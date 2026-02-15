//
//  ComponentsCoordinatorView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentsCoordinatorView: View {
  @Environment(AppNavController.self) private var appNav

  var body: some View {
    @Bindable var navController = appNav.components

    NavigationStack(path: $navController.stack) {
      ComponentGalleryView()
        .navigationDestination(for: BaseDestination.self) { destination in
          AnyView(destination.getScreen())
        }
    }
    .environment(appNav.components)
  }
}
