// App.swift
// swiftcn Example App

import SwiftUI
import Swiftcn

@main
struct SwiftcnApp: App {
    @State private var themeProvider = ThemeProvider()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(themeProvider)
                .environment(\.theme, themeProvider.resolvedTheme)
                .preferredColorScheme(themeProvider.resolvedColorScheme)
        }
    }
}
