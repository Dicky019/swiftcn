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
    public let isOn: Bool
    public let switchId: String?

    public init(
      label: String,
      isOn: Bool = false,
      switchId: String? = nil
    ) {
      self.label = label
      self.isOn = isOn
      self.switchId = switchId
    }

    /// Initialize from SDUI node props
    public init(from props: [String: AnyCodable]) {
      self.label = props["label"]?.asString ?? ""
      self.isOn = props["isOn"]?.asBool ?? false
      self.switchId = props["switchId"]?.asString
    }
  }
}
