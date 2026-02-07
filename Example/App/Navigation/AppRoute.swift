//
//  AppRoute.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Foundation

/// Unified navigation routes for the entire app
/// Combines feature-specific routes into a single type for cross-feature navigation
enum AppRoute: Hashable {
  /// Component feature routes
  case component(ComponentRoute)
}

// MARK: - Convenience Initializers

extension AppRoute {
  /// Create component detail route
  static func componentDetail(_ info: ComponentInfo) -> AppRoute {
    .component(.detail(info))
  }
}
