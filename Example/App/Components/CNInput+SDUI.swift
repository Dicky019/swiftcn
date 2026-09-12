//
//  CNInput+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNInput {
  /// Configuration for SDUI rendering
  public struct Configuration: Codable, Sendable, Hashable {
    public let placeholder: String
    public let label: String?
    public let isError: Bool
    public let errorMessage: String?
    public let inputId: String?

    public init(
      placeholder: String,
      label: String? = nil,
      isError: Bool = false,
      errorMessage: String? = nil,
      inputId: String? = nil
    ) {
      self.placeholder = placeholder
      self.label = label
      self.isError = isError
      self.errorMessage = errorMessage
      self.inputId = inputId
    }
  }
}

extension CNInput.Configuration {
  init(node: SDUINode) throws {
    guard let placeholder = node.props["placeholder"]?.stringValue else {
      throw SDUIError.invalidProps(component: "input", reason: "placeholder is required")
    }
    let label = try node.props["label"].map { prop in
      guard let value = prop.stringValue else {
        throw SDUIError.invalidProps(component: "input", reason: "label must be a string")
      }
      return value
    }
    let isError = try node.props["isError"].map { prop in
      guard let value = prop.boolValue else {
        throw SDUIError.invalidProps(component: "input", reason: "isError must be a boolean")
      }
      return value
    } ?? false
    let errorMessage = try node.props["errorMessage"].map { prop in
      guard let value = prop.stringValue else {
        throw SDUIError.invalidProps(component: "input", reason: "errorMessage must be a string")
      }
      return value
    }
    let inputId = try node.props["inputId"].map { prop in
      guard let value = prop.stringValue else {
        throw SDUIError.invalidProps(component: "input", reason: "inputId must be a string")
      }
      return value
    }
    self.init(
      placeholder: placeholder,
      label: label,
      isError: isError,
      errorMessage: errorMessage,
      inputId: inputId
    )
  }
}

private struct SDUIInputWrapper: View {
  let placeholder: String
  let label: String?
  let isError: Bool
  let errorMessage: String?
  let inputId: String?
  var actionHandler: SDUIActionHandler?

  @State private var text = ""

  var body: some View {
    CNInput(
      placeholder,
      text: $text,
      label: label,
      isError: isError,
      errorMessage: errorMessage
    )
    .onChange(of: text) { _, newValue in
      if let inputId {
        actionHandler?.handleAction(
          id: inputId,
          payload: ["value": AnyCodable(newValue)]
        )
      }
    }
  }
}

extension SDUIRegistry {
  public func registerCNInput() {
    register("input") { node, handler in
      let configuration = try CNInput.Configuration(node: node)
      return SDUIInputWrapper(
        placeholder: configuration.placeholder,
        label: configuration.label,
        isError: configuration.isError,
        errorMessage: configuration.errorMessage,
        inputId: configuration.inputId,
        actionHandler: handler
      )
    }
  }
}
