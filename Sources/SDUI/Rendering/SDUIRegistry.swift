//
//  SDUIRegistry.swift
//  Sources/SDUI/Rendering
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Registry for mapping component types to their renderers
@MainActor
public final class SDUIRegistry {
  public static let shared = SDUIRegistry()

  private var renderers: [String: @MainActor (SDUINode, SDUIActionHandler?) throws -> AnyView] = [:]

  private init() {
    registerCoreComponents()
  }

  /// Register a component renderer
  public func register<V: View>(
    _ type: String,
    renderer: @MainActor @escaping (SDUINode, SDUIActionHandler?) throws -> V
  ) {
    renderers[type] = { node, handler in
      AnyView(try renderer(node, handler).id(node.id))
    }
  }

  /// Render a node using registered renderer
  public func render(_ node: SDUINode, actionHandler: SDUIActionHandler?) -> AnyView {
    guard let renderer = renderers[node.type] else {
      return AnyView(SDUIUnknownComponent(type: node.type).id(node.id))
    }

    do {
      return try renderer(node, actionHandler)
    } catch {
      return AnyView(
        SDUIInvalidComponent(type: node.type, message: error.localizedDescription).id(node.id)
      )
    }
  }

  /// Check if a component type is registered
  public func isRegistered(_ type: String) -> Bool {
    renderers[type] != nil
  }

  private func registerCoreComponents() {
    register("vstack") { node, handler in
      VStack(spacing: try Self.optionalDouble(node, key: "spacing") ?? 8) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    register("hstack") { node, handler in
      HStack(spacing: try Self.optionalDouble(node, key: "spacing") ?? 8) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    register("text") { node, _ in
      Text(try Self.requiredString(node, key: "content"))
        .font(try Self.font(forWireValue: Self.optionalString(node, key: "style") ?? "body"))
    }

    register("spacer") { _, _ in Spacer() }
    register("divider") { _, _ in Divider() }
  }

  private static func requiredString(_ node: SDUINode, key: String) throws -> String {
    guard let value = node.props[key]?.stringValue else {
      throw SDUIError.invalidProps(component: node.type, reason: "\(key) is required")
    }
    return value
  }

  private static func optionalString(_ node: SDUINode, key: String) throws -> String? {
    guard let prop = node.props[key] else { return nil }
    guard let value = prop.stringValue else {
      throw SDUIError.invalidProps(component: node.type, reason: "\(key) must be a string")
    }
    return value
  }

  private static func optionalDouble(_ node: SDUINode, key: String) throws -> Double? {
    guard let prop = node.props[key] else { return nil }
    guard let value = prop.doubleValue else {
      throw SDUIError.invalidProps(component: node.type, reason: "\(key) must be a number")
    }
    return value
  }

  private static func font(forWireValue style: String) throws -> Font {
    switch style {
    case "largeTitle": return .largeTitle
    case "title": return .title
    case "title2": return .title2
    case "title3": return .title3
    case "headline": return .headline
    case "subheadline": return .subheadline
    case "callout": return .callout
    case "footnote": return .footnote
    case "caption": return .caption
    case "caption2": return .caption2
    case "body": return .body
    default:
      throw SDUIError.invalidProps(component: "text", reason: "style is invalid")
    }
  }
}

/// Placeholder for unknown component types
struct SDUIUnknownComponent: View {
  let type: String

  var body: some View {
    Text("Unknown: \(type)")
      .font(.caption)
      .foregroundStyle(.red)
      .padding(4)
      .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 4))
  }
}

struct SDUIInvalidComponent: View {
  let type: String
  let message: String

  var body: some View {
    Text("Invalid \(type): \(message)")
      .font(.caption)
      .foregroundStyle(.red)
      .padding(4)
      .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 4))
  }
}
