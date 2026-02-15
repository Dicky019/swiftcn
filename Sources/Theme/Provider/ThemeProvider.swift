//
//  ThemeProvider.swift
//  Sources/Theme/Provider
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI
import OSLog
#if canImport(UIKit)
import UIKit
#endif

private let logger = Logger(subsystem: "com.swiftcn.theme", category: "ThemeProvider")

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
      updateResolvedTheme(animated: true)
    }
  }

  /// System color scheme (tracked for system preference)
  private var systemColorScheme: SwiftUI.ColorScheme = .light

  /// Resolved theme with SwiftUI Colors
  public private(set) var resolvedTheme: ResolvedTheme

  /// Deferred color scheme for .preferredColorScheme() — updates after animation completes
  /// so system chrome (status bar, keyboard) follows without killing the SwiftUI animation
  public private(set) var systemChromeScheme: SwiftUI.ColorScheme?

  /// Tag for identifying transition snapshot views
  private static let snapshotTag = 847291

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
    let preference = ColorSchemePreference(rawValue: savedMode ?? "") ?? .system
    self.colorSchemePreference = preference

    // Resolve based on loaded preference
    // For .system, defaults to light until view appears and updates with actual system scheme
    let isDark = preference == .dark
    self.resolvedTheme = ResolvedTheme.resolve(theme: theme, isDark: isDark)
    self.systemChromeScheme = preference == .system ? nil : (preference == .dark ? .dark : .light)
  }

  // MARK: - Theme Updates

  /// Apply theme from JSON data (SDUI)
  public func apply(_ data: Data) throws {
    do {
      let theme = try JSONDecoder().decode(Theme.self, from: data)
      currentTheme = theme
      updateResolvedTheme(animated: true)
      #if DEBUG
      logger.info("Applied theme from JSON data (\(data.count) bytes)")
      #endif
    } catch {
      #if DEBUG
      logger.error("Failed to decode theme: \(error.localizedDescription, privacy: .public)")
      #endif
      throw ThemeError.decodingFailed(error)
    }
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
    updateResolvedTheme(animated: true)
  }

  /// Update system color scheme (call from view's onChange)
  public func updateSystemColorScheme(_ scheme: SwiftUI.ColorScheme) {
    guard systemColorScheme != scheme else { return }
    systemColorScheme = scheme
    if colorSchemePreference == .system {
      updateResolvedTheme()
    }
  }

  /// Toggle between light and dark based on current effective appearance
  public func toggleColorScheme() {
    switch effectiveColorScheme {
    case .light: colorSchemePreference = .dark
    case .dark: colorSchemePreference = .light
    @unknown default: colorSchemePreference = .light
    }
  }

  // MARK: - Private

  private func updateResolvedTheme(animated: Bool = false) {
    let isDark = effectiveColorScheme == .dark
    let newTheme = ResolvedTheme.resolve(theme: currentTheme, isDark: isDark)

    if animated {
      performSnapshotTransition {
        self.resolvedTheme = newTheme
      }
      #if DEBUG
      logger.debug("Theme updated (animated): colorScheme=\(isDark ? "dark" : "light", privacy: .public)")
      #endif
    } else {
      var transaction = Transaction(animation: nil)
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        self.resolvedTheme = newTheme
        self.systemChromeScheme = self.resolvedColorScheme
        #if DEBUG
        logger.debug("Theme updated: colorScheme=\(isDark ? "dark" : "light", privacy: .public)")
        #endif
      }
    }
  }

  /// Perform theme change with cross-fade snapshot transition (iOS) or instant fallback (macOS)
  private func performSnapshotTransition(change: () -> Void) {
    #if canImport(UIKit)
    guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }),
          let snapshot = window.snapshotView(afterScreenUpdates: false) else {
      change()
      self.systemChromeScheme = self.resolvedColorScheme
      return
    }

    let duration = resolvedTheme.motion.normal

    // Remove any existing snapshot from rapid toggling
    window.viewWithTag(Self.snapshotTag)?.removeFromSuperview()

    snapshot.tag = Self.snapshotTag
    window.addSubview(snapshot)

    // Apply theme change — views update underneath the snapshot
    change()

    // Fade out snapshot to reveal new theme, then update system chrome
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
      snapshot.alpha = 0
    } completion: { _ in
      snapshot.removeFromSuperview()
      // Defer system chrome update until after fade completes
      // so status bar transitions cleanly after the crossfade
      self.systemChromeScheme = self.resolvedColorScheme
    }
    #else
    change()
    self.systemChromeScheme = self.resolvedColorScheme
    #endif
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
