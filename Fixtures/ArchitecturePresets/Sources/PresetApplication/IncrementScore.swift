//
//  IncrementScore.swift
//  Fixtures/ArchitecturePresets/Sources/PresetApplication
//
//  Created by Dicky Darmawan on 03/10/26.
//

import PresetDomain

public struct IncrementScore: Sendable {
  public init() {}

  public func execute(_ score: Score) -> Score {
    var score = score
    score.increment()
    return score
  }
}
