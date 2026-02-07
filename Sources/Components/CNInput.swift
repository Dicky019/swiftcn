//
//  CNInput.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A text input field with label, placeholder, and error state support.
///
/// Usage:
/// ```swift
/// @State private var email = ""
///
/// CNInput("Email", text: $email, label: "Email Address")
///
/// CNInput("Password", text: $password, isError: true, errorMessage: "Required")
/// ```
public struct CNInput: View {

    // MARK: - Properties

    private let placeholder: String
    @Binding private var text: String
    private let label: String?
    private let isError: Bool
    private let errorMessage: String?

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.theme) private var theme

    // MARK: - Initializers

    public init(
        _ placeholder: String,
        text: Binding<String>,
        label: String? = nil,
        isError: Bool = false,
        errorMessage: String? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.label = label
        self.isError = isError
        self.errorMessage = errorMessage
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let label {
                Text(label)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(labelColor)
            }

            TextField(placeholder, text: $text)
                .font(.body)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(theme.input, in: shape)
                .overlay {
                    shape.stroke(borderColor, lineWidth: isFocused ? 2 : theme.borderWidth.regular)
                }
                .focused($isFocused)

            if let errorMessage, isError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(theme.destructive)
            }
        }
        .opacity(isEnabled ? 1.0 : theme.opacity.disabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label ?? placeholder)
        .accessibilityValue(text)
    }

    // MARK: - Computed Properties

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.radius.md)
    }

    private var labelColor: Color {
        isError ? theme.destructive : theme.mutedForeground
    }

    private var borderColor: Color {
        if isError {
            return theme.destructive
        } else if isFocused {
            return theme.focus
        } else {
            return theme.border
        }
    }
}

// MARK: - Previews

#Preview("CNInput States") {
    VStack(spacing: 20) {
        CNInput("Enter name", text: .constant(""), label: "Name")
        CNInput("Enter email", text: .constant("john@example.com"), label: "Email")
        CNInput("Enter password", text: .constant(""), label: "Password", isError: true, errorMessage: "Password is required")
    }
    .padding()
}
