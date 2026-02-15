//
//  BaseDestination.swift
//  Example
//
//  Created by Dicky Darmawan on 13/02/26.
//

import SwiftUI

/// Abstract base class for all navigation destinations.
/// Subclass and override `getScreen()` to define the view for each route.
@MainActor
open class BaseDestination: Hashable {
  /// Route identifier, auto-derived from the class type name.
  nonisolated public var route: String {
    String(describing: type(of: self))
  }

  /// Override in subclasses to return the destination's view.
  open func getScreen() -> any View {
    EmptyView()
  }

  public init() {}

  /// Override in subclasses to provide parameter-aware equality.
  nonisolated open func isEqual(to other: BaseDestination) -> Bool {
    route == other.route
  }

  nonisolated public static func == (lhs: BaseDestination, rhs: BaseDestination) -> Bool {
    type(of: lhs) == type(of: rhs) && lhs.isEqual(to: rhs)
  }

  nonisolated public func hash(into hasher: inout Hasher) {
    hasher.combine(route)
  }
}
