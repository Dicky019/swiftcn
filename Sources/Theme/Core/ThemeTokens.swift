//
//  ThemeTokens.swift
//  Sources/Theme/Core
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - Radius Tokens

public struct ThemeRadius: Codable, Sendable, Equatable {
  public let none: CGFloat
  public let sm: CGFloat
  public let md: CGFloat
  public let lg: CGFloat
  public let xl: CGFloat
  public let xxl: CGFloat
  public let full: CGFloat

  public init(
    none: CGFloat = 0,
    sm: CGFloat = 4,
    md: CGFloat = 8,
    lg: CGFloat = 12,
    xl: CGFloat = 16,
    xxl: CGFloat = 24,
    full: CGFloat = 9999
  ) {
    self.none = none
    self.sm = sm
    self.md = md
    self.lg = lg
    self.xl = xl
    self.xxl = xxl
    self.full = full
  }

  public static let `default` = ThemeRadius()
}

// MARK: - Spacing Tokens

public struct ThemeSpacing: Codable, Sendable, Equatable {
  public let none: CGFloat
  public let xs: CGFloat
  public let sm: CGFloat
  public let md: CGFloat
  public let lg: CGFloat
  public let xl: CGFloat
  public let xxl: CGFloat
  public let xxxl: CGFloat

  public init(
    none: CGFloat = 0,
    xs: CGFloat = 4,
    sm: CGFloat = 8,
    md: CGFloat = 16,
    lg: CGFloat = 24,
    xl: CGFloat = 32,
    xxl: CGFloat = 48,
    xxxl: CGFloat = 64
  ) {
    self.none = none
    self.xs = xs
    self.sm = sm
    self.md = md
    self.lg = lg
    self.xl = xl
    self.xxl = xxl
    self.xxxl = xxxl
  }

  public static let `default` = ThemeSpacing()
}

// MARK: - Shadow Tokens

public struct ThemeShadow: Codable, Sendable, Equatable {
  public let radius: CGFloat
  public let y: CGFloat
  public let opacity: Double

  public init(radius: CGFloat, y: CGFloat, opacity: Double) {
    self.radius = radius
    self.y = y
    self.opacity = opacity
  }
}

public struct ThemeShadows: Codable, Sendable, Equatable {
  public let none: ThemeShadow
  public let sm: ThemeShadow
  public let md: ThemeShadow
  public let lg: ThemeShadow
  public let xl: ThemeShadow

  public init(
    none: ThemeShadow = ThemeShadow(radius: 0, y: 0, opacity: 0),
    sm: ThemeShadow = ThemeShadow(radius: 2, y: 1, opacity: 0.05),
    md: ThemeShadow = ThemeShadow(radius: 4, y: 2, opacity: 0.1),
    lg: ThemeShadow = ThemeShadow(radius: 8, y: 4, opacity: 0.15),
    xl: ThemeShadow = ThemeShadow(radius: 16, y: 8, opacity: 0.2)
  ) {
    self.none = none
    self.sm = sm
    self.md = md
    self.lg = lg
    self.xl = xl
  }

  public static let `default` = ThemeShadows()
}

// MARK: - Motion Tokens

public struct ThemeMotion: Codable, Sendable, Equatable {
  public let fast: Double
  public let normal: Double
  public let slow: Double

  public init(
    fast: Double = 0.15,
    normal: Double = 0.3,
    slow: Double = 0.5
  ) {
    self.fast = fast
    self.normal = normal
    self.slow = slow
  }

  public static let `default` = ThemeMotion()
}

// MARK: - Border Width Tokens

public struct ThemeBorderWidth: Codable, Sendable, Equatable {
  public let none: CGFloat
  public let thin: CGFloat
  public let regular: CGFloat
  public let thick: CGFloat

  enum CodingKeys: String, CodingKey {
    case none, thin, regular = "default", thick
  }

  public init(
    none: CGFloat = 0,
    thin: CGFloat = 0.5,
    regular: CGFloat = 1,
    thick: CGFloat = 2
  ) {
    self.none = none
    self.thin = thin
    self.regular = regular
    self.thick = thick
  }

  public static let `default` = ThemeBorderWidth()
}

// MARK: - Opacity Tokens

public struct ThemeOpacity: Codable, Sendable, Equatable {
  public let disabled: Double
  public let overlay: Double
  public let hover: Double
  public let muted: Double

  public init(
    disabled: Double = 0.5,
    overlay: Double = 0.8,
    hover: Double = 0.9,
    muted: Double = 0.6
  ) {
    self.disabled = disabled
    self.overlay = overlay
    self.hover = hover
    self.muted = muted
  }

  public static let `default` = ThemeOpacity()
}
