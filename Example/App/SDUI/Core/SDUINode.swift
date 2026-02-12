//
//  SDUINode.swift
//  Sources/SDUI/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

/// Represents a UI node in the SDUI tree
public struct SDUINode: Codable, Sendable, Hashable, Identifiable {
  /// Maximum allowed nesting depth for SDUI trees. Edit this constant to adjust the limit.
  public static let maxDepth = 20

  /// Maximum allowed total node count in an SDUI tree. Edit this constant to adjust the limit.
  public static let maxNodeCount = 200

  public let id: String
  public let type: String
  public let props: [String: AnyCodable]
  public let children: [SDUINode]?

  public init(
    id: String,
    type: String,
    props: [String: AnyCodable] = [:],
    children: [SDUINode]? = nil
  ) {
    self.id = id
    self.type = type
    self.props = props
    self.children = children
  }

  /// Counts total nodes in the tree iteratively (stack-based to avoid stack overflow).
  public func totalNodeCount() -> Int {
    var count = 0
    var stack: [SDUINode] = [self]
    while let node = stack.popLast() {
      count += 1
      if let children = node.children {
        stack.append(contentsOf: children)
      }
    }
    return count
  }

  /// Calculates the maximum depth of the tree iteratively (stack-based to avoid stack overflow).
  public func maxTreeDepth() -> Int {
    var maxDepth = 0
    var stack: [(node: SDUINode, depth: Int)] = [(self, 1)]
    while let (node, depth) = stack.popLast() {
      maxDepth = max(maxDepth, depth)
      if let children = node.children {
        for child in children {
          stack.append((child, depth + 1))
        }
      }
    }
    return maxDepth
  }
}
