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

  /// Custom renderers registered by the user (AnyView for extensibility)
  private var customRenderers: [String: @MainActor (SDUINode, SDUIActionHandler?) -> AnyView] = [:]

  /// Maximum text content length before truncation
  static let maxTextLength = 10_000

  private init() {}

  /// Register a custom component renderer
  public func register<V: View>(
    _ type: String,
    renderer: @MainActor @escaping (SDUINode, SDUIActionHandler?) -> V
  ) {
    customRenderers[type] = { node, handler in
      AnyView(renderer(node, handler))
    }
  }

  /// Render a node using built-in @ViewBuilder switch or custom renderer fallback
  @ViewBuilder
  public func render(_ node: SDUINode, actionHandler: SDUIActionHandler?, depth: Int = 0) -> some View {
    let childDepth = depth + 1
    switch node.type {
    case "button":
      let config = CNButton.Configuration(from: node.props)
      CNButton(configuration: config) {
        if let actionId = config.actionId {
          actionHandler?.handleAction(id: actionId, payload: nil)
        }
      }

    case "card":
      let config = CNCard<SDUIRenderer>.Configuration(from: node.props)
      let children = node.children ?? []
      CNCard(variant: config.variant) {
        SDUIRenderer(nodes: children, actionHandler: actionHandler, depth: childDepth)
      }

    case "badge":
      let config = CNBadge.Configuration(from: node.props)
      CNBadge(configuration: config)

    case "vstack":
      let spacing = node.props["spacing"]?.asDouble ?? 8
      VStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: actionHandler, depth: childDepth)
        }
      }

    case "hstack":
      let spacing = node.props["spacing"]?.asDouble ?? 8
      HStack(spacing: spacing) {
        if let children = node.children {
          SDUIRenderer(nodes: children, actionHandler: actionHandler, depth: childDepth)
        }
      }

    case "lazy-vstack":
      let spacing = node.props["spacing"]?.asDouble ?? 8
      ScrollView {
        LazyVStack(spacing: spacing) {
          if let children = node.children {
            SDUIRenderer(nodes: children, actionHandler: actionHandler, depth: childDepth)
          }
        }
      }

    case "lazy-hstack":
      let spacing = node.props["spacing"]?.asDouble ?? 8
      ScrollView(.horizontal) {
        LazyHStack(spacing: spacing) {
          if let children = node.children {
            SDUIRenderer(nodes: children, actionHandler: actionHandler, depth: childDepth)
          }
        }
      }

    case "text":
      let rawContent = node.props["content"]?.asString ?? ""
      let content = rawContent.count > Self.maxTextLength
        ? String(rawContent.prefix(Self.maxTextLength))
        : rawContent
      let style = node.props["style"]?.asString ?? "body"
      Text(content)
        .font(Self.font(for: style))

    case "spacer":
      Spacer()

    case "divider":
      Divider()

    case "input":
      let config = CNInput.Configuration(from: node.props)
      SDUIInputWrapper(
        placeholder: config.placeholder,
        label: config.label,
        isError: config.isError,
        errorMessage: config.errorMessage,
        inputId: config.inputId,
        actionHandler: actionHandler
      )

    case "switch":
      let config = CNSwitch.Configuration(from: node.props)
      SDUISwitchWrapper(
        label: config.label,
        initialValue: config.isOn,
        switchId: config.switchId,
        actionHandler: actionHandler
      )

    case "slider":
      let config = CNSlider.Configuration(from: node.props)
      SDUISliderWrapper(
        label: config.label ?? "",
        initialValue: config.value,
        range: config.minValue...config.maxValue,
        step: config.step,
        sliderId: config.sliderId,
        actionHandler: actionHandler
      )

    default:
      if let customRenderer = customRenderers[node.type] {
        customRenderer(node, actionHandler)
      } else {
        SDUIUnknownComponent(type: node.type)
      }
    }
  }

  /// Check if a component type is registered (built-in or custom)
  public func isRegistered(_ type: String) -> Bool {
    let builtIn: Set<String> = [
      "button", "card", "badge", "vstack", "hstack",
      "lazy-vstack", "lazy-hstack", "text", "spacer",
      "divider", "input", "switch", "slider"
    ]
    return builtIn.contains(type) || customRenderers[type] != nil
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
    #if DEBUG
    Text("Unknown: \(type)")
      .font(.caption)
      .foregroundStyle(.red)
      .padding(4)
      .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 4))
    #else
    EmptyView()
    #endif
  }
}
