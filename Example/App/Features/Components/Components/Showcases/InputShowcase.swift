//
//  InputShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct InputShowcase: View {
    @Environment(\.theme) private var theme

    @State private var text = ""
    @State private var email = "john@example.com"
    @State private var errorText = ""

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Input States")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            CNInput("Enter your name", text: $text, label: "Name")

            CNInput("Enter email", text: $email, label: "Email")

            CNInput("Password", text: $errorText, label: "Password", isError: true, errorMessage: "Password is required")

            CNInput("Disabled input", text: .constant("Cannot edit"))
                .disabled(true)
        }
    }
}
