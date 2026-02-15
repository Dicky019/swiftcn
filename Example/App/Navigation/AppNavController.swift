//
//  AppNavController.swift
//  Example
//
//  Created by Dicky Darmawan on 13/02/26.
//

import SwiftUI

/// Tab identifiers for programmatic tab switching.
enum AppTab: Int, Hashable, CaseIterable {
  case components
  case sdui
  case theme
  case settings
}

/// Global navigation controller that manages tab selection and per-tab navigation stacks.
/// Inject via SwiftUI Environment at the app root.
@MainActor
@Observable
final class AppNavController {
  var selectedTab: AppTab = .components

  let components = NavController()
  let sdui = NavController()
  let theme = NavController()
  let settings = NavController()

  /// Get the NavController for a specific tab.
  func navController(for tab: AppTab) -> NavController {
    switch tab {
    case .components: components
    case .sdui: sdui
    case .theme: theme
    case .settings: settings
    }
  }

  /// Switch to a tab and optionally push a destination onto that tab's stack.
  func switchTo(_ tab: AppTab, destination: BaseDestination? = nil) {
    selectedTab = tab
    if let destination {
      navController(for: tab).navigateTo(destination)
    }
  }

  /// Switch to a tab after clearing its navigation stack to root.
  func switchTo(_ tab: AppTab, clearStack: Bool) {
    if clearStack {
      navController(for: tab).popUpToRoot()
    }
    selectedTab = tab
  }
}
