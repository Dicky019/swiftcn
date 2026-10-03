//
//  SyncContractTests.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Foundation
import Testing

@Suite("Offline sync failure contracts")
struct SyncContractTests {
  let scope = SyncScope(rawValue: "account-A")

  @Test func droppedResponseReusesOperationIDAndMakesOneServerSideEffect() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "local", operationID: operation, scope: scope)
    let server = IdempotentServer(push: [.acceptAndDropResponse])
    let worker = ReferenceSyncWorker(store: store, server: server)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: RetryPolicy(maximumAttempts: 1, baseDelay: .zero, maximumDelay: .zero),
      sleep: { _ in },
      jitter: { 0 }
    )
    #expect(await coordinator.request(.localMutation) == .completed)
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "local")
    #expect(snapshot.entities[id]?.revision == 1)
    #expect(snapshot.pending.isEmpty)
    #expect(await server.operationIDs == [operation, operation])
    #expect(await server.sideEffects == 1)
  }

  @Test func retryBudgetExhaustionKeepsDurableIntentForNextTrigger() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "local", operationID: operation, scope: scope)
    let server = IdempotentServer(push: [.acceptAndDropResponse])
    let worker = ReferenceSyncWorker(store: store, server: server)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: RetryPolicy(maximumAttempts: 0, baseDelay: .zero, maximumDelay: .zero)
    )
    #expect(await coordinator.request(.localMutation) == .deferred(.transport))
    let waiting = await store.snapshot(scope: scope)
    #expect(waiting.entities[id]?.title == "local")
    #expect(waiting.entities[id]?.revision == 0)
    #expect(waiting.pending.map(\.operationID) == [operation])
    #expect(await coordinator.request(.foreground) == .completed)
    #expect(await store.snapshot(scope: scope).pending.isEmpty)
    #expect(await server.operationIDs == [operation, operation])
    #expect(await server.sideEffects == 1)
  }

  @Test func lateAcknowledgmentRetainsSecondLocalProjectionAndOperation() async {
    let id = UUID(), first = UUID(), second = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "first", operationID: first, scope: scope)
    let gate = SuspensionGate()
    let server = IdempotentServer(pushGate: gate)
    let worker = ReferenceSyncWorker(store: store, server: server)
    let pass = Task { await worker.run(scope: scope, triggers: [.localMutation]) }
    while await gate.waiting == 0 { await Task.yield() }
    await store.edit(id: id, title: "second", operationID: second, scope: scope)
    await gate.releaseOne()
    #expect(await pass.value == .completed)
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "second")
    #expect(snapshot.entities[id]?.revision == 1)
    #expect(snapshot.pending.map(\.operationID) == [second])
  }

  @Test func partialBatchOnlyRemovesAcceptedOperations() async {
    let firstID = UUID(), secondID = UUID(), first = UUID(), second = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: firstID, title: "accepted", operationID: first, scope: scope)
    await store.edit(id: secondID, title: "waiting", operationID: second, scope: scope)
    let server = IdempotentServer(push: [.accept, .retry(.serverBusy)])
    let result = await ReferenceSyncWorker(store: store, server: server).run(scope: scope, triggers: [.manual])
    #expect(result == .retry(reason: .serverBusy, serverHint: nil))
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[firstID]?.revision == 1)
    #expect(snapshot.entities[secondID]?.title == "waiting")
    #expect(snapshot.pending.map(\.operationID) == [second])
  }

  @Test func duplicateRemotePageIsIdempotentAndCursorCommitsOnce() async {
    let id = UUID()
    let page = RemotePage(changes: [RemoteChange(entityID: id, title: "remote", revision: 3, tombstone: false)], nextCursor: "page-3")
    let store = ReferenceLocalStore(scope: scope)
    let server = IdempotentServer(pull: [.page(page), .page(page)])
    let worker = ReferenceSyncWorker(store: store, server: server)
    #expect(await worker.run(scope: scope, triggers: [.manual]) == .completed)
    #expect(await worker.run(scope: scope, triggers: [.manual]) == .completed)
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities.count == 1)
    #expect(snapshot.entities[id]?.title == "remote")
    #expect(snapshot.pending.isEmpty)
    #expect(snapshot.cursor == "page-3")
    #expect(snapshot.pageCommits == 1)
  }

  @Test func pageApplyFailurePreservesPreviousCursorAndPendingIntent() async {
    let localID = UUID(), remoteID = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: localID, title: "pending", operationID: operation, scope: scope)
    await store.seedCursor("old", scope: scope)
    await store.setPageFailure(true)
    let change = RemoteChange(entityID: remoteID, title: "uncommitted", revision: 1, tombstone: false)
    let page = RemotePage(changes: [change], nextCursor: "new")
    // Pending intent is ineligible on this pass, so failure exercises pull atomicity.
    await store.setEligible(false)
    let server = IdempotentServer(pull: [.page(page)])
    #expect(await ReferenceSyncWorker(store: store, server: server).run(scope: scope, triggers: [.manual]) == .blocked(.storage))
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.cursor == "old")
    #expect(snapshot.entities[remoteID] == nil)
    #expect(snapshot.entities[localID]?.title == "pending")
    #expect(snapshot.pending.map(\.operationID) == [operation])
  }

  @Test func expiredCursorRequestsFullReconciliationWithoutClearingOutbox() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "local", operationID: operation, scope: scope)
    await store.setEligible(false)
    await store.seedCursor("expired", scope: scope)
    let server = IdempotentServer(pull: [.cursorExpired])
    let worker = ReferenceSyncWorker(store: store, server: server)
    #expect(await worker.run(scope: scope, triggers: [.foreground]) == .retry(reason: .serverBusy, serverHint: nil))
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.needsFullReconciliation)
    #expect(snapshot.cursor == "expired")
    #expect(snapshot.entities[id]?.title == "local")
    #expect(snapshot.pending.map(\.operationID) == [operation])
  }

  @Test func conflictPreservesLocalIntentAndStopsDependentCommands() async {
    let id = UUID(), first = UUID(), second = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "first", operationID: first, scope: scope)
    await store.edit(id: id, title: "second", operationID: second, scope: scope)
    let server = IdempotentServer(push: [.conflict(9)])
    #expect(await ReferenceSyncWorker(store: store, server: server).run(scope: scope, triggers: [.localMutation]) == .blocked(.conflict))
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "second")
    #expect(snapshot.pending.map(\.operationID) == [first, second])
    #expect(snapshot.blocked == .conflict)
    #expect(await server.operationIDs == [first])
  }

  @Test func tombstoneSurvivesVisibleReadsAndOlderPullReplay() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.delete(id: id, operationID: operation, scope: scope)
    await store.setEligible(false)
    let deleted = RemotePage(changes: [RemoteChange(entityID: id, title: "", revision: 2, tombstone: true)], nextCursor: "2")
    let old = RemotePage(changes: [RemoteChange(entityID: id, title: "old", revision: 1, tombstone: false)], nextCursor: "2")
    let server = IdempotentServer(pull: [.page(deleted), .page(old)])
    let worker = ReferenceSyncWorker(store: store, server: server)
    _ = await worker.run(scope: scope, triggers: [.manual])
    _ = await worker.run(scope: scope, triggers: [.manual])
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.tombstone == true)
    #expect(snapshot.visible.isEmpty)
    #expect(snapshot.pending.map(\.operationID) == [operation])
  }

  @Test(arguments: [SyncBlockReason.authentication, .permanentRejection, .migration, .storage])
  func blockedFailuresPreserveProjectionAndOutbox(_ reason: SyncBlockReason) async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "saved locally", operationID: operation, scope: scope)
    let localFailure = reason == .migration || reason == .storage
    if localFailure { await store.setReadinessFailure(reason) }
    let behavior: PushBehavior = reason == .permanentRejection ? .reject : .blocked(reason)
    let server = IdempotentServer(push: [localFailure ? .accept : behavior])
    #expect(await ReferenceSyncWorker(store: store, server: server).run(scope: scope, triggers: [.launch]) == .blocked(reason))
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "saved locally")
    #expect(snapshot.pending.map(\.operationID) == [operation])
    #expect(snapshot.blocked == reason)
    if localFailure { #expect(await server.operationIDs.isEmpty) }
  }

  @Test func backgroundExpirationRemainsDistinctAndResumable() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "saved locally", operationID: operation, scope: scope)
    let server = IdempotentServer(push: [.expired])
    let worker = ReferenceSyncWorker(store: store, server: server)
    #expect(await worker.run(scope: scope, triggers: [.foreground]) == .expired)
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "saved locally")
    #expect(snapshot.pending.map(\.operationID) == [operation])
    #expect(await worker.run(scope: scope, triggers: [.launch]) == .completed)
    #expect(await store.snapshot(scope: scope).pending.isEmpty)
  }

  @Test func accountSwitchAndCancellationFenceLateAcknowledgment() async {
    let id = UUID(), operation = UUID(), otherOperation = UUID()
    let other = SyncScope(rawValue: "account-B")
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "A", operationID: operation, scope: scope)
    let gate = SuspensionGate()
    let server = IdempotentServer(pushGate: gate)
    let worker = ReferenceSyncWorker(store: store, server: server)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: RetryPolicy(maximumAttempts: 0, baseDelay: .zero, maximumDelay: .zero)
    )
    let pass = Task { await coordinator.request(.manual) }
    while await gate.waiting == 0 { await Task.yield() }
    await coordinator.cancel()
    await store.activate(other)
    await store.edit(id: id, title: "B", operationID: otherOperation, scope: other)
    await gate.releaseOne()
    #expect(await pass.value == .cancelled)
    let first = await store.snapshot(scope: scope), second = await store.snapshot(scope: other)
    #expect(first.entities[id]?.title == "A")
    #expect(first.entities[id]?.revision == 0)
    #expect(first.pending.map(\.operationID) == [operation])
    #expect(second.entities[id]?.title == "B")
    #expect(second.entities[id]?.revision == 0)
    #expect(second.pending.map(\.operationID) == [otherOperation])
  }

  @Test func scopeSwitchAloneFencesLateResultEvenWithoutTaskCancellation() async {
    let id = UUID(), operation = UUID(), otherOperation = UUID()
    let other = SyncScope(rawValue: "account-B")
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "A", operationID: operation, scope: scope)
    let gate = SuspensionGate()
    let server = IdempotentServer(pushGate: gate)
    let worker = ReferenceSyncWorker(store: store, server: server)
    let pass = Task { await worker.run(scope: scope, triggers: [.manual]) }
    while await gate.waiting == 0 { await Task.yield() }
    await store.activate(other)
    await store.edit(id: id, title: "B", operationID: otherOperation, scope: other)
    await gate.releaseOne()
    #expect(await pass.value == .expired)
    let oldSnapshot = await store.snapshot(scope: scope)
    let newSnapshot = await store.snapshot(scope: other)
    #expect(oldSnapshot.entities[id]?.revision == 0)
    #expect(oldSnapshot.pending.map(\.operationID) == [operation])
    #expect(newSnapshot.entities[id]?.title == "B")
    #expect(newSnapshot.entities[id]?.revision == 0)
    #expect(newSnapshot.pending.map(\.operationID) == [otherOperation])
  }

  @Test func concurrentTriggersUseOneFeaturePassAtATime() async {
    let id = UUID(), operation = UUID()
    let store = ReferenceLocalStore(scope: scope)
    await store.edit(id: id, title: "local", operationID: operation, scope: scope)
    let gate = SuspensionGate()
    let server = IdempotentServer(pushGate: gate)
    let worker = ReferenceSyncWorker(store: store, server: server)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: RetryPolicy(maximumAttempts: 0, baseDelay: .zero, maximumDelay: .zero)
    )
    let first = Task { await coordinator.request(.launch) }
    while await gate.waiting == 0 { await Task.yield() }
    let requests = (0..<20).map { _ in Task { await coordinator.request(.manual) } }
    await gate.releaseOne()
    _ = await first.value
    for request in requests { _ = await request.value }
    #expect(await worker.maximumActive == 1)
    let snapshot = await store.snapshot(scope: scope)
    #expect(snapshot.entities[id]?.title == "local")
    #expect(snapshot.pending.isEmpty)
    #expect(await server.sideEffects == 1)
  }
}
