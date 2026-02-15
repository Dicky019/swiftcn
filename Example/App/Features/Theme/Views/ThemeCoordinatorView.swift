//
//  ThemeCoordinatorView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeCoordinatorView: View {
  @Environment(AppNavController.self) private var appNav

  var body: some View {
    @Bindable var navController = appNav.theme

    NavigationStack(path: $navController.stack) {
      ThemeExplorerView()
        .navigationDestination(for: BaseDestination.self) { destination in
          AnyView(destination.getScreen())
        }
    }
    .environment(appNav.theme)
  }
}

#Preview {
  ThemeCoordinatorView()
    .environment(AppNavController())
    .environment(ThemeProvider())
}
