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

  var body: some Scene {
    WindowGroup {
      ContentWrapper()
        .environment(themeProvider)
    }
  }
}

/// Wrapper view that tracks system color scheme and provides theme environment
private struct ContentWrapper: View {
  @Environment(ThemeProvider.self) private var themeProvider
  @Environment(\.colorScheme) private var systemColorScheme

  var body: some View {
    MainTabView()
      .withThemeTracking(themeProvider, systemColorScheme: systemColorScheme)
  }
}
