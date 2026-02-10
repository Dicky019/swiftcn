//
//  ThemeTests.swift
//  Tests
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Testing
import SwiftUI
@testable import Example

@Suite("Theme Tests")
struct ThemeTests {
  
  // MARK: - Theme Defaults
  
  @Test("Default theme has light and dark color schemes")
  func defaultThemeHasColorSchemes() {
    let theme = Theme.default
    #expect(theme.light.background == "#ffffff")
    #expect(theme.dark.background == "#09090b")
  }

  @Test("Default theme has text hierarchy tokens")
  func defaultThemeHasTextHierarchy() {
    let theme = Theme.default
    // Light
    #expect(theme.light.text == "#09090b")
    #expect(theme.light.textSecondary == "#52525b")
    #expect(theme.light.textMuted == "#71717a")
    // Dark
    #expect(theme.dark.text == "#fafafa")
    #expect(theme.dark.textSecondary == "#a1a1aa")
    #expect(theme.dark.textMuted == "#71717a")
  }
  
  @Test("Default theme has design tokens")
  func defaultThemeHasTokens() {
    let theme = Theme.default
    #expect(theme.radius.md == 8)
    #expect(theme.spacing.md == 16)
    #expect(theme.shadows.md.radius == 4)
    #expect(theme.motion.normal == 0.3)
    #expect(theme.borderWidth.regular == 1)
    #expect(theme.opacity.disabled == 0.5)
  }
  
  // MARK: - Theme Parsing
  
  @Test("Theme can be decoded from JSON")
  func themeDecodesFromJSON() throws {
    let json = """
        {
          "light": {
            "background": "#ffffff",
            "foreground": "#000000",
            "card": "#ffffff",
            "cardForeground": "#000000",
            "sheet": "#ffffff",
            "sheetForeground": "#000000",
            "primary": "#0000ff",
            "primaryForeground": "#ffffff",
            "secondary": "#cccccc",
            "secondaryForeground": "#000000",
            "muted": "#eeeeee",
            "mutedForeground": "#666666",
            "accent": "#dddddd",
            "accentForeground": "#000000",
            "destructive": "#ff0000",
            "destructiveForeground": "#ffffff",
            "border": "#e0e0e0",
            "input": "#e0e0e0",
            "focus": "#0000ff",
            "warning": "#ffaa00",
            "warningForeground": "#000000",
            "success": "#00ff00",
            "successForeground": "#000000",
            "chart1": "#ff0000",
            "chart2": "#00ff00",
            "chart3": "#0000ff",
            "chart4": "#ffff00",
            "chart5": "#ff00ff"
          },
          "dark": {
            "background": "#000000",
            "foreground": "#ffffff",
            "card": "#111111",
            "cardForeground": "#ffffff",
            "sheet": "#111111",
            "sheetForeground": "#ffffff",
            "primary": "#3333ff",
            "primaryForeground": "#ffffff",
            "secondary": "#333333",
            "secondaryForeground": "#ffffff",
            "muted": "#222222",
            "mutedForeground": "#999999",
            "accent": "#333333",
            "accentForeground": "#ffffff",
            "destructive": "#cc0000",
            "destructiveForeground": "#ffffff",
            "border": "#333333",
            "input": "#333333",
            "focus": "#3333ff",
            "warning": "#ffcc00",
            "warningForeground": "#000000",
            "success": "#33ff33",
            "successForeground": "#000000",
            "chart1": "#ff3333",
            "chart2": "#33ff33",
            "chart3": "#3333ff",
            "chart4": "#ffff33",
            "chart5": "#ff33ff"
          }
        }
        """
    let data = json.data(using: .utf8)!
    let theme = try JSONDecoder().decode(Theme.self, from: data)
    
    #expect(theme.light.primary == "#0000ff")
    #expect(theme.dark.primary == "#3333ff")
    // Text hierarchy falls back to foreground/mutedForeground when not in JSON
    #expect(theme.light.text == "#000000")
    #expect(theme.light.textSecondary == "#666666")
    #expect(theme.light.textMuted == "#666666")
  }
  
