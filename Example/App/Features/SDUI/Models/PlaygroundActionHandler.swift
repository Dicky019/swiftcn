//
//  PlaygroundActionHandler.swift
//  Example
//
//  Created by Dicky Darmawan on 12/02/26.
//

import Foundation

struct ActionLogEntry: Identifiable {
  let id = UUID()
  let timestamp: Date
  let kind: Kind
  let actionId: String
  let payloadDescription: String?

  enum Kind {
    case action
    case navigation
    case blocked
  }
}

@MainActor
@Observable
final class PlaygroundActionHandler: SDUIActionHandler {
  private(set) var logEntries: [ActionLogEntry] = []
  private(set) var counter: Int = 0

  var navController: NavController?
  var appNavController: AppNavController?

  private let inner = DefaultSDUIActionHandler()

  private static let maxEntries = 50

  init() {
    inner.allowedActions = [
      "get_started", "login", "forgot_password", "submit_feedback",
      "add_to_cart", "update", "dismiss",
      "email", "password", "name", "message",
      "dark_mode", "notifications", "auto_update",
      "volume", "rating",
      "count_increment", "count_decrement", "count_reset"
    ]
    inner.allowedRoutes = [
      "settings", "components"
    ]
  }

  func handleAction(id: String, payload: [String: AnyCodable]?) {
    let isAllowed = inner.allowedActions.contains(id)
    let description = payload.map { dict in
      dict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }

    appendEntry(ActionLogEntry(
      timestamp: Date(),
      kind: isAllowed ? .action : .blocked,
      actionId: id,
      payloadDescription: description
    ))

    switch id {
    case "count_increment": counter += 1
    case "count_decrement": counter -= 1
    case "count_reset": counter = 0
    default: break
    }

    inner.handleAction(id: id, payload: payload)
  }

  func handleNavigation(route: String, params: [String: AnyCodable]?) {
    let isAllowed = inner.allowedRoutes.contains(route) || route.hasPrefix("components_")
    let description = params.map { dict in
      dict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }

    appendEntry(ActionLogEntry(
      timestamp: Date(),
      kind: isAllowed ? .navigation : .blocked,
      actionId: route,
      payloadDescription: description
    ))

    inner.handleNavigation(route: route, params: params)

    guard isAllowed else { return }

    switch route {
    case "settings":
      appNavController?.switchTo(.settings)
    case "components":
      appNavController?.switchTo(.components)
    default:
      if route.hasPrefix("components_") {
        let componentId = String(route.dropFirst("components_".count))
        if let info = ComponentInfo.all.first(where: { $0.id == componentId }) {
          appNavController?.switchTo(.components, destination: Destination.ComponentDetail(info: info))
        }
      }
    }
  }

  func clearLog() {
    logEntries.removeAll()
  }

  private func appendEntry(_ entry: ActionLogEntry) {
    logEntries.append(entry)
    if logEntries.count > Self.maxEntries {
      logEntries.removeFirst(logEntries.count - Self.maxEntries)
    }
  }
}
