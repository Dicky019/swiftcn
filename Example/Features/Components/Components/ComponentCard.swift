// ComponentCard.swift
// swiftcn Example App

import SwiftUI
import Swiftcn

struct ComponentCard: View {
    @Environment(\.theme) private var theme

    let component: ComponentInfo
    let isCompact: Bool

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Image(systemName: component.iconName)
                .font(isCompact ? .title2 : .largeTitle)
                .foregroundStyle(theme.primary)
                .frame(height: isCompact ? 32 : 48)

            VStack(spacing: theme.spacing.xs) {
                Text(component.cnName)
                    .font(.headline)
                    .foregroundStyle(theme.foreground)

                Text(component.description)
                    .font(.caption)
                    .foregroundStyle(theme.mutedForeground)
                    .lineLimit(2)
            }

            if component.sduiSupport {
                CNBadge("SDUI", variant: .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(theme.spacing.md)
        .background(theme.card)
        .clipShape(.rect(cornerRadius: theme.radius.lg))
    }
}
