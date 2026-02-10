//
//  ThemeActionsView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeActionsView: View {
  @Environment(\.theme) private var theme
  @Environment(\.horizontalSizeClass) private var sizeClass
  @Environment(ThemeProvider.self) private var themeProvider
  @StateObject private var themeLoader = ExampleThemeLoader.shared
  @State private var customThemeJSON = ""
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var selectedTheme: ExampleTheme?
  @State private var showApplyConfirmation = false

  private var themeColumns: [GridItem] {
    sizeClass == .compact
    ? [GridItem(.flexible()), GridItem(.flexible())]
    : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.lg) {
        // Header description
        Text("Configure appearance and apply custom themes")
          .font(.subheadline)
          .foregroundStyle(theme.textMuted)

        // MARK: - Current State + Quick Actions
        currentStateSection
        quickActionsSection

        // MARK: - Example Themes
        themeGallerySection

        // MARK: - Custom Theme JSON
        customThemeSection
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.md)
    }
    .navigationTitle("Theme Actions")
    .background(theme.background)
    .onAppear {
      themeLoader.loadIfNeeded()
      if customThemeJSON.isEmpty {
        loadCurrentThemeJSON()
      }
    }
    .alert("Error", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
    .alert(
      "Apply \(selectedTheme?.rawValue ?? "") Theme?",
      isPresented: $showApplyConfirmation
    ) {
      Button("Apply") {
        if let theme = selectedTheme {
          let json = themeLoader.json(for: theme)
          customThemeJSON = json
          applyCustomTheme()
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Do you want to apply the \(selectedTheme?.rawValue ?? "") theme?")
    }
  }

  // MARK: - Current State

  private var currentStateSection: some View {
    CNCard(variant: .elevated) {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: themeProvider.effectiveColorScheme == .dark ? "moon.fill" : "sun.max.fill")
          .font(.title2)
          .foregroundStyle(theme.primary)
          .frame(width: 32)

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("Current Appearance")
            .font(.subheadline)
            .foregroundStyle(theme.textMuted)
          Text(themeProvider.effectiveColorScheme == .dark ? "Dark Mode" : "Light Mode")
            .font(.headline)
            .foregroundStyle(theme.text)
        }

        Spacer()

        CNBadge(themeProvider.colorSchemePreference.rawValue, variant: .secondary)
      }
    }
  }

  // MARK: - Quick Actions

  private var quickActionsSection: some View {
    HStack(spacing: theme.spacing.md) {
      Button {
        themeProvider.toggleColorScheme()
      } label: {
        CNCard(variant: .outlined) {
          VStack(spacing: theme.spacing.sm) {
            Image(systemName: themeProvider.effectiveColorScheme == .dark ? "sun.max.fill" : "moon.fill")
              .font(.title2)
              .foregroundStyle(theme.primary)
            Text("Toggle Scheme")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(theme.text)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.plain)

      Button {
        themeProvider.resetToDefault()
        loadCurrentThemeJSON()
      } label: {
        CNCard(variant: .outlined) {
          VStack(spacing: theme.spacing.sm) {
            Image(systemName: "arrow.counterclockwise")
              .font(.title2)
              .foregroundStyle(theme.primary)
            Text("Reset Default")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(theme.text)
          }
          .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Theme Gallery

  private var themeGallerySection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("Example Themes")
        .font(.headline)
        .foregroundStyle(theme.text)
      Text("Tap a theme to preview and apply")
        .font(.caption)
        .foregroundStyle(theme.textMuted)

      LazyVGrid(columns: themeColumns, spacing: theme.spacing.md) {
        ForEach(ExampleTheme.allCases) { exampleTheme in
          Button {
            selectedTheme = exampleTheme
            showApplyConfirmation = true
          } label: {
            CNCard(variant: .outlined) {
              VStack(spacing: theme.spacing.sm) {
                Circle()
                  .fill(exampleTheme.previewColor)
                  .frame(width: 40, height: 40)
                  .overlay(
                    Circle()
                      .stroke(theme.border, lineWidth: theme.borderWidth.regular)
                  )
                Text(exampleTheme.rawValue)
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundStyle(theme.text)
              }
              .frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  // MARK: - Custom Theme JSON

  private var customThemeSection: some View {
    CNCard(variant: .outlined) {
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        HStack {
          Image(systemName: "curlybraces")
            .foregroundStyle(theme.primary)
          Text("Custom Theme JSON")
            .font(.headline)
            .foregroundStyle(theme.text)
        }
        Text("Paste or edit a full theme JSON to apply")
          .font(.caption)
          .foregroundStyle(theme.textMuted)
        Divider()

        TextEditor(text: $customThemeJSON)
          .frame(minHeight: 200)
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(theme.text)
          .scrollContentBackground(.hidden)
          .padding(theme.spacing.sm)
          .background(theme.background)
          .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
          .overlay(
            RoundedRectangle(cornerRadius: theme.radius.md)
              .stroke(theme.border, lineWidth: theme.borderWidth.regular)
          )

        CNButton("Apply Theme", variant: .default) {
          applyCustomTheme()
        }
        .disabled(customThemeJSON.isEmpty)
        .frame(maxWidth: .infinity)
      }
    }
  }

  // MARK: - Private Methods

  private func loadCurrentThemeJSON() {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    if let data = try? encoder.encode(themeProvider.currentTheme),
       let json = String(data: data, encoding: .utf8) {
      customThemeJSON = json
    }
  }

  private func applyCustomTheme() {
    do {
      try themeProvider.apply(jsonString: customThemeJSON)
    } catch {
      errorMessage = error.localizedDescription
      showError = true
    }
  }
}

#Preview {
  NavigationStack {
    ThemeActionsView()
  }
  .environment(ThemeProvider())
}
