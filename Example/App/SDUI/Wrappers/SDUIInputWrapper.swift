//
//  SDUIInputWrapper.swift
//  Sources/SDUI/Wrappers
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Wrapper for CNInput that manages its own state in SDUI context
struct SDUIInputWrapper: View {
  let placeholder: String
  let label: String?
  let isError: Bool
  let errorMessage: String?
  let inputId: String?
  var actionHandler: SDUIActionHandler?

  @State private var text = ""

  var body: some View {
    CNInput(placeholder, text: $text, label: label, isError: isError, errorMessage: errorMessage)
      .onChange(of: text) { _, newValue in
        if let inputId {
          actionHandler?.handleAction(id: inputId, payload: ["value": AnyCodable(newValue)])
        }
      }
  }
}
