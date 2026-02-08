//
//  App.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

@main
struct ExampleApp: App {
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
