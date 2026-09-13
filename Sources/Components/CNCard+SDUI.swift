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
    public let size: Size
    public let title: String?
    public let description: String?

    public init(
      variant: Variant = .elevated,
      size: Size = .default,
      title: String? = nil,
      description: String? = nil
    ) {
      self.variant = variant
      self.size = size
      self.title = title
      self.description = description
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.variant = try container.decodeIfPresent(Variant.self, forKey: .variant) ?? .elevated
      self.size = try container.decodeIfPresent(Size.self, forKey: .size) ?? .default
      self.title = try container.decodeIfPresent(String.self, forKey: .title)
      self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }

    init(node: SDUINode) throws {
      let variant = try node.props["variant"].map { prop in
        guard let raw = prop.stringValue, let value = Variant(rawValue: raw) else {
          throw SDUIError.invalidProps(component: "card", reason: "variant is invalid")
        }
        return value
      } ?? .elevated

      let size = try node.props["size"].map { prop in
        guard let raw = prop.stringValue, let value = Size(rawValue: raw) else {
          throw SDUIError.invalidProps(component: "card", reason: "size is invalid")
        }
        return value
      } ?? .default

      let title = try node.props["title"].map { prop in
        guard let raw = prop.stringValue else {
          throw SDUIError.invalidProps(component: "card", reason: "title must be a string")
        }
        return raw
      }

      let description = try node.props["description"].map { prop in
        guard let raw = prop.stringValue else {
          throw SDUIError.invalidProps(component: "card", reason: "description must be a string")
        }
        return raw
      }

      self.init(
        variant: variant,
        size: size,
        title: title,
        description: description
      )
    }
  }
}

extension CNCard {
  public init(configuration: Configuration, @ViewBuilder content: () -> Content) {
    self.init(
      title: configuration.title,
      description: configuration.description,
      variant: configuration.variant,
      size: configuration.size,
      hasFooterDivider: false,
      content: content
    )
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
