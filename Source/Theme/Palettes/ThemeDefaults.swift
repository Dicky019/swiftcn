//
//  ThemeDefaults.swift
//  Source/Theme/Palettes
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

extension Theme {
    /// Default theme using shadcn Zinc palette
    public static let `default` = Theme(
        light: .defaultLight,
        dark: .defaultDark
    )
}

extension Theme.ColorScheme {
    /// Default light color scheme (Zinc palette)
    public static let defaultLight = Theme.ColorScheme(
        background: "#ffffff",
        foreground: "#09090b",
        card: "#ffffff",
        cardForeground: "#09090b",
        sheet: "#ffffff",
        sheetForeground: "#09090b",
        primary: "#18181b",
        primaryForeground: "#fafafa",
        secondary: "#f4f4f5",
        secondaryForeground: "#18181b",
        muted: "#f4f4f5",
        mutedForeground: "#71717a",
        accent: "#f4f4f5",
        accentForeground: "#18181b",
        destructive: "#ef4444",
        destructiveForeground: "#fafafa",
        border: "#e4e4e7",
        input: "#e4e4e7",
        focus: "#18181b",
        warning: "#f59e0b",
        warningForeground: "#ffffff",
        success: "#22c55e",
        successForeground: "#ffffff",
        chart1: "#e76e50",
        chart2: "#2a9d90",
        chart3: "#274754",
        chart4: "#e8c468",
        chart5: "#f4a462"
    )

    /// Default dark color scheme (Zinc palette)
    public static let defaultDark = Theme.ColorScheme(
        background: "#09090b",
        foreground: "#fafafa",
        card: "#09090b",
        cardForeground: "#fafafa",
        sheet: "#09090b",
        sheetForeground: "#fafafa",
        primary: "#fafafa",
        primaryForeground: "#18181b",
        secondary: "#27272a",
        secondaryForeground: "#fafafa",
        muted: "#27272a",
        mutedForeground: "#a1a1aa",
        accent: "#27272a",
        accentForeground: "#fafafa",
        destructive: "#7f1d1d",
        destructiveForeground: "#fafafa",
        border: "#27272a",
        input: "#27272a",
        focus: "#d4d4d8",
        warning: "#fbbf24",
        warningForeground: "#18181b",
        success: "#4ade80",
        successForeground: "#18181b",
        chart1: "#e76e50",
        chart2: "#2a9d90",
        chart3: "#274754",
        chart4: "#e8c468",
        chart5: "#f4a462"
    )
}
