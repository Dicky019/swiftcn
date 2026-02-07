//
//  CNCard.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A container with rounded corners, optional shadow, and flexible content.
///
/// Usage:
/// ```swift
/// CNCard {
///     Text("Card content")
/// }
///
/// CNCard(variant: .outlined) {
///     VStack { ... }
/// }
/// ```
public struct CNCard<Content: View>: View {

    // MARK: - Variants

    public enum Variant: String, Codable, CaseIterable, Sendable {
        case elevated   // Shadow + background
        case outlined   // Border + background
        case filled     // Just background
    }

    // MARK: - Properties

    private let variant: Variant
    private let content: Content

    @Environment(\.theme) private var theme

    // MARK: - Initializers

    public init(
        variant: Variant = .elevated,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.content = content()
    }

    // MARK: - Body

    public var body: some View {
        content
            .padding(theme.spacing.lg)
            .background(theme.card, in: shape)
            .overlay {
                if variant == .outlined {
                    shape.stroke(theme.border, lineWidth: theme.borderWidth.regular)
                }
            }
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                y: shadowY
            )
    }

    // MARK: - Computed Properties

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.radius.lg)
    }

    private var shadowColor: Color {
        variant == .elevated ? .black.opacity(theme.shadows.md.opacity) : .clear
    }

    private var shadowRadius: CGFloat {
        variant == .elevated ? theme.shadows.md.radius : 0
    }

    private var shadowY: CGFloat {
        variant == .elevated ? theme.shadows.md.y : 0
    }
}

// MARK: - Previews

#Preview("CNCard Variants") {
    VStack(spacing: 20) {
        CNCard(variant: .elevated) {
            Text("Elevated Card")
        }

        CNCard(variant: .outlined) {
            Text("Outlined Card")
        }

        CNCard(variant: .filled) {
            Text("Filled Card")
        }
    }
    .padding()
}
