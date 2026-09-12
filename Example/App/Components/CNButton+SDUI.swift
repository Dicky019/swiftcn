//
//  CNButton+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNButton {
  /// Configuration for SDUI rendering
  public struct Configuration: Codable, Sendable, Hashable {
    public let label: String
    public let size: Size
    public let variant: Variant
    public let actionId: String?

    public init(
      label: String,
      size: Size = .md,
      variant: Variant = .default,
      actionId: String? = nil
    ) {
      self.label = label
      self.size = size
      self.variant = variant
      self.actionId = actionId
    }
  }
}

extension CNButton.Configuration {
  init(node: SDUINode) throws {
    guard let label = node.props["label"]?.stringValue else {
      throw SDUIError.invalidProps(component: "button", reason: "label is required")
    }
    let size = try node.props["size"].map { prop in
      guard let raw = prop.stringValue, let value = CNButton.Size(rawValue: raw) else {
        throw SDUIError.invalidProps(component: "button", reason: "size is invalid")
      }
      return value
    } ?? .md
    let variant = try node.props["variant"].map { prop in
      guard let raw = prop.stringValue, let value = CNButton.Variant(rawValue: raw) else {
        throw SDUIError.invalidProps(component: "button", reason: "variant is invalid")
      }
      return value
    } ?? .default
    guard node.props["actionId"] == nil || node.props["actionId"]?.stringValue != nil else {
      throw SDUIError.invalidProps(component: "button", reason: "actionId must be a string")
    }
    self.init(
      label: label,
      size: size,
      variant: variant,
      actionId: node.props["actionId"]?.stringValue
    )
  }
}

// MARK: - SDUI Initializer

extension CNButton {
  /// Create from SDUI configuration
  public init(configuration: Configuration, action: @escaping () -> Void) {
    self.init(
      configuration.label,
      size: configuration.size,
      variant: configuration.variant,
      action: action
    )
  }
}

extension SDUIRegistry {
  public func registerCNButton() {
    register("button") { node, handler in
      let configuration = try CNButton.Configuration(node: node)
      return CNButton(configuration: configuration) {
        if let actionId = configuration.actionId {
          handler?.handleAction(id: actionId, payload: nil)
        }
      }
    }
  }
}
