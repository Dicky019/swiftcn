//
//  ResolvedTheme.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Resolved theme with SwiftUI Colors, used by components via Environment
public struct ResolvedTheme: Sendable {
    // MARK: - Colors

    public let background: Color
    public let foreground: Color
    public let card: Color
    public let cardForeground: Color
    public let sheet: Color
    public let sheetForeground: Color
    public let primary: Color
    public let primaryForeground: Color
    public let secondary: Color
    public let secondaryForeground: Color
    public let muted: Color
    public let mutedForeground: Color
    public let accent: Color
    public let accentForeground: Color
    public let destructive: Color
    public let destructiveForeground: Color
    public let border: Color
    public let input: Color
    public let focus: Color
    public let warning: Color
    public let warningForeground: Color
    public let success: Color
    public let successForeground: Color
    public let chart1: Color
    public let chart2: Color
    public let chart3: Color
    public let chart4: Color
    public let chart5: Color

    // MARK: - Design Tokens

    public let radius: ThemeRadius
    public let spacing: ThemeSpacing
    public let shadows: ThemeShadows
    public let motion: ThemeMotion
    public let borderWidth: ThemeBorderWidth
    public let opacity: ThemeOpacity

    // MARK: - Initialization

    public init(
        colorScheme: Theme.ColorScheme,
        radius: ThemeRadius,
        spacing: ThemeSpacing,
        shadows: ThemeShadows,
        motion: ThemeMotion,
        borderWidth: ThemeBorderWidth,
        opacity: ThemeOpacity
    ) {
        // Colors
        self.background = Color(hex: colorScheme.background)
        self.foreground = Color(hex: colorScheme.foreground)
        self.card = Color(hex: colorScheme.card)
        self.cardForeground = Color(hex: colorScheme.cardForeground)
        self.sheet = Color(hex: colorScheme.sheet)
        self.sheetForeground = Color(hex: colorScheme.sheetForeground)
        self.primary = Color(hex: colorScheme.primary)
        self.primaryForeground = Color(hex: colorScheme.primaryForeground)
        self.secondary = Color(hex: colorScheme.secondary)
        self.secondaryForeground = Color(hex: colorScheme.secondaryForeground)
        self.muted = Color(hex: colorScheme.muted)
        self.mutedForeground = Color(hex: colorScheme.mutedForeground)
        self.accent = Color(hex: colorScheme.accent)
        self.accentForeground = Color(hex: colorScheme.accentForeground)
        self.destructive = Color(hex: colorScheme.destructive)
        self.destructiveForeground = Color(hex: colorScheme.destructiveForeground)
        self.border = Color(hex: colorScheme.border)
        self.input = Color(hex: colorScheme.input)
        self.focus = Color(hex: colorScheme.focus)
        self.warning = Color(hex: colorScheme.warning)
        self.warningForeground = Color(hex: colorScheme.warningForeground)
        self.success = Color(hex: colorScheme.success)
        self.successForeground = Color(hex: colorScheme.successForeground)
        self.chart1 = Color(hex: colorScheme.chart1)
        self.chart2 = Color(hex: colorScheme.chart2)
        self.chart3 = Color(hex: colorScheme.chart3)
        self.chart4 = Color(hex: colorScheme.chart4)
        self.chart5 = Color(hex: colorScheme.chart5)

        // Tokens
        self.radius = radius
        self.spacing = spacing
        self.shadows = shadows
        self.motion = motion
        self.borderWidth = borderWidth
        self.opacity = opacity
    }

    /// Create from Theme with specific color scheme
    public static func resolve(theme: Theme, isDark: Bool) -> ResolvedTheme {
        ResolvedTheme(
            colorScheme: isDark ? theme.dark : theme.light,
            radius: theme.radius,
            spacing: theme.spacing,
            shadows: theme.shadows,
            motion: theme.motion,
            borderWidth: theme.borderWidth,
            opacity: theme.opacity
        )
    }

    /// Default resolved theme (light mode, Zinc palette)
    public static let `default` = ResolvedTheme.resolve(theme: .default, isDark: false)
}
