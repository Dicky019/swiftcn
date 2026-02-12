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

    /// Initialize from SDUI node props
    public init(from props: [String: AnyCodable]) {
      self.label = props["label"]?.asString ?? ""
      self.size = props["size"]?.asString.flatMap(Size.init(rawValue:)) ?? .md
      self.variant = props["variant"]?.asString.flatMap(Variant.init(rawValue:)) ?? .default
      self.actionId = props["actionId"]?.asString
    }
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
