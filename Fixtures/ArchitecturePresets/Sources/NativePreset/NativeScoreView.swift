//
//  NativeScoreView.swift
//  Fixtures/ArchitecturePresets/Sources/NativePreset
//
//  Created by Dicky Darmawan on 03/10/26.
//

import PresetApplication
import PresetDomain
import PresetNavigation
import SwiftUI

public enum NativeRoute: Hashable {
  case details(score: Int)
}

public struct NativeScoreView: View {
  @Environment(Router<NativeRoute>.self) private var router
  @State private var score = Score()
  private let increment = IncrementScore()

  public init() {}

  public var body: some View {
    VStack {
      Text("Score: \(score.value)")
      Button("Increment") { score = increment.execute(score) }
      Button("Details") { router.push(.details(score: score.value)) }
    }
    .navigationTitle("Native")
  }
}

public struct NativeRootView: View {
  @State private var router = Router<NativeRoute>()

  public init() {}

  public var body: some View {
    @Bindable var router = router
    NavigationStack(path: $router.path) {
      NativeScoreView()
        .navigationDestination(for: NativeRoute.self) { route in
          switch route {
          case .details(let score): Text("Score snapshot: \(score)")
          }
        }
    }
    .environment(router)
  }
}
