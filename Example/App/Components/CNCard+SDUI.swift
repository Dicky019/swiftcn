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

    init(node: SDUINode) throws {
      let variant = try node.props["variant"].map { prop in
        guard let raw = prop.stringValue, let value = Variant(rawValue: raw) else {
          throw SDUIError.invalidProps(component: "card", reason: "variant is invalid")
        }
        return value
      } ?? .elevated
      self.init(variant: variant)
    }
  }
}

extension CNCard {
  public init(configuration: Configuration, @ViewBuilder content: () -> Content) {
    self.init(variant: configuration.variant, content: content)
  }
}

extension SDUIRegistry {
  public func registerCNCard() {
    register("card") { node, handler -> CNCard<SDUIRenderer> in
      let configuration = try CNCard<SDUIRenderer>.Configuration(node: node)
      return CNCard(configuration: configuration) {
        SDUIRenderer(nodes: node.children ?? [], actionHandler: handler)
      }
    }
  }
}
