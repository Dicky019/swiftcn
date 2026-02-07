//
//  CNBadge.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A small status indicator or label badge.
///
/// Usage:
/// ```swift
/// CNBadge("New")
/// CNBadge("Error", variant: .destructive)
/// ```
public struct CNBadge: View {

    // MARK: - Variants

    public enum Variant: String, Codable, CaseIterable, Sendable {
        case `default`
        case secondary
        case destructive
        case outline
    }

    // MARK: - Properties

    private let label: String
    private let variant: Variant

    @Environment(\.theme) private var theme

    // MARK: - Initializers

    public init(
        _ label: String,
        variant: Variant = .default
    ) {
        self.label = label
        self.variant = variant
    }

    // MARK: - Body

    public var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(backgroundColor, in: .capsule)
            .overlay {
                if variant == .outline {
                    Capsule()
                        .stroke(theme.border, lineWidth: theme.borderWidth.regular)
                }
            }
    }

    // MARK: - Computed Properties

    private var backgroundColor: Color {
        switch variant {
        case .default: theme.primary
        case .secondary: theme.secondary
        case .destructive: theme.destructive
        case .outline: .clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .default: theme.primaryForeground
        case .destructive: theme.destructiveForeground
        case .secondary, .outline: theme.foreground
        }
    }
}

// MARK: - Previews

#Preview("CNBadge Variants") {
    HStack(spacing: 12) {
        CNBadge("Default")
        CNBadge("Secondary", variant: .secondary)
        CNBadge("Destructive", variant: .destructive)
        CNBadge("Outline", variant: .outline)
    }
    .padding()
}
