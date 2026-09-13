//
//  ThemeEnvironment.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - Theme Environment

extension EnvironmentValues {
  /// Access the resolved theme from the environment.
  @Entry public var theme: ResolvedTheme = .default
}

// MARK: - View Extension

@MainActor
private struct ThemeTrackingModifier: ViewModifier {
  let themeProvider: ThemeProvider

  @Environment(\.colorScheme) private var systemColorScheme

  func body(content: Content) -> some View {
    content
      .environment(\.theme, themeProvider.resolvedTheme)
      .preferredColorScheme(themeProvider.resolvedColorScheme)
      .onChange(of: systemColorScheme, initial: true) { _, newScheme in
        themeProvider.updateSystemColorScheme(newScheme)
      }
  }
}

extension View {
  /// Apply theme values and track system appearance.
  public func withThemeTracking(_ themeProvider: ThemeProvider) -> some View {
    modifier(ThemeTrackingModifier(themeProvider: themeProvider))
  }
}
