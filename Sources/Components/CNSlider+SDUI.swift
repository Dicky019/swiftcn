//
//  CNSlider+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNSlider {
    /// Configuration for SDUI rendering
    public struct Configuration: Codable, Sendable, Hashable {
        public let label: String?
        public let minValue: Double
        public let maxValue: Double
        public let step: Double?
        public let showValue: Bool
        public let sliderId: String?

        public init(
            label: String? = nil,
            minValue: Double = 0,
            maxValue: Double = 100,
            step: Double? = nil,
            showValue: Bool = false,
            sliderId: String? = nil
        ) {
            self.label = label
            self.minValue = minValue
            self.maxValue = maxValue
            self.step = step
            self.showValue = showValue
            self.sliderId = sliderId
        }
    }
}
