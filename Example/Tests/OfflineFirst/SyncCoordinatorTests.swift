//
//  SyncCoordinatorTests.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Testing

actor SuspensionGate {
  private var waiters: [CheckedContinuation<Void, Never>] = []
  private var permits = 0
  private var opened = false

  func wait() async {
    if opened { return }
    if permits > 0 {
      permits -= 1
      return
    }
    await withCheckedContinuation { waiters.append($0) }
  }

  func releaseOne() {
    if waiters.isEmpty { permits += 1 } else { waiters.removeFirst().resume() }
  }

  func open() {
    opened = true
    let suspended = waiters
    waiters.removeAll()
    for waiter in suspended { waiter.resume() }
  }

  var waiting: Int { waiters.count }
}

actor RecordingWorker: SyncWorker {
  private(set) var calls: [(SyncScope, Set<SyncTrigger>)] = []
  private(set) var maximumActive = 0
  private var active = 0
  private var results: [SyncPassResult]
  private let gate: SuspensionGate?

  init(results: [SyncPassResult], gate: SuspensionGate? = nil) {
    self.results = results
    self.gate = gate
  }

  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult {
    active += 1
    maximumActive = max(maximumActive, active)
    defer { active -= 1 }
    calls.append((scope, triggers))
    if let gate { await gate.wait() }
    return results.isEmpty ? .noWork : results.removeFirst()
  }
}

actor RecordingSleeper {
  private(set) var delays: [Duration] = []
  let gate: SuspensionGate?
  init(gate: SuspensionGate? = nil) { self.gate = gate }
  func sleep(_ delay: Duration) async throws {
    delays.append(delay)
    if let gate { await gate.wait() }
    try Task.checkCancellation()
  }
}

// The witness is scheduled while holding the coordinator actor. request() enters
// inline on that same actor and inserts its trigger before suspension. A worker
// completion therefore cannot overtake a witnessed trigger registration.
extension SyncCoordinator {
  fileprivate func witnessedRequest(_ trigger: SyncTrigger, witness: SuspensionGate) async -> SyncOutcome {
    Task { await witness.releaseOne() }
    return await request(trigger)
  }
}

@Suite("SyncCoordinator")
struct SyncCoordinatorTests {
  let scope = SyncScope(rawValue: "account-A/store-1")
  let policy = RetryPolicy(maximumAttempts: 3, baseDelay: .seconds(2), maximumDelay: .seconds(10))

  @Test func coalescesConcurrentTriggersWithoutOverlappingWorkerPasses() async {
    let gate = SuspensionGate()
    let worker = RecordingWorker(results: [.completed, .completed], gate: gate)
    let coordinator = SyncCoordinator(scope: scope, worker: worker, retryPolicy: policy)
    let first = Task { await coordinator.request(.launch) }
    while await worker.calls.isEmpty { await Task.yield() }
    let witness = SuspensionGate()
    let requests = (0..<20).map { _ in
      Task { await coordinator.witnessedRequest(.localMutation, witness: witness) }
    }
    for _ in 0..<20 { await witness.wait() }
    await gate.releaseOne()
    while await worker.calls.count < 2 { await Task.yield() }
    await gate.releaseOne()
    #expect(await first.value == .completed)
    for request in requests { _ = await request.value }
    let calls = await worker.calls
    #expect(calls.count == 2)
    #expect(calls[0].1 == [.launch])
    #expect(calls[1].1 == [.localMutation])
    #expect(calls.allSatisfy { $0.0 == scope })
    #expect(await worker.maximumActive == 1)
  }

