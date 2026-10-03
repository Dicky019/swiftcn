//
//  SyncCoordinator.swift
//  Sources/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

public typealias SyncSleeper = @Sendable (Duration) async throws -> Void
public typealias SyncJitter = @Sendable () -> Double

/// A single flight for one account/store. Durable mutations belong to the worker.
public actor SyncCoordinator<Worker: SyncWorker> {
  private let scope: SyncScope
  private let worker: Worker
  private let retryPolicy: RetryPolicy
  private let sleep: SyncSleeper
  private let jitter: SyncJitter
  private var pendingTriggers: Set<SyncTrigger> = []
  private var activeTask: Task<SyncOutcome, Never>?

  public init(scope: SyncScope, worker: Worker, retryPolicy: RetryPolicy) {
    self.init(
      scope: scope,
      worker: worker,
      retryPolicy: retryPolicy,
      sleep: { try await Task.sleep(for: $0) },
      jitter: { Double.random(in: 0...1) }
    )
  }

  public init(
    scope: SyncScope,
    worker: Worker,
    retryPolicy: RetryPolicy,
    sleep: @escaping SyncSleeper,
    jitter: @escaping SyncJitter
  ) {
    self.scope = scope
    self.worker = worker
    self.retryPolicy = retryPolicy
    self.sleep = sleep
    self.jitter = jitter
  }

  /// Concurrent callers share the outcome of the same drain. Cancel via cancel().
  public func request(_ trigger: SyncTrigger) async -> SyncOutcome {
    // A cancelled worker may still be retiring inside a non-cooperative await.
    // Wait for its cleanup before enqueueing into a replacement flight. Other
    // fresh callers can start that flight first; recheck after every suspension.
    while let retiringTask = activeTask, retiringTask.isCancelled {
      _ = await retiringTask.value
      guard !Task.isCancelled else { return .cancelled }
    }
    guard !Task.isCancelled else { return .cancelled }
    pendingTriggers.insert(trigger)
    if let activeTask { return await activeTask.value }
    let task = Task { await drainAndFinish() }
    activeTask = task
    return await task.value
  }

  public func cancel() {
    activeTask?.cancel()
    pendingTriggers.removeAll()
  }

  private func drainAndFinish() async -> SyncOutcome {
    defer { activeTask = nil }
    var retryAttempt = 0
    var triggers: Set<SyncTrigger> = []
    while true {
      guard !Task.isCancelled else { return .cancelled }
      // Preserve failed-pass triggers for retries. New triggers are consumed
      // once by this next pass, whether it is a retry or a successful follow-up.
      triggers.formUnion(pendingTriggers)
      pendingTriggers.removeAll()
      let result = await worker.run(scope: scope, triggers: triggers)
      guard !Task.isCancelled else { return .cancelled }
      let outcome: SyncOutcome
      switch result {
      case .noWork:
        outcome = .noWork
      case .completed:
        outcome = .completed
      case let .blocked(reason):
        return .blocked(reason)
      case .expired:
        return .expired
      case let .retry(reason, serverHint):
        retryAttempt += 1
        guard let delay = retryPolicy.delay(forAttempt: retryAttempt, serverHint: serverHint, jitter: jitter()) else {
          return .deferred(reason)
        }
        do { try await sleep(delay) } catch { return .cancelled }
        continue
      }
      guard !pendingTriggers.isEmpty else { return outcome }
      retryAttempt = 0
      triggers.removeAll()
    }
  }
}
