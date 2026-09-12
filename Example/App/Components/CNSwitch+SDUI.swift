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

    private enum CodingKeys: String, CodingKey {
      case label
      case isOn
      case switchId
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.label = try container.decode(String.self, forKey: .label)
      self.isOn = try container.decodeIfPresent(Bool.self, forKey: .isOn) ?? false
      self.switchId = try container.decodeIfPresent(String.self, forKey: .switchId)
    }
  }
}

extension CNSwitch.Configuration {
  init(node: SDUINode) throws {
    guard let label = node.props["label"]?.stringValue else {
      throw SDUIError.invalidProps(component: "switch", reason: "label is required")
    }
    let isOn = try node.props["isOn"].map { prop in
      guard let value = prop.boolValue else {
        throw SDUIError.invalidProps(component: "switch", reason: "isOn must be a boolean")
      }
      return value
    } ?? false
    let switchId = try node.props["switchId"].map { prop in
      guard let value = prop.stringValue else {
        throw SDUIError.invalidProps(component: "switch", reason: "switchId must be a string")
      }
      return value
    }
    self.init(label: label, isOn: isOn, switchId: switchId)
  }
}

private struct SDUISwitchWrapper: View {
  let label: String
  let initialValue: Bool
  let switchId: String?
  var actionHandler: SDUIActionHandler?

  @State private var isOn: Bool

  init(
    label: String,
    initialValue: Bool,
    switchId: String?,
    actionHandler: SDUIActionHandler?
  ) {
    self.label = label
    self.initialValue = initialValue
    self.switchId = switchId
    self.actionHandler = actionHandler
    self._isOn = State(initialValue: initialValue)
  }

  var body: some View {
    CNSwitch(label, isOn: $isOn)
      .onChange(of: initialValue) { _, newValue in
        isOn = newValue
      }
      .onChange(of: isOn) { _, newValue in
        if let switchId {
          actionHandler?.handleAction(
            id: switchId,
            payload: ["value": AnyCodable(newValue)]
          )
        }
      }
  }
}

extension SDUIRegistry {
  public func registerCNSwitch() {
    register("switch") { node, handler in
      let configuration = try CNSwitch.Configuration(node: node)
      return SDUISwitchWrapper(
        label: configuration.label,
        initialValue: configuration.isOn,
        switchId: configuration.switchId,
        actionHandler: handler
      )
    }
  }
}
