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

    /// Initialize from SDUI node props
    public init(from props: [String: AnyCodable]) {
      self.placeholder = props["placeholder"]?.asString ?? ""
      self.label = props["label"]?.asString
      self.isError = props["isError"]?.asBool ?? false
      self.errorMessage = props["errorMessage"]?.asString
      self.inputId = props["inputId"]?.asString
    }
  }
}
