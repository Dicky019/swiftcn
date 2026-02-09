//
//  ThemeEnvironment.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
  static let defaultValue: ResolvedTheme = .default
}

extension EnvironmentValues {
  /// Access the resolved theme from the environment
  public var theme: ResolvedTheme {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

// MARK: - View Extension

extension View {
  /// Apply theme environment and track system color scheme changes
  /// Use this on your root content view to enable theme support
  public func withThemeTracking(_ themeProvider: ThemeProvider, systemColorScheme: ColorScheme) -> some View {
    self
      .environment(\.theme, themeProvider.resolvedTheme)
      .preferredColorScheme(themeProvider.resolvedColorScheme)
      .onChange(of: systemColorScheme, initial: true) { _, newScheme in
        themeProvider.updateSystemColorScheme(newScheme)
      }
  }
}
