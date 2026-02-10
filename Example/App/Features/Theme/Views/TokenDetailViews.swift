//
//  TokenDetailViews.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

// MARK: - Colors Token View

struct ColorsTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          ColorRow(name: "Background", color: theme.background)
          ColorRow(name: "Foreground", color: theme.foreground)
          ColorRow(name: "Text", color: theme.text)
          ColorRow(name: "Text Secondary", color: theme.textSecondary)
          ColorRow(name: "Text Muted", color: theme.textMuted)
          ColorRow(name: "Primary", color: theme.primary)
          ColorRow(name: "Primary Foreground", color: theme.primaryForeground)
          ColorRow(name: "Secondary", color: theme.secondary)
          ColorRow(name: "Muted", color: theme.muted)
          ColorRow(name: "Accent", color: theme.accent)
          ColorRow(name: "Destructive", color: theme.destructive)
          ColorRow(name: "Border", color: theme.border)
          ColorRow(name: "Card", color: theme.card)
          ColorRow(name: "Sheet", color: theme.sheet)
          ColorRow(name: "Warning", color: theme.warning)
          ColorRow(name: "Success", color: theme.success)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Colors")
    .background(theme.background)
  }
}

// MARK: - Chart Colors Token View

struct ChartColorsTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          ColorRow(name: "Chart 1", color: theme.chart1)
          ColorRow(name: "Chart 2", color: theme.chart2)
          ColorRow(name: "Chart 3", color: theme.chart3)
          ColorRow(name: "Chart 4", color: theme.chart4)
          ColorRow(name: "Chart 5", color: theme.chart5)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Chart Colors")
    .background(theme.background)
  }
}

// MARK: - Spacing Token View

struct SpacingTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          SpacingRow(name: "none", value: theme.spacing.none)
          SpacingRow(name: "xs", value: theme.spacing.xs)
          SpacingRow(name: "sm", value: theme.spacing.sm)
          SpacingRow(name: "md", value: theme.spacing.md)
          SpacingRow(name: "lg", value: theme.spacing.lg)
          SpacingRow(name: "xl", value: theme.spacing.xl)
          SpacingRow(name: "xxl", value: theme.spacing.xxl)
          SpacingRow(name: "xxxl", value: theme.spacing.xxxl)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Spacing")
    .background(theme.background)
  }
}

// MARK: - Radius Token View

struct RadiusTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          RadiusRow(name: "none", value: theme.radius.none)
          RadiusRow(name: "sm", value: theme.radius.sm)
          RadiusRow(name: "md", value: theme.radius.md)
          RadiusRow(name: "lg", value: theme.radius.lg)
          RadiusRow(name: "xl", value: theme.radius.xl)
          RadiusRow(name: "xxl", value: theme.radius.xxl)
          RadiusRow(name: "full", value: theme.radius.full)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Radius")
    .background(theme.background)
  }
}

// MARK: - Shadows Token View

struct ShadowsTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          ShadowRow(name: "none", shadow: theme.shadows.none)
          ShadowRow(name: "sm", shadow: theme.shadows.sm)
          ShadowRow(name: "md", shadow: theme.shadows.md)
          ShadowRow(name: "lg", shadow: theme.shadows.lg)
          ShadowRow(name: "xl", shadow: theme.shadows.xl)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Shadows")
    .background(theme.background)
  }
}

// MARK: - Motion Token View

struct MotionTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text("Tap to animate")
            .font(.caption)
            .foregroundStyle(theme.textMuted)
          Divider()
          MotionRow(name: "fast", duration: theme.motion.fast)
          MotionRow(name: "normal", duration: theme.motion.normal)
          MotionRow(name: "slow", duration: theme.motion.slow)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Motion")
    .background(theme.background)
  }
}

// MARK: - Opacity Token View

struct OpacityTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          OpacityRow(name: "disabled", value: theme.opacity.disabled)
          OpacityRow(name: "overlay", value: theme.opacity.overlay)
          OpacityRow(name: "hover", value: theme.opacity.hover)
          OpacityRow(name: "muted", value: theme.opacity.muted)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Opacity")
    .background(theme.background)
  }
}

// MARK: - Border Width Token View

struct BorderWidthTokenView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    ScrollView {
      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          BorderWidthRow(name: "none", value: theme.borderWidth.none)
          BorderWidthRow(name: "thin", value: theme.borderWidth.thin)
          BorderWidthRow(name: "regular", value: theme.borderWidth.regular)
          BorderWidthRow(name: "thick", value: theme.borderWidth.thick)
        }
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle("Border Width")
    .background(theme.background)
  }
}

// MARK: - Previews

#Preview("Colors") {
  NavigationStack {
    ColorsTokenView()
  }
  .environment(ThemeProvider())
}

#Preview("Spacing") {
  NavigationStack {
    SpacingTokenView()
  }
  .environment(ThemeProvider())
}

#Preview("Motion") {
  NavigationStack {
    MotionTokenView()
  }
  .environment(ThemeProvider())
}
