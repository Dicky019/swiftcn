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
  public init() {}

  public func handleAction(id: String, payload: [String: AnyCodable]?) {
    print("[SDUI] Action: \(id), payload: \(String(describing: payload))")
  }

  public func handleNavigation(route: String, params: [String: AnyCodable]?) {
    print("[SDUI] Navigate: \(route), params: \(String(describing: params))")
  }
}
