//
//  Destination.swift
//  Example
//
//  Created by Dicky Darmawan on 13/02/26.
//

import SwiftUI

/// Namespace for all navigation destinations.
/// Each inner class is a self-contained route that knows how to render its screen.
enum Destination {
  /// Sentinel destination representing the root. Never navigate to this directly.
  final class Root: BaseDestination {}

  /// Component detail/showcase screen.
  final class ComponentDetail: BaseDestination {
    let info: ComponentInfo

    init(info: ComponentInfo) {
      self.info = info
      super.init()
    }

    override func getScreen() -> any View {
      ComponentDetailView(component: info)
    }

    nonisolated override func hash(into hasher: inout Hasher) {
      hasher.combine(route)
      hasher.combine(info.id)
    }

    nonisolated override func isEqual(to other: BaseDestination) -> Bool {
      guard let other = other as? ComponentDetail else { return false }
      return info.id == other.info.id
    }
  }


  // MARK: - Theme Destinations

  /// Token showcase screen.
  final class TokenShowcase: BaseDestination {
    override func getScreen() -> any View {
      TokenShowcaseView()
    }
  }

  /// Theme actions screen.
  final class ThemeActions: BaseDestination {
    override func getScreen() -> any View {
      ThemeActionsView()
    }
  }

  /// Token category detail screen.
  final class TokenCategoryDetail: BaseDestination {
    let category: TokenCategory

    init(category: TokenCategory) {
      self.category = category
      super.init()
    }

    override func getScreen() -> any View {
      category.destinationView
    }

    nonisolated override func hash(into hasher: inout Hasher) {
      hasher.combine(route)
      hasher.combine(category.id)
    }

    nonisolated override func isEqual(to other: BaseDestination) -> Bool {
      guard let other = other as? TokenCategoryDetail else { return false }
      return category.id == other.category.id
    }
  }
}
