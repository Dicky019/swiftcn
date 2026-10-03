//
//  ScoreFlow.swift
//  Fixtures/ArchitecturePresets/Sources/MVVMPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import Observation
import PresetNavigation

public enum ScoreRoute: Hashable {
  case details(score: Int)
}

@MainActor @Observable
public final class ScoreFlow {
  public let router = Router<ScoreRoute>()

  public init() {}

  public func handle(_ outcome: ScoreNavigationOutcome?) {
    guard let outcome else { return }
    switch outcome {
    case .showDetails(let score):
      guard score >= 0 else { return }
      router.push(.details(score: score))
    }
  }
}
