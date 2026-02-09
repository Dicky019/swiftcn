//
//  TokenShowcaseView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct TokenShowcaseView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    List {
      colorsSection
      chartColorsSection
      spacingSection
      radiusSection
      shadowsSection
      motionSection
      opacitySection
      borderWidthSection
    }
    .navigationTitle("Design Tokens")
  }

  // MARK: - Colors Section

  private var colorsSection: some View {
    Section("Colors") {
      ColorRow(name: "Background", color: theme.background)
      ColorRow(name: "Foreground", color: theme.foreground)
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

  // MARK: - Chart Colors Section

  private var chartColorsSection: some View {
    Section("Chart Colors") {
      ColorRow(name: "Chart 1", color: theme.chart1)
      ColorRow(name: "Chart 2", color: theme.chart2)
      ColorRow(name: "Chart 3", color: theme.chart3)
      ColorRow(name: "Chart 4", color: theme.chart4)
      ColorRow(name: "Chart 5", color: theme.chart5)
    }
  }

  // MARK: - Spacing Section

  private var spacingSection: some View {
    Section("Spacing") {
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

  // MARK: - Radius Section

  private var radiusSection: some View {
    Section("Radius") {
      RadiusRow(name: "none", value: theme.radius.none)
      RadiusRow(name: "sm", value: theme.radius.sm)
      RadiusRow(name: "md", value: theme.radius.md)
      RadiusRow(name: "lg", value: theme.radius.lg)
      RadiusRow(name: "xl", value: theme.radius.xl)
      RadiusRow(name: "xxl", value: theme.radius.xxl)
      RadiusRow(name: "full", value: theme.radius.full)
    }
  }

  // MARK: - Shadows Section

  private var shadowsSection: some View {
    Section("Shadows") {
      ShadowRow(name: "none", shadow: theme.shadows.none)
      ShadowRow(name: "sm", shadow: theme.shadows.sm)
      ShadowRow(name: "md", shadow: theme.shadows.md)
      ShadowRow(name: "lg", shadow: theme.shadows.lg)
      ShadowRow(name: "xl", shadow: theme.shadows.xl)
    }
  }

  // MARK: - Motion Section

  private var motionSection: some View {
    Section("Motion (Tap to animate)") {
      MotionRow(name: "fast", duration: theme.motion.fast)
      MotionRow(name: "normal", duration: theme.motion.normal)
      MotionRow(name: "slow", duration: theme.motion.slow)
    }
  }

  // MARK: - Opacity Section

  private var opacitySection: some View {
    Section("Opacity") {
      OpacityRow(name: "disabled", value: theme.opacity.disabled)
      OpacityRow(name: "overlay", value: theme.opacity.overlay)
      OpacityRow(name: "hover", value: theme.opacity.hover)
      OpacityRow(name: "muted", value: theme.opacity.muted)
    }
  }

  // MARK: - Border Width Section

  private var borderWidthSection: some View {
    Section("Border Width") {
      BorderWidthRow(name: "none", value: theme.borderWidth.none)
      BorderWidthRow(name: "thin", value: theme.borderWidth.thin)
      BorderWidthRow(name: "regular", value: theme.borderWidth.regular)
      BorderWidthRow(name: "thick", value: theme.borderWidth.thick)
    }
  }
}

#Preview {
  NavigationStack {
    TokenShowcaseView()
  }
  .environment(ThemeProvider())
}
