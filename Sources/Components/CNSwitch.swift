//
//  CNSwitch.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A toggle switch control for boolean values.
///
/// Usage:
/// ```swift
/// @State private var isEnabled = false
///
/// CNSwitch("Enable notifications", isOn: $isEnabled)
/// ```
public struct CNSwitch: View {

  // MARK: - Properties

  private let label: String
  @Binding private var isOn: Bool

  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.theme) private var theme

  // MARK: - Initializers

  public init(
    _ label: String,
    isOn: Binding<Bool>
  ) {
    self.label = label
    self._isOn = isOn
  }

  // MARK: - Body

  public var body: some View {
    Toggle(label, isOn: $isOn)
      .tint(theme.primary)
      .opacity(isEnabled ? 1.0 : theme.opacity.disabled)
      .accessibilityLabel(label)
      .accessibilityValue(isOn ? "On" : "Off")
      .accessibilityAddTraits(.isButton)
  }
}

// MARK: - Previews

#Preview("CNSwitch States") {
  VStack(spacing: 20) {
    CNSwitch("Enable notifications", isOn: .constant(true))
    CNSwitch("Dark mode", isOn: .constant(false))
    CNSwitch("Disabled switch", isOn: .constant(true))
      .disabled(true)
  }
  .padding()
}
