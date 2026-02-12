//
//  SDUIActionHandler.swift
//  Sources/SDUI/Actions
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

/// Protocol for handling SDUI component actions
@MainActor
public protocol SDUIActionHandler: AnyObject {
  /// Handle an action triggered by a component
  func handleAction(id: String, payload: [String: AnyCodable]?)

  /// Handle navigation action
  func handleNavigation(route: String, params: [String: AnyCodable]?)
}

/// Default no-op action handler for testing and previews
@MainActor
public final class DefaultSDUIActionHandler: SDUIActionHandler {
  /// Set of allowed action IDs. Actions not in this set are silently blocked.
  /// Populate this with the action IDs your SDUI templates use.
  public var allowedActions: Set<String> = []

  /// Set of allowed navigation routes. Routes not in this set are silently blocked.
  /// Populate this with the route paths your SDUI templates use.
  public var allowedRoutes: Set<String> = []

  public init() {}

  public func handleAction(id: String, payload: [String: AnyCodable]?) {
    guard allowedActions.contains(id) else {
      #if DEBUG
      print("[SDUI] Blocked action: \(id) (not in allowedActions)")
      #endif
      return
    }
    #if DEBUG
    print("[SDUI] Action: \(id), payload: \(String(describing: payload))")
    #endif
  }

  public func handleNavigation(route: String, params: [String: AnyCodable]?) {
    guard allowedRoutes.contains(route) else {
      #if DEBUG
      print("[SDUI] Blocked navigation: \(route) (not in allowedRoutes)")
      #endif
      return
    }
    #if DEBUG
    print("[SDUI] Navigate: \(route), params: \(String(describing: params))")
    #endif
  }
}
