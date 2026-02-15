//
//  MainTabView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct MainTabView: View {
  @Environment(\.theme) private var theme
  @State private var appNav = AppNavController()

  var body: some View {
    TabView(selection: $appNav.selectedTab) {
      ComponentsCoordinatorView()
        .tabItem {
          Label("Components", systemImage: "square.grid.2x2")
        }
        .tag(AppTab.components)

      SDUIPlaygroundView()
        .tabItem {
          Label("SDUI", systemImage: "server.rack")
        }
        .tag(AppTab.sdui)

      ThemeCoordinatorView()
        .tabItem {
          Label("Theme", systemImage: "paintpalette")
        }
        .tag(AppTab.theme)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
        .tag(AppTab.settings)
    }
    .tint(theme.primary)
    .environment(appNav)
  }
}

#Preview {
  MainTabView()
    .environment(ThemeProvider())
}
