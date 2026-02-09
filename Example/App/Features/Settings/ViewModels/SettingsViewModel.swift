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
  
  func selectMode(_ mode: ColorSchemePreference) {
    themeProvider.colorSchemePreference = mode
  }
  
  func isSelected(_ mode: ColorSchemePreference) -> Bool {
    currentMode == mode
  }
  
  // MARK: - App Info
  
  var appVersion: String { "1.0.0" }
  var buildNumber: String { "1" }
}
