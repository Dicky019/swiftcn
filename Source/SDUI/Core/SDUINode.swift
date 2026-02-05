//
//  SDUINode.swift
//  Source/SDUI/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

/// Represents a UI node in the SDUI tree
public struct SDUINode: Codable, Sendable, Hashable, Identifiable {
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
}
