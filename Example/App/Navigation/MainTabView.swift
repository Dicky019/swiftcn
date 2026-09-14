//
//  MainTabView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

private enum Tab: Hashable {
  case components
  case sdui
  case theme
  case settings
}

struct MainTabView: View {
  @Environment(\.theme) private var theme
  @State private var router = Router<ComponentRoute>()
  @State private var selectedTab: Tab = .components

  var body: some View {
    TabView(selection: $selectedTab) {
      ComponentsCoordinatorView()
        .tabItem {
          Label("Components", systemImage: "square.grid.2x2")
        }
        .tag(Tab.components)

      SDUIPlaygroundView()
        .tabItem {
          Label("SDUI", systemImage: "server.rack")
        }
        .tag(Tab.sdui)

      ThemeCoordinatorView()
        .tabItem {
          Label("Theme", systemImage: "paintpalette")
        }
        .tag(Tab.theme)

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
        .tag(Tab.settings)
    }
    .tint(theme.primary)
    .environment(router)
  }
}

#Preview {
  MainTabView()
    .environment(ThemeProvider())
}