  @Test func retriesRetainOriginalTriggersAndUseInjectedDelays() async {
    let worker = RecordingWorker(results: [
      .retry(reason: .transport, serverHint: nil),
      .retry(reason: .serverBusy, serverHint: .seconds(7)), .completed
    ])
    let sleeper = RecordingSleeper()
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: policy,
      sleep: { try await sleeper.sleep($0) },
      jitter: { 0.5 }
    )
    #expect(await coordinator.request(.manual) == .completed)
    #expect(await sleeper.delays == [.seconds(1), .seconds(7)])
    #expect(await worker.calls.map { $0.1 } == [[.manual], [.manual], [.manual]])
  }

  @Test func newTriggerDuringRetrySleepJoinsNextPassOnce() async {
    let sleepGate = SuspensionGate()
    let witness = SuspensionGate()
    let worker = RecordingWorker(results: [.retry(reason: .transport, serverHint: nil), .completed])
    let sleeper = RecordingSleeper(gate: sleepGate)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: policy,
      sleep: { try await sleeper.sleep($0) },
      jitter: { 1 }
    )
    let first = Task { await coordinator.request(.launch) }
    while await sleepGate.waiting == 0 { await Task.yield() }
    let second = Task { await coordinator.witnessedRequest(.localMutation, witness: witness) }
    await witness.wait()
    await sleepGate.releaseOne()
    #expect(await first.value == .completed)
    #expect(await second.value == .completed)
    #expect(await worker.calls.map { $0.1 } == [[.launch], [.launch, .localMutation]])
  }

  @Test func finiteRetryBudgetDefersAndNextRequestGetsFreshBudget() async {
    let worker = RecordingWorker(results: Array(repeating: .retry(reason: .timeout, serverHint: nil), count: 4) + [.completed])
    let sleeper = RecordingSleeper()
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: policy,
      sleep: { try await sleeper.sleep($0) },
      jitter: { 1 }
    )
    #expect(await coordinator.request(.launch) == .deferred(.timeout))
    #expect(await worker.calls.count == 4)
    #expect(await sleeper.delays == [.seconds(2), .seconds(4), .seconds(8)])
    #expect(await coordinator.request(.manual) == .completed)
    #expect(await worker.calls.count == 5)
  }

  @Test func cancelDuringWorkerWaitsForPassThenReturnsCancelled() async {
    let gate = SuspensionGate()
    let worker = RecordingWorker(results: [.completed, .noWork], gate: gate)
    let coordinator = SyncCoordinator(scope: scope, worker: worker, retryPolicy: policy)
    let request = Task { await coordinator.request(.launch) }
    while await gate.waiting == 0 { await Task.yield() }
    await coordinator.cancel()
    await gate.releaseOne()
    #expect(await request.value == .cancelled)
    let next = Task { await coordinator.request(.manual) }
    while await gate.waiting == 0 { await Task.yield() }
    await gate.releaseOne()
    #expect(await next.value == .noWork)
    #expect(await worker.maximumActive == 1)
  }

  @Test func freshRequestAfterCancelWaitsRetiringPassThenRuns() async {
    let gate = SuspensionGate()
    let witness = SuspensionGate()
    let worker = RecordingWorker(results: [.completed, .completed], gate: gate)
    let coordinator = SyncCoordinator(scope: scope, worker: worker, retryPolicy: policy)
    let old = Task { await coordinator.request(.launch) }
    while await gate.waiting == 0 { await Task.yield() }
    await coordinator.cancel()
    let fresh = Task { await coordinator.witnessedRequest(.foreground, witness: witness) }
    await witness.wait()
    // The replacement cannot execute while the retiring worker is suspended.
    #expect(await worker.calls.count == 1)
    await gate.open()
    #expect(await old.value == .cancelled)
    #expect(await fresh.value == .completed)
    #expect(await worker.calls.map { $0.1 } == [[.launch], [.foreground]])
    #expect(await worker.maximumActive == 1)
  }

  @Test func cancelledRetirementWaiterDoesNotSwallowOtherFreshTriggers() async {
    let gate = SuspensionGate()
    let witness = SuspensionGate()
    let worker = RecordingWorker(results: [.completed, .completed, .completed], gate: gate)
    let coordinator = SyncCoordinator(scope: scope, worker: worker, retryPolicy: policy)
    let old = Task { await coordinator.request(.launch) }
    while await gate.waiting == 0 { await Task.yield() }
    await coordinator.cancel()
    let cancelled = Task { await coordinator.witnessedRequest(.manual, witness: witness) }
    let foreground = Task { await coordinator.witnessedRequest(.foreground, witness: witness) }
    let mutation = Task { await coordinator.witnessedRequest(.localMutation, witness: witness) }
    for _ in 0..<3 { await witness.wait() }
    cancelled.cancel()
    #expect(await worker.calls.count == 1)
    await gate.open()
    #expect(await old.value == .cancelled)
    #expect(await cancelled.value == .cancelled)
    #expect(await foreground.value == .completed)
    #expect(await mutation.value == .completed)
    let calls = await worker.calls
    let freshTriggers = calls.dropFirst().flatMap { $0.1 }
    #expect(freshTriggers.filter { $0 == .foreground }.count == 1)
    #expect(freshTriggers.filter { $0 == .localMutation }.count == 1)
    #expect(!freshTriggers.contains(.manual))
    #expect(calls.count <= 3)
    #expect(await worker.maximumActive == 1)
  }

  @Test func cancelDuringSleepDoesNotRerunWorker() async {
    let gate = SuspensionGate()
    let worker = RecordingWorker(results: [.retry(reason: .transport, serverHint: nil), .completed])
    let sleeper = RecordingSleeper(gate: gate)
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: policy,
      sleep: { try await sleeper.sleep($0) },
      jitter: { 1 }
    )
    let request = Task { await coordinator.request(.foreground) }
    while await gate.waiting == 0 { await Task.yield() }
    await coordinator.cancel()
    await gate.releaseOne()
    #expect(await request.value == .cancelled)
    #expect(await worker.calls.count == 1)
  }

  @Test(arguments: [SyncPassResult.blocked(.authentication), .blocked(.storage), .blocked(.migration), .expired])
  func terminalResultsNeverRetry(_ result: SyncPassResult) async {
    let worker = RecordingWorker(results: [result])
    let sleeper = RecordingSleeper()
    let coordinator = SyncCoordinator(
      scope: scope,
      worker: worker,
      retryPolicy: policy,
      sleep: { try await sleeper.sleep($0) },
      jitter: { 1 }
    )
    let outcome = await coordinator.request(.connectivityHint)
    switch result {
    case let .blocked(reason): #expect(outcome == .blocked(reason))
    case .expired: #expect(outcome == .expired)
    default: Issue.record("Unexpected test case")
    }
    #expect(await worker.calls.count == 1)
    #expect(await sleeper.delays.isEmpty)
  }
}
