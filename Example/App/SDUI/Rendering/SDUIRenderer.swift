//
//  SDUIRenderer.swift
//  Sources/SDUI/Rendering
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Renders an array of SDUI nodes
public struct SDUIRenderer: View {
    private let nodes: [SDUINode]
    private weak var actionHandler: SDUIActionHandler?

    public init(nodes: [SDUINode], actionHandler: SDUIActionHandler? = nil) {
        self.nodes = nodes
        self.actionHandler = actionHandler
    }

    public init(node: SDUINode, actionHandler: SDUIActionHandler? = nil) {
        self.nodes = [node]
        self.actionHandler = actionHandler
    }

    public var body: some View {
        ForEach(nodes) { node in
            SDUIRegistry.shared.render(node, actionHandler: actionHandler)
        }
    }
}

// MARK: - Convenience initializers from JSON

extension SDUIRenderer {
    /// Initialize from JSON data
    public init(jsonData: Data, actionHandler: SDUIActionHandler? = nil) throws {
        let nodes = try JSONDecoder().decode([SDUINode].self, from: jsonData)
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
        let node = try JSONDecoder().decode(SDUINode.self, from: singleNodeJSON)
        self.init(node: node, actionHandler: actionHandler)
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
