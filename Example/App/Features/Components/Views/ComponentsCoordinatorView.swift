//
//  ComponentsCoordinatorView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentsCoordinatorView: View {
  @Environment(Router<ComponentRoute>.self) private var router
  
  var body: some View {
    @Bindable var router = router
    
    NavigationStack(path: $router.path) {
      ComponentGalleryView()
        .navigationDestination(for: ComponentRoute.self) { route in
          switch route {
          case .detail(let component):
            ComponentDetailView(component: component)
          }
        }
    }
  }
}
