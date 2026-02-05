//
//  ReduceMotionRow.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI
import Swiftcn

struct ReduceMotionRow: View {
  @Environment(\.theme) private var theme
  @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

  @AppStorage("reduceMotion") private var appReduceMotion: Bool = false

  private var effectiveReduceMotion: Bool {
    appReduceMotion || systemReduceMotion
  }

  var body: some View {
    Toggle(isOn: $appReduceMotion) {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: effectiveReduceMotion ? "figure.stand" : "figure.walk.motion")
          .font(.title2)
          .foregroundStyle(effectiveReduceMotion ? theme.primary : theme.mutedForeground)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("Reduce Motion")
            .font(.body)
            .foregroundStyle(theme.foreground)

          if systemReduceMotion {
            Text("System enabled - Always on")
              .font(.caption)
              .foregroundStyle(theme.primary)
          } else {
            Text("Override system setting")
              .font(.caption)
              .foregroundStyle(theme.mutedForeground)
          }
        }
      }
    }
    .tint(theme.primary)
    .disabled(systemReduceMotion)
  }
}
