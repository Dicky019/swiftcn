//
//  SyncContractHarness.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Foundation

// Feature-specific, repository-only contracts: no production payload protocol.
enum Command: Equatable, Sendable {
  case setTitle(String)
  case delete
}

struct PendingMutation: Equatable, Sendable {
  let operationID: UUID
  let scope: SyncScope
  let entityID: UUID
  let baseRevision: Int?
  let command: Command
  let sequence: Int
}

enum PushResult: Equatable, Sendable {
  case accepted(operationID: UUID, revision: Int)
  case retryable(RetryReason)
  case rejected
  case conflict(remoteRevision: Int)
  case blocked(SyncBlockReason)
  case expired
}

struct RemoteChange: Equatable, Sendable {
  let entityID: UUID
  let title: String
  let revision: Int
  let tombstone: Bool
}

struct RemotePage: Equatable, Sendable {
  let changes: [RemoteChange]
  let nextCursor: String
}

enum PullResult: Sendable {
  case page(RemotePage)
  case cursorExpired
  case blocked(SyncBlockReason)
  case expired
}

enum PushBehavior: Sendable {
  case accept
  case acceptAndDropResponse
  case retry(RetryReason)
  case reject
  case conflict(Int)
  case blocked(SyncBlockReason)
  case expired
}

struct ReferenceEntity: Equatable, Sendable {
  var title: String
  var revision: Int
  var tombstone: Bool
}

struct ReferenceSnapshot: Sendable {
  var entities: [UUID: ReferenceEntity] = [:]
  var pending: [PendingMutation] = []
  var cursor: String?
  var blocked: SyncBlockReason?
  var needsFullReconciliation = false
  var pageCommits = 0
  var visible: [UUID: ReferenceEntity] { entities.filter { !$0.value.tombstone } }
}

enum ContractStoreError: Error { case storage, wrongScope }

