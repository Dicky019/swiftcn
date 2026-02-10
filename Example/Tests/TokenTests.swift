//
//  TokenTests.swift
//  Tests
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Testing
@testable import Example

@Suite("Design Token Tests")
struct TokenTests {
  
  // MARK: - ThemeRadius
  
  @Test("ThemeRadius has correct default values")
  func themeRadiusDefaults() {
    let radius = ThemeRadius.default
    #expect(radius.none == 0)
    #expect(radius.sm == 4)
    #expect(radius.md == 8)
    #expect(radius.lg == 12)
    #expect(radius.xl == 16)
    #expect(radius.xxl == 24)
    #expect(radius.full == 9999)
  }
  
  // MARK: - ThemeSpacing
  
  @Test("ThemeSpacing follows 4pt grid")
  func themeSpacingFollowsGrid() {
    let spacing = ThemeSpacing.default
    #expect(spacing.none == 0)
    #expect(spacing.xs == 4)
    #expect(spacing.sm == 8)
    #expect(spacing.md == 16)
    #expect(spacing.lg == 24)
    #expect(spacing.xl == 32)
    #expect(spacing.xxl == 48)
    #expect(spacing.xxxl == 64)
  }
  
  // MARK: - ThemeShadows
  
  @Test("ThemeShadows has correct default values")
  func themeShadowsDefaults() {
    let shadows = ThemeShadows.default
    #expect(shadows.sm.radius == 2)
    #expect(shadows.md.radius == 4)
    #expect(shadows.lg.radius == 8)
  }
  
  // MARK: - ThemeMotion
  
  @Test("ThemeMotion has correct durations")
  func themeMotionDurations() {
    let motion = ThemeMotion.default
    #expect(motion.fast == 0.15)
    #expect(motion.normal == 0.3)
    #expect(motion.slow == 0.5)
  }
  
  // MARK: - ThemeBorderWidth
  
  @Test("ThemeBorderWidth has correct default values")
  func themeBorderWidthDefaults() {
    let borderWidth = ThemeBorderWidth.default
    #expect(borderWidth.none == 0)
    #expect(borderWidth.thin == 0.5)
    #expect(borderWidth.regular == 1)
    #expect(borderWidth.thick == 2)
  }
  
  // MARK: - ThemeOpacity
  
  @Test("ThemeOpacity has correct default values")
  func themeOpacityDefaults() {
    let opacity = ThemeOpacity.default
    #expect(opacity.disabled == 0.5)
    #expect(opacity.overlay == 0.8)
    #expect(opacity.hover == 0.9)
    #expect(opacity.muted == 0.6)
  }
}
