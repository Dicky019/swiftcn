//
//  SDUIActionHandler.swift
//  Sources/SDUI/Actions
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation
import OSLog

private let sduiLogger = Logger(subsystem: "com.swiftcn", category: "SDUI")

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
    sduiLogger.debug("[SDUI] Action: \(id, privacy: .public), payload: \(String(describing: payload ?? [:]), privacy: .public)")
  }

  public func handleNavigation(route: String, params: [String: AnyCodable]?) {
    sduiLogger.debug("[SDUI] Navigate: \(route, privacy: .public), params: \(String(describing: params ?? [:]), privacy: .public)")
  }
}
