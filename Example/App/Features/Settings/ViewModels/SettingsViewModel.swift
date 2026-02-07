//
//  SettingsViewModel.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
  private let themeProvider: ThemeProvider

  // MARK: - Reduce Motion

  /// App-specific reduce motion preference (overrides system if set)
  @ObservationIgnored
  @AppStorage("reduceMotion") private var _reduceMotion: Bool = false

  var reduceMotion: Bool {
    get { _reduceMotion }
    set { _reduceMotion = newValue }
  }

  /// Check if motion should be reduced (app setting OR system setting)
  func shouldReduceMotion(systemReduceMotion: Bool) -> Bool {
    reduceMotion || systemReduceMotion
  }

  init(themeProvider: ThemeProvider) {
    self.themeProvider = themeProvider
  }

  // MARK: - Theme

  var currentMode: ColorSchemePreference {
    themeProvider.colorSchemePreference
  }

  var allModes: [ColorSchemePreference] {
    ColorSchemePreference.allCases
  }

  func selectMode(_ mode: ColorSchemePreference, reduceMotion: Bool) {
    guard !reduceMotion else {
      themeProvider.colorSchemePreference = mode
      return
    }
    withAnimation(.easeInOut) {
      themeProvider.colorSchemePreference = mode
    }
  }

  func isSelected(_ mode: ColorSchemePreference) -> Bool {
    currentMode == mode
  }

  // MARK: - App Info

  var appVersion: String { "1.0.0" }
  var buildNumber: String { "1" }
}
