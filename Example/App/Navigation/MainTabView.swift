//
//  MainTabView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct MainTabView: View {
  @State private var router = AppRouter()
  
  var body: some View {
    TabView {
      ComponentsCoordinatorView()
        .tabItem {
          Label("Components", systemImage: "square.grid.2x2")
        }

      SDUIPlaygroundView()
        .tabItem {
          Label("SDUI", systemImage: "server.rack")
        }

      ThemeCoordinatorView()
        .tabItem {
          Label("Theme", systemImage: "paintpalette")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
    }
    .environment(router)
  }
}

#Preview {
  MainTabView()
    .environment(ThemeProvider())
}
