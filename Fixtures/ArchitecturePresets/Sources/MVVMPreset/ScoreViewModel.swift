//
//  ScoreViewModel.swift
//  Fixtures/ArchitecturePresets/Sources/MVVMPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import Observation
import PresetApplication
import PresetDomain

public enum ScoreNavigationOutcome: Equatable, Sendable {
  case showDetails(score: Int)
}

@MainActor @Observable
public final class ScoreViewModel {
  public private(set) var score: Score
  public private(set) var outcome: ScoreNavigationOutcome?
  private let increment: IncrementScore

  public init(score: Score = Score(), increment: IncrementScore = IncrementScore()) {
    self.score = score
    self.increment = increment
  }

  public func incrementTapped() {
    score = increment.execute(score)
  }

  public func detailsTapped() {
    outcome = .showDetails(score: score.value)
  }

  public func takeNavigationOutcome() -> ScoreNavigationOutcome? {
    defer { outcome = nil }
    return outcome
  }
}
