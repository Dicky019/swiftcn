//
//  Theme.swift
//  Sources/Theme/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import Foundation

// MARK: - Theme

/// Codable theme model for SDUI and JSON configuration
public struct Theme: Codable, Sendable, Equatable {
  public let light: ColorScheme
  public let dark: ColorScheme
  public let radius: ThemeRadius
  public let spacing: ThemeSpacing
  public let shadows: ThemeShadows
  public let motion: ThemeMotion
  public let borderWidth: ThemeBorderWidth
  public let opacity: ThemeOpacity

  public init(
    light: ColorScheme,
    dark: ColorScheme,
    radius: ThemeRadius = .default,
    spacing: ThemeSpacing = .default,
    shadows: ThemeShadows = .default,
    motion: ThemeMotion = .default,
    borderWidth: ThemeBorderWidth = .default,
    opacity: ThemeOpacity = .default
  ) {
    self.light = light
    self.dark = dark
    self.radius = radius
    self.spacing = spacing
    self.shadows = shadows
    self.motion = motion
    self.borderWidth = borderWidth
    self.opacity = opacity
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    light = try container.decode(ColorScheme.self, forKey: .light)
    dark = try container.decode(ColorScheme.self, forKey: .dark)
    radius = try container.decodeIfPresent(ThemeRadius.self, forKey: .radius) ?? .default
    spacing = try container.decodeIfPresent(ThemeSpacing.self, forKey: .spacing) ?? .default
    shadows = try container.decodeIfPresent(ThemeShadows.self, forKey: .shadows) ?? .default
    motion = try container.decodeIfPresent(ThemeMotion.self, forKey: .motion) ?? .default
    borderWidth = try container.decodeIfPresent(ThemeBorderWidth.self, forKey: .borderWidth) ?? .default
    opacity = try container.decodeIfPresent(ThemeOpacity.self, forKey: .opacity) ?? .default
  }

  // MARK: - ColorScheme

  public struct ColorScheme: Codable, Sendable, Equatable {
    // Background & Foreground
    public let background: String
    public let foreground: String

    // Card
    public let card: String
    public let cardForeground: String

    // Sheet (iOS adaptation of popover)
    public let sheet: String
    public let sheetForeground: String

    // Primary
    public let primary: String
    public let primaryForeground: String

    // Secondary
    public let secondary: String
    public let secondaryForeground: String

    // Muted
    public let muted: String
    public let mutedForeground: String

    // Accent
    public let accent: String
    public let accentForeground: String

    // Destructive
    public let destructive: String
    public let destructiveForeground: String

    // Utility
    public let border: String
    public let input: String
    public let focus: String

    // Status Colors
    public let warning: String
    public let warningForeground: String
    public let success: String
    public let successForeground: String

    // Chart Colors
    public let chart1: String
    public let chart2: String
    public let chart3: String
    public let chart4: String
    public let chart5: String

    // Text Hierarchy
    public let text: String
    public let textSecondary: String
    public let textMuted: String

