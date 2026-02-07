// MainTabView.swift
// swiftcn Example App

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
