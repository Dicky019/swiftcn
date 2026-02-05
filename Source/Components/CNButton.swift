//
//  CNButton.swift
//  Source/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A customizable button with multiple size and variant options.
///
/// Usage:
/// ```swift
/// CNButton("Click me") {
///     print("Button tapped")
/// }
///
/// CNButton("Delete", variant: .destructive) {
///     deleteItem()
/// }
/// ```
public struct CNButton: View {

    // MARK: - Variants

    public enum Size: String, Codable, CaseIterable, Sendable {
        case sm
        case md
        case lg
    }

    public enum Variant: String, Codable, CaseIterable, Sendable {
        case `default`
        case destructive
        case outline
        case secondary
        case ghost
        case link
    }

    // MARK: - Properties

    private let label: String
    private let size: Size
    private let variant: Variant
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.theme) private var theme

    // MARK: - Initializers

    public init(
        _ label: String,
        size: Size = .md,
        variant: Variant = .default,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.size = size
        self.variant = variant
        self.action = action
    }

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .fontWeight(fontWeight)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(minWidth: minWidth)
        }
        .background(backgroundColor, in: .rect(cornerRadius: cornerRadius))
        .overlay {
            if variant == .outline {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: theme.borderWidth.regular)
            }
        }
        .opacity(isEnabled ? 1.0 : theme.opacity.disabled)
        .accessibilityLabel(label)
    }

    // MARK: - Size Properties

    private var font: Font {
        switch size {
        case .sm: .footnote
        case .md: .body
        case .lg: .headline
        }
    }

    private var fontWeight: Font.Weight {
        .medium
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: theme.spacing.sm
        case .md: theme.spacing.md
        case .lg: theme.spacing.xl
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .sm: theme.spacing.xs + 2
        case .md: theme.spacing.sm + 2
        case .lg: theme.spacing.md - 2
        }
    }

    private var minWidth: CGFloat {
        switch size {
        case .sm: 60
        case .md: 80
        case .lg: 100
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .sm: theme.radius.sm
        case .md: theme.radius.md
        case .lg: theme.radius.lg
        }
    }

    // MARK: - Variant Properties

    private var backgroundColor: Color {
        switch variant {
        case .default: theme.primary
        case .destructive: theme.destructive
        case .secondary: theme.secondary
        case .ghost, .outline, .link: .clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .default: theme.primaryForeground
        case .destructive: theme.destructiveForeground
        case .secondary: theme.secondaryForeground
        case .ghost, .outline: theme.foreground
        case .link: theme.primary
        }
    }

    private var borderColor: Color {
        theme.border
    }
}

// MARK: - Previews

#Preview("CNButton Sizes") {
    VStack(spacing: 16) {
        CNButton("Small", size: .sm) {}
        CNButton("Medium", size: .md) {}
        CNButton("Large", size: .lg) {}
    }
    .padding()
}

#Preview("CNButton Variants") {
    VStack(spacing: 16) {
        CNButton("Default", variant: .default) {}
        CNButton("Destructive", variant: .destructive) {}
        CNButton("Outline", variant: .outline) {}
        CNButton("Secondary", variant: .secondary) {}
        CNButton("Ghost", variant: .ghost) {}
        CNButton("Link", variant: .link) {}
    }
    .padding()
}

#Preview("CNButton Disabled") {
    VStack(spacing: 16) {
        CNButton("Enabled") {}
        CNButton("Disabled") {}
            .disabled(true)
    }
    .padding()
}
