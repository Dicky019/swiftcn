//
//  SDUIActionHandler.swift
//  Sources/SDUI/Actions
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

/// Protocol for handling SDUI component actions
public protocol SDUIActionHandler: AnyObject {
    /// Handle an action triggered by a component
    func handleAction(id: String, payload: [String: Any]?)

    /// Handle navigation action
    func handleNavigation(route: String, params: [String: Any]?)
}

/// Default no-op action handler for testing and previews
public final class DefaultSDUIActionHandler: SDUIActionHandler {
    public init() {}

    public func handleAction(id: String, payload: [String: Any]?) {
        print("[SDUI] Action: \(id), payload: \(payload ?? [:])")
    }

    public func handleNavigation(route: String, params: [String: Any]?) {
        print("[SDUI] Navigate: \(route), params: \(params ?? [:])")
    }
}
