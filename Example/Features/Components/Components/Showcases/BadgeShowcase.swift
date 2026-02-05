// BadgeShowcase.swift
// swiftcn Example App

import SwiftUI
import Swiftcn

struct BadgeShowcase: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Badge Variants")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: theme.spacing.sm) {
                CNBadge("Default")
                CNBadge("Secondary", variant: .secondary)
                CNBadge("Destructive", variant: .destructive)
                CNBadge("Outline", variant: .outline)
            }

            Text("Use Cases")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, theme.spacing.md)

            HStack(spacing: theme.spacing.sm) {
                CNBadge("New")
                CNBadge("Beta", variant: .secondary)
                CNBadge("Error", variant: .destructive)
                CNBadge("v1.0", variant: .outline)
            }
        }
    }
}
