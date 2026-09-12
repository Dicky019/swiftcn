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
      value: Double = 0,
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

    private enum CodingKeys: String, CodingKey {
      case label
      case value
      case minValue
      case maxValue
      case step
      case showValue
      case sliderId
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.label = try container.decodeIfPresent(String.self, forKey: .label)
      self.value = try container.decodeIfPresent(Double.self, forKey: .value) ?? 0
      self.minValue = try container.decodeIfPresent(Double.self, forKey: .minValue) ?? 0
      self.maxValue = try container.decodeIfPresent(Double.self, forKey: .maxValue) ?? 100
      self.step = try container.decodeIfPresent(Double.self, forKey: .step)
      self.showValue = try container.decodeIfPresent(Bool.self, forKey: .showValue) ?? false
      self.sliderId = try container.decodeIfPresent(String.self, forKey: .sliderId)
    }
  }
}

extension CNSlider.Configuration {
  init(node: SDUINode) throws {
    let minValue = try Self.number(node, key: "min") ?? 0
    let maxValue = try Self.number(node, key: "max") ?? 100
    let value = try Self.number(node, key: "value") ?? 0
    let step = try Self.number(node, key: "step")
    let label = try Self.string(node, key: "label")
    let sliderId = try Self.string(node, key: "sliderId")
    let showValue = try node.props["showValue"].map { prop in
      guard let value = prop.boolValue else {
        throw SDUIError.invalidProps(component: "slider", reason: "showValue must be a boolean")
      }
      return value
    } ?? false

    guard minValue.isFinite, maxValue.isFinite, value.isFinite, minValue < maxValue else {
      throw SDUIError.invalidProps(component: "slider", reason: "range is invalid")
    }
    guard (minValue...maxValue).contains(value) else {
      throw SDUIError.invalidProps(component: "slider", reason: "value is outside the range")
    }
    if let step, !step.isFinite || step <= 0 {
      throw SDUIError.invalidProps(component: "slider", reason: "step must be greater than zero")
    }
    self.init(
      label: label,
      value: value,
      minValue: minValue,
      maxValue: maxValue,
      step: step,
      showValue: showValue,
      sliderId: sliderId
    )
  }

  private static func number(_ node: SDUINode, key: String) throws -> Double? {
    guard let prop = node.props[key] else { return nil }
    guard let value = prop.doubleValue else {
      throw SDUIError.invalidProps(component: "slider", reason: "\(key) must be a number")
    }
    return value
  }

  private static func string(_ node: SDUINode, key: String) throws -> String? {
    guard let prop = node.props[key] else { return nil }
    guard let value = prop.stringValue else {
      throw SDUIError.invalidProps(component: "slider", reason: "\(key) must be a string")
    }
    return value
  }
}

private struct SDUISliderWrapper: View {
  let label: String
  let initialValue: Double
  let range: ClosedRange<Double>
  let step: Double?
  let showValue: Bool
  let sliderId: String?
  var actionHandler: SDUIActionHandler?

  @State private var value: Double

  init(
    label: String,
    initialValue: Double,
    range: ClosedRange<Double>,
    step: Double?,
    showValue: Bool,
    sliderId: String?,
    actionHandler: SDUIActionHandler?
  ) {
    self.label = label
    self.initialValue = initialValue
    self.range = range
    self.step = step
    self.showValue = showValue
    self.sliderId = sliderId
    self.actionHandler = actionHandler
    self._value = State(initialValue: initialValue)
  }

  var body: some View {
    Group {
      if let step {
        CNSlider(
          label,
          value: $value,
          in: range,
          step: step,
          showValue: showValue
        )
      } else {
        CNSlider(
          label,
          value: $value,
          in: range,
          showValue: showValue
        )
      }
    }
    .onChange(of: value) { _, newValue in
      if let sliderId {
        actionHandler?.handleAction(
          id: sliderId,
          payload: ["value": AnyCodable(newValue)]
        )
      }
    }
  }
}

extension SDUIRegistry {
  public func registerCNSlider() {
    register("slider") { node, handler in
      let configuration = try CNSlider.Configuration(node: node)
      return SDUISliderWrapper(
        label: configuration.label ?? "",
        initialValue: configuration.value,
        range: configuration.minValue...configuration.maxValue,
        step: configuration.step,
        showValue: configuration.showValue,
        sliderId: configuration.sliderId,
        actionHandler: handler
      )
    }
  }
}
