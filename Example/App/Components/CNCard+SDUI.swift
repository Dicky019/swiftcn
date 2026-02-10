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
  }
}
