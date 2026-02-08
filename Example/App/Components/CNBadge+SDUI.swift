//
//  CNBadge+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNBadge {
  /// Configuration for SDUI rendering
  public struct Configuration: Codable, Sendable, Hashable {
    public let label: String
    public let variant: Variant

    public init(
      label: String,
      variant: Variant = .default
    ) {
      self.label = label
      self.variant = variant
    }
  }
}

// MARK: - SDUI Initializer

extension CNBadge {
  /// Create from SDUI configuration
  public init(configuration: Configuration) {
    self.init(configuration.label, variant: configuration.variant)
  }
}
