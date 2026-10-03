//
//  RetryPolicyTests.swift
//  Example/Tests/OfflineFirst/
//
//  Created by Dicky Darmawan on 03/10/26.
//

@testable import Example
import Testing

@Suite("RetryPolicy")
struct RetryPolicyTests {
  let policy = RetryPolicy(maximumAttempts: 3, baseDelay: .seconds(2), maximumDelay: .seconds(10))

  @Test func oneBasedExponentialBudget() {
    #expect(policy.delay(forAttempt: 0, serverHint: nil, jitter: 1) == nil)
    #expect(policy.delay(forAttempt: 1, serverHint: nil, jitter: 1) == .seconds(2))
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: 1) == .seconds(4))
    #expect(policy.delay(forAttempt: 3, serverHint: nil, jitter: 1) == .seconds(8))
    #expect(policy.delay(forAttempt: 4, serverHint: nil, jitter: 1) == nil)
  }

  @Test func fullJitterAndServerHintAreBounded() {
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: -1) == .zero)
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: 2) == .seconds(4))
    #expect(policy.delay(forAttempt: 2, serverHint: .seconds(7), jitter: 0.5) == .seconds(7))
    #expect(policy.delay(forAttempt: 2, serverHint: .seconds(99), jitter: 0.5) == .seconds(10))
    #expect(policy.delay(forAttempt: 1, serverHint: .seconds(-1), jitter: 0.25) == .milliseconds(500))
    #expect(policy.delay(forAttempt: 1, serverHint: nil, jitter: .nan) == .zero)
  }

  @Test func capsBeforeDoublingAndAllowsNoRetries() {
    let capped = RetryPolicy(maximumAttempts: 100, baseDelay: .seconds(2), maximumDelay: .seconds(3))
    #expect(capped.delay(forAttempt: 100, serverHint: nil, jitter: 1) == .seconds(3))
    #expect(RetryPolicy(maximumAttempts: 0, baseDelay: .zero, maximumDelay: .zero)
      .delay(forAttempt: 1, serverHint: nil, jitter: 1) == nil)
  }
}
