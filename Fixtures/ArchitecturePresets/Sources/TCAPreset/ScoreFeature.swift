//
//  ScoreFeature.swift
//  Fixtures/ArchitecturePresets/Sources/TCAPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ComposableArchitecture
import PresetApplication
import PresetDomain

@Reducer
public struct ScoreFeature {
  @ObservableState
  public struct State: Equatable {
    public var score: Score

    public init(score: Score = Score()) {
      self.score = score
    }
  }

  public enum Action {
    case incrementTapped
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementTapped:
        state.score = IncrementScore().execute(state.score)
        return .none
      }
    }
  }
}
