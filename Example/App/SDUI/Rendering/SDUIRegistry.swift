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
      let label = node.props["label"]?.value as? String ?? ""
      let sizeRaw = node.props["size"]?.value as? String ?? "md"
      let variantRaw = node.props["variant"]?.value as? String ?? "default"
      let actionId = node.props["actionId"]?.value as? String

      let size = CNButton.Size(rawValue: sizeRaw) ?? .md
      let variant = CNButton.Variant(rawValue: variantRaw) ?? .default

      return CNButton(label, size: size, variant: variant) {
        if let actionId {
          handler?.handleAction(id: actionId, payload: nil)
        }
      }
    }

    // CNCard - use type annotation to help inference
    register("card") { node, handler -> CNCard<SDUIRenderer> in
      let variantRaw = node.props["variant"]?.value as? String ?? "elevated"
      let variant = CNCard<SDUIRenderer>.Variant(rawValue: variantRaw) ?? .elevated
      let children = node.children ?? []

      return CNCard(variant: variant) {
        SDUIRenderer(nodes: children, actionHandler: handler)
      }
    }

    // CNBadge
    register("badge") { node, _ in
      let label = node.props["label"]?.value as? String ?? ""
      let variantRaw = node.props["variant"]?.value as? String ?? "default"
      let variant = CNBadge.Variant(rawValue: variantRaw) ?? .default

      return CNBadge(label, variant: variant)
    }

    // Layout: VStack
    register("vstack") { node, handler in
      let spacing = node.props["spacing"]?.value as? Double ?? 8

      return VStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    // Layout: HStack
    register("hstack") { node, handler in
      let spacing = node.props["spacing"]?.value as? Double ?? 8

      return HStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: handler)
        }
      }
    }

    // Text
    register("text") { node, _ in
      let content = node.props["content"]?.value as? String ?? ""
      let style = node.props["style"]?.value as? String ?? "body"

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
      let placeholder = node.props["placeholder"]?.value as? String ?? ""
      let label = node.props["label"]?.value as? String
      let isError = node.props["isError"]?.value as? Bool ?? false
      let errorMessage = node.props["errorMessage"]?.value as? String
      let inputId = node.props["inputId"]?.value as? String

      return SDUIInputWrapper(
        placeholder: placeholder,
        label: label,
        isError: isError,
        errorMessage: errorMessage,
        inputId: inputId,
        actionHandler: handler
      )
    }

    // CNSwitch
    register("switch") { node, handler in
      let label = node.props["label"]?.value as? String ?? ""
      let isOn = node.props["isOn"]?.value as? Bool ?? false
      let switchId = node.props["switchId"]?.value as? String

      return SDUISwitchWrapper(
        label: label,
        initialValue: isOn,
        switchId: switchId,
        actionHandler: handler
      )
    }

    // CNSlider
    register("slider") { node, handler in
      let label = node.props["label"]?.value as? String ?? ""
      let value = node.props["value"]?.value as? Double ?? 0.5
      let minValue = node.props["min"]?.value as? Double ?? 0.0
      let maxValue = node.props["max"]?.value as? Double ?? 1.0
      let step = node.props["step"]?.value as? Double
      let sliderId = node.props["sliderId"]?.value as? String

      return SDUISliderWrapper(
        label: label,
        initialValue: value,
        range: minValue...maxValue,
        step: step,
        sliderId: sliderId,
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
