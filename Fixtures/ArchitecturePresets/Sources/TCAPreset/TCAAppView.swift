//
//  TCAAppView.swift
//  Fixtures/ArchitecturePresets/Sources/TCAPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ComposableArchitecture
import SwiftUI

public struct TCAScoreView: View {
  private let store: StoreOf<ScoreFeature>

  public init(store: StoreOf<ScoreFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack {
      Text("Score: \(store.score.value)")
      Button("Increment") { store.send(.incrementTapped) }
    }
    .navigationTitle("TCA")
  }
}

public struct TCAAppView: View {
  @Bindable private var store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(\.path, action: \.path)) {
      VStack {
        Button("Push score") { store.send(.showScore) }
        Button("Present score") { store.send(.presentScore) }
        Button("Pop to root") { store.send(.popToRoot) }
      }
      .navigationTitle("TCA")
    } destination: { store in
      switch store.case {
      case .score(let store): TCAScoreView(store: store)
      }
    }
    .sheet(item: $store.scope(state: \.destination?.score, action: \.destination.score)) { store in
      TCAScoreView(store: store)
    }
  }
}
