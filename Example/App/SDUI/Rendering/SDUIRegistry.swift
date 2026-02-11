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

  private var renderers: [String: @MainActor (SDUINode, SDUIActionHandler?) -> AnyView] = [:]

  private init() {
    registerDefaultComponents()
  }

  /// Register a component renderer
  public func register<V: View>(
    _ type: String,
    renderer: @MainActor @escaping (SDUINode, SDUIActionHandler?) -> V
  ) {
    renderers[type] = { node, handler in
      AnyView(renderer(node, handler))
    }
  }

  /// Render a node using registered renderer
  public func render(_ node: SDUINode, actionHandler: SDUIActionHandler?) -> AnyView {
    if let renderer = renderers[node.type] {
      return renderer(node, actionHandler)
    }
    return AnyView(SDUIUnknownComponent(type: node.type))
  }

  /// Check if a component type is registered
  public func isRegistered(_ type: String) -> Bool {
    renderers[type] != nil
  }

  /// Register default CN components
  private func registerDefaultComponents() {
    // CNButton
    register("button") { node, handler in
      let config = CNButton.Configuration(from: node.props)

      return CNButton(configuration: config) {
        if let actionId = config.actionId {
          handler?.handleAction(id: actionId, payload: nil)
        }
      }
    }

    // CNCard - use type annotation to help inference
    register("card") { node, handler -> CNCard<SDUIRenderer> in
      let config = CNCard<SDUIRenderer>.Configuration(from: node.props)
      let children = node.children ?? []

      return CNCard(variant: config.variant) {
        SDUIRenderer(nodes: children, actionHandler: handler)
      }
    }

    // CNBadge
    register("badge") { node, _ in
      let config = CNBadge.Configuration(from: node.props)
      return CNBadge(configuration: config)
    }

    // Layout: VStack
    register("vstack") { node, handler in
      let spacing = node.props["spacing"]?.asDouble ?? 8

      return VStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    // Layout: HStack
    register("hstack") { node, handler in
      let spacing = node.props["spacing"]?.asDouble ?? 8

      return HStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    // Text
    register("text") { node, _ in
      let content = node.props["content"]?.asString ?? ""
      let style = node.props["style"]?.asString ?? "body"

      return Text(content)
        .font(Self.font(for: style))
    }

    // Spacer
    register("spacer") { _, _ in
      Spacer()
    }

    // Divider
    register("divider") { _, _ in
      Divider()
    }

    // CNInput
    register("input") { node, handler in
      let config = CNInput.Configuration(from: node.props)

      return SDUIInputWrapper(
        placeholder: config.placeholder,
        label: config.label,
        isError: config.isError,
        errorMessage: config.errorMessage,
        inputId: config.inputId,
        actionHandler: handler
      )
    }

    // CNSwitch
    register("switch") { node, handler in
      let config = CNSwitch.Configuration(from: node.props)

      return SDUISwitchWrapper(
        label: config.label,
        initialValue: config.isOn,
        switchId: config.switchId,
        actionHandler: handler
      )
    }

    // CNSlider
    register("slider") { node, handler in
      let config = CNSlider.Configuration(from: node.props)

      return SDUISliderWrapper(
        label: config.label ?? "",
        initialValue: config.value,
        range: config.minValue...config.maxValue,
        step: config.step,
        sliderId: config.sliderId,
        actionHandler: handler
      )
    }
  }

  private static func font(for style: String) -> Font {
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
    default: return .body
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
