//
//  SettingsView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.theme) private var theme
  @Environment(ThemeProvider.self) private var themeProvider
  @Environment(AppNavController.self) private var appNav
  @State private var viewModel: SettingsViewModel?

  var body: some View {
    @Bindable var navController = appNav.settings

    NavigationStack(path: $navController.stack) {
      ScrollView {
        if let viewModel {
          VStack(spacing: theme.spacing.lg) {
            // MARK: - Appearance Section
            CNCard(variant: .outlined) {
              VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Appearance")
                  .font(.headline)
                  .foregroundStyle(theme.text)
                Divider()

                ForEach(viewModel.allModes, id: \.self) { mode in
                  ThemeModeRow(
                    mode: mode,
                    isSelected: viewModel.isSelected(mode),
                    action: {
                      viewModel.selectMode(mode)
                    }
                  )
                }

                Text("Choose how the app appears. System mode follows your device settings.")
                  .font(.caption)
                  .foregroundStyle(theme.textMuted)
              }
            }

            // MARK: - About Section
            CNCard(variant: .outlined) {
              VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("About")
                  .font(.headline)
                  .foregroundStyle(theme.text)
                Divider()
                InfoRow(label: "Version", value: viewModel.appVersion)
                InfoRow(label: "Build", value: viewModel.buildNumber)
              }
            }
          }
          .padding(theme.spacing.md)
        }
      }
      .navigationTitle("Settings")
      .background(theme.background)
      .navigationDestination(for: BaseDestination.self) { destination in
        AnyView(destination.getScreen())
      }
      .onAppear {
        if viewModel == nil {
          viewModel = SettingsViewModel(themeProvider: themeProvider)
        }
      }
    }
    .environment(appNav.settings)
  }
}

#Preview {
  SettingsView()
    .environment(AppNavController())
    .environment(ThemeProvider())
}
