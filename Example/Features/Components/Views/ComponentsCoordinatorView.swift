//
//  ComponentsCoordinatorView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentsCoordinatorView: View {
  @Environment(AppRouter.self) private var router

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.componentsPath) {
      ComponentGalleryView()
        .navigationDestination(for: ComponentRoute.self) { route in
          destinationView(for: route)
        }
    }
  }

  @ViewBuilder
  private func destinationView(for route: ComponentRoute) -> some View {
    switch route {
    case .detail(let component):
      ComponentDetailView(component: component)
    }
  }
}
