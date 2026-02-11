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
    public let value: Double
    public let minValue: Double
    public let maxValue: Double
    public let step: Double?
    public let showValue: Bool
    public let sliderId: String?

    public init(
      label: String? = nil,
      value: Double = 0.5,
      minValue: Double = 0,
      maxValue: Double = 100,
      step: Double? = nil,
      showValue: Bool = false,
      sliderId: String? = nil
    ) {
      self.label = label
      self.value = value
      self.minValue = minValue
      self.maxValue = maxValue
      self.step = step
      self.showValue = showValue
      self.sliderId = sliderId
    }

    /// Initialize from SDUI node props
    public init(from props: [String: AnyCodable]) {
      self.label = props["label"]?.asString
      self.value = props["value"]?.asDouble ?? 0.5
      self.minValue = props["min"]?.asDouble ?? 0.0
      self.maxValue = props["max"]?.asDouble ?? 1.0
      self.step = props["step"]?.asDouble
      self.showValue = props["showValue"]?.asBool ?? false
      self.sliderId = props["sliderId"]?.asString
    }
  }
}
