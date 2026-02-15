//
//  ComponentGalleryView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentGalleryView: View {
  @Environment(NavController.self) private var navController
  @Environment(\.theme) private var theme
  @Environment(\.horizontalSizeClass) private var sizeClass
  
  private var columns: [GridItem] {
    sizeClass == .compact
    ? [GridItem(.flexible())]
    : [GridItem(.flexible()), GridItem(.flexible())]
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        // Header
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("Copy-paste ready components")
            .font(.subheadline)
            .foregroundStyle(theme.textMuted)
        }
        .padding(.horizontal, theme.spacing.md)
        
        // Grid
        LazyVGrid(columns: columns, spacing: theme.spacing.md) {
          ForEach(ComponentInfo.all) { component in
            Button {
              navController.navigateTo(Destination.ComponentDetail(info: component))
            } label: {
              ComponentCard(component: component, isCompact: sizeClass == .compact)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, theme.spacing.md)
      }
      .padding(.vertical, theme.spacing.md)
    }
    .navigationTitle("CN Components")
    .background(theme.background)
  }
}

#Preview {
  ComponentsCoordinatorView()
    .environment(ThemeProvider())
}
