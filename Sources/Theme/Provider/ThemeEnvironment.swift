//
//  ThemeEnvironment.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - Theme Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ResolvedTheme = .default
}

extension EnvironmentValues {
    /// Access the resolved theme from the environment
    public var theme: ResolvedTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Legacy Theme Provider Key (for backward compatibility)

private struct ThemeProviderKey: EnvironmentKey {
    static let defaultValue: ThemeProvider? = nil
}

extension EnvironmentValues {
    /// Access the theme provider from the environment (legacy)
    public var themeProvider: ThemeProvider? {
        get { self[ThemeProviderKey.self] }
        set { self[ThemeProviderKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject a theme provider into the environment
    public func themeProvider(_ provider: ThemeProvider) -> some View {
        self
            .environment(\.themeProvider, provider)
            .environment(\.theme, provider.resolvedTheme)
    }
}
