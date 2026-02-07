//
//  CNSwitch+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNSwitch {
    /// Configuration for SDUI rendering
    public struct Configuration: Codable, Sendable, Hashable {
        public let label: String
        public let switchId: String?

        public init(
            label: String,
            switchId: String? = nil
        ) {
            self.label = label
            self.switchId = switchId
        }
    }
}
