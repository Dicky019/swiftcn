//
//  App.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

@main
struct ExampleApp: App {
  @State private var themeProvider = ThemeProvider()

  @MainActor
  init() {
    let registry = SDUIRegistry.shared
    registry.registerCNButton()
    registry.registerCNCard()
    registry.registerCNBadge()
    registry.registerCNInput()
    registry.registerCNSwitch()
    registry.registerCNSlider()
  }

  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environment(themeProvider)
        .withThemeTracking(themeProvider)
    }
  }
}
