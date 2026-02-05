//
//  CNSlider.swift
//  Source/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A range input control with optional label and value display.
///
/// Usage:
/// ```swift
/// @State private var volume: Double = 50
///
/// CNSlider("Volume", value: $volume, in: 0...100)
/// ```
public struct CNSlider: View {

    // MARK: - Properties

    private let label: String?
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let showValue: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.theme) private var theme

    // MARK: - Initializers

    public init(
        _ label: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...100,
        step: Double? = nil,
        showValue: Bool = false
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.showValue = showValue
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if label != nil || showValue {
                HStack {
                    if let label {
                        Text(label)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    Spacer()
                    if showValue {
                        Text(value, format: .number.precision(.fractionLength(0)))
                            .font(.footnote)
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
            }

            if let step {
                Slider(value: $value, in: range, step: step)
                    .tint(theme.primary)
            } else {
                Slider(value: $value, in: range)
                    .tint(theme.primary)
            }
        }
        .opacity(isEnabled ? 1.0 : theme.opacity.disabled)
        .accessibilityLabel(label ?? "Slider")
        .accessibilityValue("\(Int(value))")
    }
}

// MARK: - Previews

#Preview("CNSlider") {
    VStack(spacing: 24) {
        CNSlider(value: .constant(50))
        CNSlider("Volume", value: .constant(75), showValue: true)
        CNSlider("Brightness", value: .constant(30), in: 0...100, step: 10, showValue: true)
    }
    .padding()
}