actor ReferenceLocalStore {
  private var activeScope: SyncScope
  private var snapshots: [SyncScope: ReferenceSnapshot] = [:]
  private var pageFailure = false
  private var eligible = true
  private var readinessFailure: SyncBlockReason?

  init(scope: SyncScope) { activeScope = scope }
  func activate(_ scope: SyncScope) { activeScope = scope }
  func isActive(_ scope: SyncScope) -> Bool { scope == activeScope }
  func setPageFailure(_ failure: Bool) { pageFailure = failure }
  func setEligible(_ value: Bool) { eligible = value }
  func setReadinessFailure(_ reason: SyncBlockReason) { readinessFailure = reason }
  func readiness() -> SyncBlockReason? { readinessFailure }
  func seedCursor(_ cursor: String, scope: SyncScope) {
    snapshots[scope, default: ReferenceSnapshot()].cursor = cursor
  }

  func edit(id: UUID, title: String, operationID: UUID, scope: SyncScope) {
    commitLocal(id: id, operationID: operationID, command: .setTitle(title), scope: scope)
  }

  func delete(id: UUID, operationID: UUID, scope: SyncScope) {
    commitLocal(id: id, operationID: operationID, command: .delete, scope: scope)
  }

  private func commitLocal(id: UUID, operationID: UUID, command: Command, scope: SyncScope) {
    precondition(scope == activeScope)
    var snapshot = snapshots[scope, default: ReferenceSnapshot()]
    guard !snapshot.pending.contains(where: { $0.operationID == operationID }) else { return }
    let old = snapshot.entities[id]
    let entity: ReferenceEntity
    switch command {
    case let .setTitle(title): entity = ReferenceEntity(title: title, revision: old?.revision ?? 0, tombstone: false)
    case .delete: entity = ReferenceEntity(title: old?.title ?? "", revision: old?.revision ?? 0, tombstone: true)
    }
    let sequence = (snapshot.pending.last?.sequence ?? 0) + 1
    snapshot.entities[id] = entity
    snapshot.pending.append(PendingMutation(
      operationID: operationID,
      scope: scope,
      entityID: id,
      baseRevision: old?.revision,
      command: command,
      sequence: sequence
    ))
    snapshots[scope] = snapshot
  }

  func snapshot(scope: SyncScope) -> ReferenceSnapshot { snapshots[scope, default: ReferenceSnapshot()] }
  func pending(scope: SyncScope) -> [PendingMutation] { eligible ? snapshot(scope: scope).pending : [] }

  func acknowledge(operationID: UUID, revision: Int, scope: SyncScope) throws {
    guard activeScope == scope, !Task.isCancelled else { throw ContractStoreError.wrongScope }
    var snapshot = snapshot(scope: scope)
    guard let mutation = snapshot.pending.first(where: { $0.operationID == operationID }) else { return }
    let previousRevision = snapshot.entities[mutation.entityID]?.revision ?? 0
    snapshot.entities[mutation.entityID]?.revision = max(previousRevision, revision)
    snapshot.pending.removeAll { $0.operationID == operationID }
    snapshots[scope] = snapshot
  }

  func apply(page: RemotePage, scope: SyncScope) throws {
    guard activeScope == scope, !Task.isCancelled else { throw ContractStoreError.wrongScope }
    guard !pageFailure else { throw ContractStoreError.storage }
    var snapshot = snapshot(scope: scope)
    guard page.nextCursor != snapshot.cursor || snapshot.needsFullReconciliation else { return }
    let pendingEntities = Set(snapshot.pending.map(\.entityID))
    for change in page.changes {
      guard !pendingEntities.contains(change.entityID) else { continue }
      if let current = snapshot.entities[change.entityID], current.revision >= change.revision { continue }
      snapshot.entities[change.entityID] = ReferenceEntity(title: change.title, revision: change.revision, tombstone: change.tombstone)
    }
    snapshot.cursor = page.nextCursor
    snapshot.needsFullReconciliation = false
    snapshot.pageCommits += 1
    snapshots[scope] = snapshot
  }

  func markBlocked(_ reason: SyncBlockReason, scope: SyncScope) {
    guard activeScope == scope, !Task.isCancelled else { return }
    snapshots[scope, default: ReferenceSnapshot()].blocked = reason
  }

  func requireFullReconciliation(scope: SyncScope) {
    guard activeScope == scope, !Task.isCancelled else { return }
    snapshots[scope, default: ReferenceSnapshot()].needsFullReconciliation = true
  }
}

actor IdempotentServer {
  private struct OperationKey: Hashable { let scope: SyncScope; let id: UUID }
  private var accepted: [OperationKey: PushResult] = [:]
  private var entities: [SyncScope: [UUID: ReferenceEntity]] = [:]
  private var pushBehaviors: [PushBehavior]
  private var pullResults: [PullResult]
  private let pushGate: SuspensionGate?
  private(set) var operationIDs: [UUID] = []
  private(set) var sideEffects = 0

  init(push: [PushBehavior] = [], pull: [PullResult] = [], pushGate: SuspensionGate? = nil) {
    self.pushBehaviors = push
    self.pullResults = pull
    self.pushGate = pushGate
  }

  func push(_ mutation: PendingMutation) async -> PushResult {
    operationIDs.append(mutation.operationID)
    // Gate intentionally ignores cancellation, modeling an already-committed
    // request whose response arrives after the app has switched account.
    if let pushGate { await pushGate.wait() }
    let key = OperationKey(scope: mutation.scope, id: mutation.operationID)
    if let original = accepted[key] { return original }
    let behavior = pushBehaviors.isEmpty ? .accept : pushBehaviors.removeFirst()
    switch behavior {
    case let .retry(reason): return .retryable(reason)
    case .reject: return .rejected
    case let .conflict(revision): return .conflict(remoteRevision: revision)
    case let .blocked(reason): return .blocked(reason)
    case .expired: return .expired
    case .accept, .acceptAndDropResponse:
      let current = entities[mutation.scope]?[mutation.entityID]
      let revision = (current?.revision ?? 0) + 1
      let entity: ReferenceEntity
      switch mutation.command {
      case let .setTitle(title): entity = ReferenceEntity(title: title, revision: revision, tombstone: false)
      case .delete: entity = ReferenceEntity(title: current?.title ?? "", revision: revision, tombstone: true)
      }
      entities[mutation.scope, default: [:]][mutation.entityID] = entity
      let acknowledgment = PushResult.accepted(operationID: mutation.operationID, revision: revision)
      accepted[key] = acknowledgment
      sideEffects += 1
      if case .acceptAndDropResponse = behavior { return .retryable(.transport) }
      return acknowledgment
    }
  }

  func pull(scope: SyncScope, cursor: String?) -> PullResult {
    if !pullResults.isEmpty { return pullResults.removeFirst() }
    let changes = entities[scope, default: [:]].map {
      RemoteChange(entityID: $0.key, title: $0.value.title, revision: $0.value.revision, tombstone: $0.value.tombstone)
    }
    return .page(RemotePage(changes: changes, nextCursor: "server-\(sideEffects)"))
  }
}

