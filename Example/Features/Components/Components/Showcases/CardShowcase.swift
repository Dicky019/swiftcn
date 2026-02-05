//
//  CardShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI
import Swiftcn

struct CardShowcase: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Card Variants")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            CNCard(variant: .elevated) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Elevated Card")
                        .font(.headline)
                    Text("This card has a shadow for depth.")
                        .font(.body)
                        .foregroundStyle(theme.mutedForeground)
                }
            }

            CNCard(variant: .outlined) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Outlined Card")
                        .font(.headline)
                    Text("This card has a border instead of shadow.")
                        .font(.body)
                        .foregroundStyle(theme.mutedForeground)
                }
            }

            CNCard(variant: .filled) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Filled Card")
                        .font(.headline)
                    Text("This card has just a background color.")
                        .font(.body)
                        .foregroundStyle(theme.mutedForeground)
                }
            }
        }
    }
}
