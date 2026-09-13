//
//  CNSwitch.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A toggle switch control for boolean values styled after shadcn/ui.
///
/// Usage:
/// ```swift
/// @State private var isEnabled = false
///
/// CNSwitch("Enable notifications", isOn: $isEnabled)
/// ```
public struct CNSwitch: View {

  // MARK: - Properties

  private let label: String?
  private let accessibilityLabel: String?
  @Binding private var isOn: Bool

  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.theme) private var theme

  // MARK: - Initializers

  /// Switch with a visible label.
  public init(
    _ label: String,
    isOn: Binding<Bool>
  ) {
    self.label = label
    self.accessibilityLabel = nil
    self._isOn = isOn
  }

  /// Standalone switch with an explicit accessibility label for assistive technologies.
  public init(
    accessibilityLabel: String,
    isOn: Binding<Bool>
  ) {
    self.label = nil
    self.accessibilityLabel = accessibilityLabel
    self._isOn = isOn
  }

  // MARK: - Body

  public var body: some View {
    if let label {
      Toggle(label, isOn: $isOn)
        .toggleStyle(.cnSwitch)
    } else if let accessibilityLabel {
      Toggle(isOn: $isOn) {
        Text(accessibilityLabel)
      }
      .toggleStyle(CNSwitchToggleStyle(standalone: true))
      .labelsHidden()
      .accessibilityLabel(accessibilityLabel)
    }
  }
}

// MARK: - CNSwitchToggleStyle

/// A ToggleStyle that replicates the shadcn/ui Switch appearance while preserving native toggle accessibility.
public struct CNSwitchToggleStyle: ToggleStyle {
  @Environment(\.theme) private var theme
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let standalone: Bool

  public init(standalone: Bool = false) {
    self.standalone = standalone
  }

  private var toggleAnimation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: theme.motion.fast)
  }

  public func makeBody(configuration: Configuration) -> some View {
    Button {
      guard isEnabled else { return }
      withAnimation(toggleAnimation) {
        configuration.isOn.toggle()
      }
    } label: {
      if standalone {
        switchControl(configuration: configuration)
      } else {
        HStack {
          configuration.label
            .font(.body)
            .foregroundStyle(theme.foreground)
            .frame(maxWidth: .infinity, alignment: .leading)

          Spacer()

          switchControl(configuration: configuration)
        }
        .contentShape(Rectangle())
      }
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1.0 : theme.opacity.disabled)
  }

  private func switchControl(configuration: Configuration) -> some View {
    ZStack(alignment: configuration.isOn ? .trailing : .leading) {
      Capsule()
        .fill(configuration.isOn ? theme.primary : theme.input)
        .frame(width: 44, height: 24)

      Circle()
        .fill(theme.background)
        .frame(width: 20, height: 20)
        .padding(2)
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(Rectangle())
  }
}

extension ToggleStyle where Self == CNSwitchToggleStyle {
  public static var cnSwitch: CNSwitchToggleStyle { CNSwitchToggleStyle() }
}

// MARK: - Previews

#Preview("CNSwitch States") {
  VStack(spacing: 20) {
    CNSwitch("Enable notifications", isOn: .constant(true))
    CNSwitch("Dark mode", isOn: .constant(false))
    CNSwitch(accessibilityLabel: "Wi-Fi", isOn: .constant(true))
    CNSwitch("Disabled switch", isOn: .constant(true))
      .disabled(true)
  }
  .padding()
}