actor ReferenceSyncWorker: SyncWorker {
  let store: ReferenceLocalStore
  let server: IdempotentServer
  private var active = 0
  private(set) var maximumActive = 0

  init(store: ReferenceLocalStore, server: IdempotentServer) {
    self.store = store
    self.server = server
  }

  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult {
    active += 1
    maximumActive = max(maximumActive, active)
    defer { active -= 1 }
    guard await canApply(scope) else { return .expired }
    let readiness = await store.readiness()
    guard await canApply(scope) else { return .expired }
    if let readiness { return await blocked(readiness, scope: scope) }
    let pending = await store.pending(scope: scope)
    guard await canApply(scope) else { return .expired }
    for mutation in pending {
      let result = await server.push(mutation)
      guard await canApply(scope) else { return .expired }
      switch result {
      case let .accepted(operationID, revision):
        do { try await store.acknowledge(operationID: operationID, revision: revision, scope: scope) } catch {
          return await storeFailure(error, scope: scope)
        }
        guard await canApply(scope) else { return .expired }
      case let .retryable(reason): return .retry(reason: reason, serverHint: nil)
      case .rejected: return await blocked(.permanentRejection, scope: scope)
      case .conflict: return await blocked(.conflict, scope: scope)
      case let .blocked(reason): return await blocked(reason, scope: scope)
      case .expired: return .expired
      }
    }
    let snapshot = await store.snapshot(scope: scope)
    guard await canApply(scope) else { return .expired }
    let result = await server.pull(scope: scope, cursor: snapshot.needsFullReconciliation ? nil : snapshot.cursor)
    guard await canApply(scope) else { return .expired }
    switch result {
    case let .page(page):
      do { try await store.apply(page: page, scope: scope) } catch { return await storeFailure(error, scope: scope) }
      guard await canApply(scope) else { return .expired }
      return .completed
    case .cursorExpired:
      await store.requireFullReconciliation(scope: scope)
      guard await canApply(scope) else { return .expired }
      return .retry(reason: .serverBusy, serverHint: nil)
    case let .blocked(reason): return await blocked(reason, scope: scope)
    case .expired: return .expired
    }
  }

  private func canApply(_ scope: SyncScope) async -> Bool {
    guard !Task.isCancelled else { return false }
    let active = await store.isActive(scope)
    return active && !Task.isCancelled
  }

  private func blocked(_ reason: SyncBlockReason, scope: SyncScope) async -> SyncPassResult {
    await store.markBlocked(reason, scope: scope)
    guard await canApply(scope) else { return .expired }
    return .blocked(reason)
  }

  private func storeFailure(_ error: any Error, scope: SyncScope) async -> SyncPassResult {
    if case ContractStoreError.wrongScope = error { return .expired }
    return await blocked(.storage, scope: scope)
  }
}
