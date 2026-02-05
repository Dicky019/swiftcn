//
//  SliderShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI
import Swiftcn

struct SliderShowcase: View {
    @Environment(\.theme) private var theme

    @State private var value: Double = 50
    @State private var brightness: Double = 75

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Slider")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            CNSlider(value: $value, in: 0...100)

            CNSlider("Volume", value: $value, showValue: true)

            CNSlider("Brightness", value: $brightness, in: 0...100, step: 10, showValue: true)

            CNSlider("Disabled", value: .constant(30), showValue: true)
                .disabled(true)
        }
    }
}
