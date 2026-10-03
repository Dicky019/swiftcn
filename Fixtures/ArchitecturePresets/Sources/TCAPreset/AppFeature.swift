//
//  AppFeature.swift
//  Fixtures/ArchitecturePresets/Sources/TCAPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ComposableArchitecture

@Reducer
public struct AppFeature {
  @Reducer
  public enum Path {
    case score(ScoreFeature)
  }

  @Reducer
  public enum Destination {
    case score(ScoreFeature)
  }

  @ObservableState
  public struct State: Equatable {
    public var path = StackState<Path.State>()
    @Presents public var destination: Destination.State?

    public init() {}
  }

  public enum Action {
    case showScore
    case popToRoot
    case presentScore
    case path(StackActionOf<Path>)
    case destination(PresentationAction<Destination.Action>)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showScore:
        state.path.append(.score(ScoreFeature.State()))
      case .popToRoot:
        state.path.removeAll()
      case .presentScore:
        state.destination = .score(ScoreFeature.State())
      case .path, .destination:
        break
      }
      return .none
    }
    .forEach(\.path, action: \.path)
    .ifLet(\.$destination, action: \.destination)
  }
}

extension AppFeature.Path.State: Equatable {}
extension AppFeature.Destination.State: Equatable {}
