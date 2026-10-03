//
//  MVVMScoreView.swift
//  Fixtures/ArchitecturePresets/Sources/MVVMPreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import SwiftUI

public struct MVVMScoreView: View {
  private let model: ScoreViewModel

  public init(model: ScoreViewModel) {
    self.model = model
  }

  public var body: some View {
    VStack {
      Text("Score: \(model.score.value)")
      Button("Increment") { model.incrementTapped() }
      Button("Details") { model.detailsTapped() }
    }
    .navigationTitle("MVVM")
  }
}

public struct MVVMRootView: View {
  @State private var model = ScoreViewModel()
  @State private var flow = ScoreFlow()

  public init() {}

  public var body: some View {
    @Bindable var router = flow.router
    NavigationStack(path: $router.path) {
      MVVMScoreView(model: model)
        .navigationDestination(for: ScoreRoute.self) { route in
          switch route {
          case .details(let score): Text("Score snapshot: \(score)")
          }
        }
    }
    .onChange(of: model.outcome) { _, outcome in
      guard outcome != nil else { return }
      flow.handle(model.takeNavigationOutcome())
    }
  }
}
