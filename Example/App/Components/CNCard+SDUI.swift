//
//  CNCard+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNCard {
  /// Configuration for SDUI rendering
  public struct Configuration: Codable, Sendable, Hashable {
    public let variant: Variant

    public init(variant: Variant = .elevated) {
      self.variant = variant
    }

    /// Initialize from SDUI node props
    public init(from props: [String: AnyCodable]) {
      if let raw = props["variant"]?.asString, let v = Variant(rawValue: raw) {
        self.variant = v
      } else {
        self.variant = .elevated
      }
    }
  }
}
