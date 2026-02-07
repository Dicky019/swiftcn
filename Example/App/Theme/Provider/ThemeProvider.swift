//
//  ThemeProvider.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - Color Scheme Preference

public enum ColorSchemePreference: String, Codable, Sendable, CaseIterable {
    case light
    case dark
    case system
}

// MARK: - Theme Provider

/// Observable theme state manager
@Observable
@MainActor
public final class ThemeProvider: Sendable {
    /// Current theme (from server or default)
    public private(set) var currentTheme: Theme

    /// User's color scheme preference
    public var colorSchemePreference: ColorSchemePreference {
        didSet {
            UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: "themeMode")
            updateResolvedTheme()
        }
    }

    /// System color scheme (tracked for system preference)
    private var systemColorScheme: SwiftUI.ColorScheme = .light

    /// Resolved theme with SwiftUI Colors
    public private(set) var resolvedTheme: ResolvedTheme

    /// Resolved ColorScheme for preferredColorScheme modifier
    public var resolvedColorScheme: SwiftUI.ColorScheme? {
        switch colorSchemePreference {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }

    /// Current effective color scheme (light or dark)
    public var effectiveColorScheme: SwiftUI.ColorScheme {
        switch colorSchemePreference {
        case .light: .light
        case .dark: .dark
        case .system: systemColorScheme
        }
    }

    // MARK: - Initialization

    public init(theme: Theme = .default) {
        self.currentTheme = theme

        let savedMode = UserDefaults.standard.string(forKey: "themeMode")
        self.colorSchemePreference = ColorSchemePreference(rawValue: savedMode ?? "") ?? .system

        // Initial resolve (will be updated when system scheme is known)
        self.resolvedTheme = ResolvedTheme.resolve(theme: theme, isDark: false)
    }

    // MARK: - Theme Updates

    /// Apply theme from JSON data (SDUI)
    public func apply(_ data: Data) throws {
        let theme = try JSONDecoder().decode(Theme.self, from: data)
        currentTheme = theme
        updateResolvedTheme()
    }

    /// Apply theme from JSON string (SDUI)
    public func apply(jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw ThemeError.invalidJSON
        }
        try apply(data)
    }

    /// Reset to default theme
    public func resetToDefault() {
        currentTheme = .default
        updateResolvedTheme()
    }

    /// Update system color scheme (call from view's onChange)
    public func updateSystemColorScheme(_ scheme: SwiftUI.ColorScheme) {
        guard systemColorScheme != scheme else { return }
        systemColorScheme = scheme
        if colorSchemePreference == .system {
            updateResolvedTheme()
        }
    }

    /// Cycle to the next color scheme preference
    public func cyclePreference() {
        switch colorSchemePreference {
        case .light: colorSchemePreference = .dark
        case .dark: colorSchemePreference = .system
        case .system: colorSchemePreference = .light
        }
    }

    // MARK: - Private

    private func updateResolvedTheme() {
        let isDark = effectiveColorScheme == .dark
        resolvedTheme = ResolvedTheme.resolve(theme: currentTheme, isDark: isDark)
    }
}

// MARK: - Theme Error

public enum ThemeError: Error, LocalizedError {
    case invalidJSON
    case decodingFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "Invalid JSON string"
        case .decodingFailed(let error):
            return "Failed to decode theme: \(error.localizedDescription)"
        }
    }
}