    public init(
      background: String,
      foreground: String,
      card: String,
      cardForeground: String,
      sheet: String,
      sheetForeground: String,
      primary: String,
      primaryForeground: String,
      secondary: String,
      secondaryForeground: String,
      muted: String,
      mutedForeground: String,
      accent: String,
      accentForeground: String,
      destructive: String,
      destructiveForeground: String,
      border: String,
      input: String,
      focus: String,
      warning: String,
      warningForeground: String,
      success: String,
      successForeground: String,
      chart1: String,
      chart2: String,
      chart3: String,
      chart4: String,
      chart5: String,
      text: String? = nil,
      textSecondary: String? = nil,
      textMuted: String? = nil
    ) {
      self.background = background
      self.foreground = foreground
      self.card = card
      self.cardForeground = cardForeground
      self.sheet = sheet
      self.sheetForeground = sheetForeground
      self.primary = primary
      self.primaryForeground = primaryForeground
      self.secondary = secondary
      self.secondaryForeground = secondaryForeground
      self.muted = muted
      self.mutedForeground = mutedForeground
      self.accent = accent
      self.accentForeground = accentForeground
      self.destructive = destructive
      self.destructiveForeground = destructiveForeground
      self.border = border
      self.input = input
      self.focus = focus
      self.warning = warning
      self.warningForeground = warningForeground
      self.success = success
      self.successForeground = successForeground
      self.chart1 = chart1
      self.chart2 = chart2
      self.chart3 = chart3
      self.chart4 = chart4
      self.chart5 = chart5
      self.text = text ?? foreground
      self.textSecondary = textSecondary ?? mutedForeground
      self.textMuted = textMuted ?? mutedForeground
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      background = try container.decodeHex(forKey: .background)
      foreground = try container.decodeHex(forKey: .foreground)
      card = try container.decodeHex(forKey: .card)
      cardForeground = try container.decodeHex(forKey: .cardForeground)
      sheet = try container.decodeHex(forKey: .sheet)
      sheetForeground = try container.decodeHex(forKey: .sheetForeground)
      primary = try container.decodeHex(forKey: .primary)
      primaryForeground = try container.decodeHex(forKey: .primaryForeground)
      secondary = try container.decodeHex(forKey: .secondary)
      secondaryForeground = try container.decodeHex(forKey: .secondaryForeground)
      muted = try container.decodeHex(forKey: .muted)
      mutedForeground = try container.decodeHex(forKey: .mutedForeground)
      accent = try container.decodeHex(forKey: .accent)
      accentForeground = try container.decodeHex(forKey: .accentForeground)
      destructive = try container.decodeHex(forKey: .destructive)
      destructiveForeground = try container.decodeHex(forKey: .destructiveForeground)
      border = try container.decodeHex(forKey: .border)
      input = try container.decodeHex(forKey: .input)
      focus = try container.decodeHex(forKey: .focus)
      warning = try container.decodeHex(forKey: .warning)
      warningForeground = try container.decodeHex(forKey: .warningForeground)
      success = try container.decodeHex(forKey: .success)
      successForeground = try container.decodeHex(forKey: .successForeground)
      chart1 = try container.decodeHex(forKey: .chart1)
      chart2 = try container.decodeHex(forKey: .chart2)
      chart3 = try container.decodeHex(forKey: .chart3)
      chart4 = try container.decodeHex(forKey: .chart4)
      chart5 = try container.decodeHex(forKey: .chart5)
      // Text hierarchy — fallback to foreground/mutedForeground for backward compat
      text = try container.decodeHexIfPresent(forKey: .text) ?? foreground
      textSecondary = try container.decodeHexIfPresent(forKey: .textSecondary) ?? mutedForeground
      textMuted = try container.decodeHexIfPresent(forKey: .textMuted) ?? mutedForeground
    }
  }
}

// MARK: - Hex Validation Helpers

private extension KeyedDecodingContainer {
  func decodeHex(forKey key: Key) throws -> String {
    let value = try decode(String.self, forKey: key)
    guard value.isSupportedHexColor else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: self,
        debugDescription: "Expected #RRGGBB, RRGGBB, #AARRGGBB, or AARRGGBB"
      )
    }
    return value
  }

  func decodeHexIfPresent(forKey key: Key) throws -> String? {
    guard let value = try decodeIfPresent(String.self, forKey: key) else {
      return nil
    }
    guard value.isSupportedHexColor else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: self,
        debugDescription: "Expected #RRGGBB, RRGGBB, #AARRGGBB, or AARRGGBB"
      )
    }
    return value
  }
}

private extension String {
  var isSupportedHexColor: Bool {
    let digits = hasPrefix("#") ? dropFirst() : self[...]
    return (digits.count == 6 || digits.count == 8)
      && digits.allSatisfy { $0.isASCII && $0.isHexDigit }
  }
}
