//
//  SDUIRenderer.swift
//  Sources/SDUI/Rendering
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Renders an array of SDUI nodes
public struct SDUIRenderer: View {
  /// Maximum allowed JSON payload size in bytes. Edit this constant to adjust the limit.
  public static let maxPayloadSize = 512 * 1024

  private static let decoder = JSONDecoder()

  private let nodes: [SDUINode]
  private var actionHandler: SDUIActionHandler?
  let depth: Int

  public init(nodes: [SDUINode], actionHandler: SDUIActionHandler? = nil, depth: Int = 0) {
    self.nodes = nodes
    self.actionHandler = actionHandler
    self.depth = depth
  }

  public init(node: SDUINode, actionHandler: SDUIActionHandler? = nil, depth: Int = 0) {
    self.nodes = [node]
    self.actionHandler = actionHandler
    self.depth = depth
  }

  public var body: some View {
    ForEach(nodes) { node in
      if depth < SDUINode.maxDepth {
        SDUIRegistry.shared.render(node, actionHandler: actionHandler, depth: depth)
      }
    }
  }
}

// MARK: - Convenience initializers from JSON

extension SDUIRenderer {
  /// Initialize from JSON data with payload size, depth, and node count validation
  public init(jsonData: Data, actionHandler: SDUIActionHandler? = nil) throws {
    guard jsonData.count <= Self.maxPayloadSize else {
      throw SDUIError.payloadTooLarge(jsonData.count)
    }
    let nodes = try Self.decoder.decode([SDUINode].self, from: jsonData)
    try Self.validateTree(nodes)
    self.init(nodes: nodes, actionHandler: actionHandler)
  }

  /// Initialize from JSON string
  public init(jsonString: String, actionHandler: SDUIActionHandler? = nil) throws {
    guard let data = jsonString.data(using: .utf8) else {
      throw SDUIError.invalidJSON
    }
    try self.init(jsonData: data, actionHandler: actionHandler)
  }

  /// Initialize from a single node JSON
  public init(singleNodeJSON: Data, actionHandler: SDUIActionHandler? = nil) throws {
    guard singleNodeJSON.count <= Self.maxPayloadSize else {
      throw SDUIError.payloadTooLarge(singleNodeJSON.count)
    }
    let node = try Self.decoder.decode(SDUINode.self, from: singleNodeJSON)
    try Self.validateTree([node])
    self.init(node: node, actionHandler: actionHandler)
  }

  private static func validateTree(_ nodes: [SDUINode]) throws {
    var totalCount = 0
    var maxDepth = 0
    for node in nodes {
      totalCount += node.totalNodeCount()
      maxDepth = max(maxDepth, node.maxTreeDepth())
    }
    if maxDepth > SDUINode.maxDepth {
      throw SDUIError.maxDepthExceeded(SDUINode.maxDepth)
    }
    if totalCount > SDUINode.maxNodeCount {
      throw SDUIError.maxNodeCountExceeded(SDUINode.maxNodeCount)
    }
  }
}

// MARK: - Preview

#Preview("SDUI Renderer") {
  let nodes: [SDUINode] = [
    SDUINode(
      id: "1",
      type: "vstack",
      props: ["spacing": AnyCodable(16)],
      children: [
        SDUINode(
          id: "2",
          type: "text",
          props: [
            "content": AnyCodable("Hello SDUI!"),
            "style": AnyCodable("title")
          ]
        ),
        SDUINode(
          id: "3",
          type: "button",
          props: [
            "label": AnyCodable("Click Me"),
            "variant": AnyCodable("default"),
            "actionId": AnyCodable("btn_click")
          ]
        ),
        SDUINode(
          id: "4",
          type: "hstack",
          props: ["spacing": AnyCodable(8)],
          children: [
            SDUINode(id: "5", type: "badge", props: ["label": AnyCodable("New")]),
            SDUINode(id: "6", type: "badge", props: ["label": AnyCodable("SDUI"), "variant": AnyCodable("secondary")])
          ]
        )
      ]
    )
  ]

  return SDUIRenderer(nodes: nodes, actionHandler: DefaultSDUIActionHandler())
    .padding()
}
