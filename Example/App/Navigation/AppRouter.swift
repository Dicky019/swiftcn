//
//  AppRouter.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

/// Global router managing navigation for all features
@MainActor
@Observable
final class AppRouter {
  var componentsPath = NavigationPath()

  // MARK: - Components Navigation

  func navigate(to route: ComponentRoute) {
    componentsPath.append(route)
  }

  func popComponents() {
    guard !componentsPath.isEmpty else { return }
    componentsPath.removeLast()
  }

  func popComponentsToRoot() {
    componentsPath.removeLast(componentsPath.count)
  }
}