  @Test("Theme with custom tokens can be decoded")
  func themeWithCustomTokensDecodes() throws {
    let json = """
        {
          "light": {
            "background": "#ffffff",
            "foreground": "#000000",
            "card": "#ffffff",
            "cardForeground": "#000000",
            "sheet": "#ffffff",
            "sheetForeground": "#000000",
            "primary": "#0000ff",
            "primaryForeground": "#ffffff",
            "secondary": "#cccccc",
            "secondaryForeground": "#000000",
            "muted": "#eeeeee",
            "mutedForeground": "#666666",
            "accent": "#dddddd",
            "accentForeground": "#000000",
            "destructive": "#ff0000",
            "destructiveForeground": "#ffffff",
            "border": "#e0e0e0",
            "input": "#e0e0e0",
            "focus": "#0000ff",
            "warning": "#ffaa00",
            "warningForeground": "#000000",
            "success": "#00ff00",
            "successForeground": "#000000",
            "chart1": "#ff0000",
            "chart2": "#00ff00",
            "chart3": "#0000ff",
            "chart4": "#ffff00",
            "chart5": "#ff00ff"
          },
          "dark": {
            "background": "#000000",
            "foreground": "#ffffff",
            "card": "#111111",
            "cardForeground": "#ffffff",
            "sheet": "#111111",
            "sheetForeground": "#ffffff",
            "primary": "#3333ff",
            "primaryForeground": "#ffffff",
            "secondary": "#333333",
            "secondaryForeground": "#ffffff",
            "muted": "#222222",
            "mutedForeground": "#999999",
            "accent": "#333333",
            "accentForeground": "#ffffff",
            "destructive": "#cc0000",
            "destructiveForeground": "#ffffff",
            "border": "#333333",
            "input": "#333333",
            "focus": "#3333ff",
            "warning": "#ffcc00",
            "warningForeground": "#000000",
            "success": "#33ff33",
            "successForeground": "#000000",
            "chart1": "#ff3333",
            "chart2": "#33ff33",
            "chart3": "#3333ff",
            "chart4": "#ffff33",
            "chart5": "#ff33ff"
          },
          "radius": {
            "none": 0,
            "sm": 2,
            "md": 4,
            "lg": 8,
            "xl": 12,
            "xxl": 20,
            "full": 9999
          },
          "spacing": {
            "none": 0,
            "xs": 2,
            "sm": 4,
            "md": 8,
            "lg": 12,
            "xl": 16,
            "xxl": 24,
            "xxxl": 32
          }
        }
        """
    let data = json.data(using: .utf8)!
    let theme = try JSONDecoder().decode(Theme.self, from: data)
    
    #expect(theme.radius.md == 4)
    #expect(theme.spacing.md == 8)
  }
  
  // MARK: - ResolvedTheme
  
  @Test("ResolvedTheme resolves light mode correctly")
  func resolvedThemeLightMode() {
    let resolved = ResolvedTheme.resolve(theme: .default, isDark: false)
    #expect(resolved.radius.md == 8)
    #expect(resolved.spacing.md == 16)
  }
  
  @Test("ResolvedTheme resolves dark mode correctly")
  func resolvedThemeDarkMode() {
    let resolved = ResolvedTheme.resolve(theme: .default, isDark: true)
    #expect(resolved.radius.md == 8)
    #expect(resolved.spacing.md == 16)
  }
  
  // MARK: - Color+Hex
  
  @Test("Color parses 6-digit hex")
  func colorParses6DigitHex() {
    let color = Color(hex: "#FF0000")
    #expect(color != Color.clear)
  }
  
  @Test("Color parses 8-digit hex with alpha")
  func colorParses8DigitHex() {
    let color = Color(hex: "#80FF0000")
    #expect(color != Color.clear)
  }
  
  @Test("Color parses hex without hash")
  func colorParsesHexWithoutHash() {
    let color = Color(hex: "00FF00")
    #expect(color != Color.clear)
  }

  // MARK: - ThemeProvider Color Scheme Tracking

  @Test("ThemeProvider updates system color scheme")
  @MainActor
  func themeProviderUpdatesSystemColorScheme() {
    let provider = ThemeProvider()
    provider.colorSchemePreference = .system

    // Initially light
    #expect(provider.effectiveColorScheme == .light)

    // Update to dark
    provider.updateSystemColorScheme(.dark)
    #expect(provider.effectiveColorScheme == .dark)

    // Update back to light
    provider.updateSystemColorScheme(.light)
    #expect(provider.effectiveColorScheme == .light)
  }

  @Test("ThemeProvider ignores system scheme when preference is explicit")
  @MainActor
  func themeProviderIgnoresSystemSchemeWhenExplicit() {
    let provider = ThemeProvider()
    provider.colorSchemePreference = .dark

    // Should stay dark even when system is light
    provider.updateSystemColorScheme(.light)
    #expect(provider.effectiveColorScheme == .dark)

    provider.colorSchemePreference = .light
    provider.updateSystemColorScheme(.dark)
    #expect(provider.effectiveColorScheme == .light)
  }

  @Test("ThemeProvider resolvedColorScheme returns nil for system preference")
  @MainActor
  func themeProviderResolvedColorSchemeNilForSystem() {
    let provider = ThemeProvider()
    provider.colorSchemePreference = .system
    #expect(provider.resolvedColorScheme == nil)

    provider.colorSchemePreference = .light
    #expect(provider.resolvedColorScheme == .light)

    provider.colorSchemePreference = .dark
    #expect(provider.resolvedColorScheme == .dark)
  }

  // MARK: - ThemeProvider Error Handling

  @Test("ThemeProvider.apply throws ThemeError.decodingFailed for invalid JSON structure")
  @MainActor
  func themeProviderThrowsDecodingFailed() {
    let provider = ThemeProvider()
    let invalidJSON = """
      {"light": {"background": "#fff"}}
      """
    let data = invalidJSON.data(using: .utf8)!

    do {
      try provider.apply(data)
      Issue.record("Expected ThemeError.decodingFailed to be thrown")
    } catch let error as ThemeError {
      switch error {
      case .decodingFailed:
        // Expected
        break
      case .invalidJSON:
        Issue.record("Expected .decodingFailed, got .invalidJSON")
      }
    } catch {
      Issue.record("Expected ThemeError, got \(type(of: error))")
    }
  }
}
