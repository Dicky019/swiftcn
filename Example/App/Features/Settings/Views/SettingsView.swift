//
//  SettingsView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SettingsView: View {
  @Environment(ThemeProvider.self) private var themeProvider
  @State private var viewModel: SettingsViewModel?
  
  var body: some View {
    NavigationStack {
      List {
        if let viewModel {
          // MARK: - Appearance Section
          Section {
            ForEach(viewModel.allModes, id: \.self) { mode in
              ThemeModeRow(
                mode: mode,
                isSelected: viewModel.isSelected(mode),
                action: {
                  viewModel.selectMode(mode)
                }
              )
            }
          } header: {
            Text("Appearance")
          } footer: {
            Text("Choose how the app appears. System mode follows your device settings.")
          }
          
          // MARK: - About Section
          Section {
            InfoRow(label: "Version", value: viewModel.appVersion)
            InfoRow(label: "Build", value: viewModel.buildNumber)
          } header: {
            Text("About")
          }
        }
      }
      .navigationTitle("Settings")
      .onAppear {
        if viewModel == nil {
          viewModel = SettingsViewModel(themeProvider: themeProvider)
        }
      }
    }
  }
}

#Preview {
  SettingsView()
    .environment(ThemeProvider())
}
