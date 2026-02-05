// ComponentGalleryView.swift
// swiftcn Example App

import SwiftUI
import Swiftcn

struct ComponentGalleryView: View {
    @Environment(AppRouter.self) private var router
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
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(.horizontal, theme.spacing.md)

                // Grid
                LazyVGrid(columns: columns, spacing: theme.spacing.md) {
                    ForEach(ComponentInfo.all) { component in
                        Button {
                            router.navigate(to: .detail(component))
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
        .environment(AppRouter())
        .environment(ThemeProvider())
}
