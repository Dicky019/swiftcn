//
//  RetryPolicy.swift
//  Sources/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

public struct RetryPolicy: Equatable, Sendable {
  public let maximumAttempts: Int
  public let baseDelay: Duration
  public let maximumDelay: Duration

  /// maximumAttempts counts retries after the initial worker pass.
  public init(maximumAttempts: Int, baseDelay: Duration, maximumDelay: Duration) {
    precondition(maximumAttempts >= 0)
    precondition(baseDelay >= .zero)
    precondition(maximumDelay >= baseDelay)
    self.maximumAttempts = maximumAttempts
    self.baseDelay = baseDelay
    self.maximumDelay = maximumDelay
  }

  public func delay(forAttempt attempt: Int, serverHint: Duration?, jitter: Double) -> Duration? {
    guard attempt > 0, attempt <= maximumAttempts else { return nil }
    var exponential = baseDelay
    if exponential > .zero {
      for _ in 1..<attempt {
        // Avoid Duration overflow before applying the cap.
        if exponential >= maximumDelay - exponential {
          exponential = maximumDelay
          break
        }
        exponential += exponential
      }
    }
    let factor = jitter.isNaN ? 0 : min(max(jitter, 0), 1)
    let jittered = scale(exponential, by: factor)
    return min(max(jittered, serverHint ?? .zero), maximumDelay)
  }

  private func scale(_ duration: Duration, by factor: Double) -> Duration {
    if factor == 0 { return .zero }
    if factor == 1 { return duration }
    let components = duration.components
    let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
    return .seconds(seconds * factor)
  }
}
