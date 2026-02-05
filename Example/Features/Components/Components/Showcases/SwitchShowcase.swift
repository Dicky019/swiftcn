// SwitchShowcase.swift
// swiftcn Example App

import SwiftUI
import Swiftcn

struct SwitchShowcase: View {
    @Environment(\.theme) private var theme

    @State private var isOn1 = true
    @State private var isOn2 = false

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Switch States")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            CNSwitch("Enabled On", isOn: $isOn1)
            CNSwitch("Enabled Off", isOn: $isOn2)
            CNSwitch("Disabled", isOn: .constant(true))
                .disabled(true)
        }
    }
}
