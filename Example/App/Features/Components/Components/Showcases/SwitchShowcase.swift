//
//  SwitchShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SwitchShowcase: View {
  @Environment(\.theme) private var theme

  @State private var isOn1 = true
  @State private var isOn2 = false
  @State private var isOn3 = true

  var body: some View {
    VStack(spacing: theme.spacing.md) {
      Text("Switch States")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)

      CNSwitch("Enabled On", isOn: $isOn1)
      CNSwitch("Enabled Off", isOn: $isOn2)
      CNSwitch("Disabled", isOn: .constant(true))
        .disabled(true)

      Text("Standalone Switch")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.sm)

      HStack {
        Text("Airplane Mode")
          .font(.body)
          .foregroundStyle(theme.foreground)
        Spacer()
        CNSwitch(accessibilityLabel: "Airplane Mode", isOn: $isOn3)
      }
    }
  }
}
