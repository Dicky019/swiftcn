//
//  ThemeActionsView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeActionsView: View {
  @Environment(ThemeProvider.self) private var themeProvider
  @StateObject private var themeLoader = ExampleThemeLoader.shared
  @State private var customThemeJSON = ""
  @State private var showError = false
  @State private var errorMessage = ""
  @State private var selectedTheme: ExampleTheme?
  @State private var showApplyConfirmation = false

  var body: some View {
    List {
      Section("Quick Actions") {
        Button("Toggle Color Scheme") {
          themeProvider.toggleColorScheme()
        }

        Button("Reset to Default Theme") {
          themeProvider.resetToDefault()
          loadCurrentThemeJSON()
        }
      }

      Section {
        ForEach(ExampleTheme.allCases) { theme in
          Button {
            selectedTheme = theme
            showApplyConfirmation = true
          } label: {
            HStack(spacing: 12) {
              Circle()
                .fill(theme.previewColor)
                .frame(width: 24, height: 24)
              Text(theme.rawValue)
                .foregroundStyle(.primary)
            }
          }
        }
      } header: {
        Text("Example Themes")
      } footer: {
        Text("Tap a theme to apply it.")
      }

      Section {
        TextEditor(text: $customThemeJSON)
          .frame(minHeight: 200)
          .font(.system(.caption, design: .monospaced))

        Button("Apply Theme") {
          applyCustomTheme()
        }
        .buttonStyle(.borderedProminent)
        .disabled(customThemeJSON.isEmpty)
        .frame(maxWidth: .infinity)
      } header: {
        Text("Custom Theme JSON")
      }

      Section("Current State") {
        LabeledContent("Preference", value: themeProvider.colorSchemePreference.rawValue)
        LabeledContent("Effective", value: themeProvider.effectiveColorScheme == .dark ? "Dark" : "Light")
      }
    }
    .navigationTitle("Theme Actions")
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
