//
//  ButtonShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI
import Swiftcn

struct ButtonShowcase: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Text("Button Variants")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: theme.spacing.sm) {
                CNButton("Default", variant: .default) {}
                CNButton("Destructive", variant: .destructive) {}
                CNButton("Outline", variant: .outline) {}
                CNButton("Secondary", variant: .secondary) {}
                CNButton("Ghost", variant: .ghost) {}
                CNButton("Link", variant: .link) {}
            }

            Text("Sizes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, theme.spacing.md)

            HStack(spacing: theme.spacing.sm) {
                CNButton("Small", size: .sm) {}
                CNButton("Medium", size: .md) {}
                CNButton("Large", size: .lg) {}
            }

            Text("States")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, theme.spacing.md)

            HStack(spacing: theme.spacing.sm) {
                CNButton("Enabled") {}
                CNButton("Disabled") {}
                    .disabled(true)
            }
        }
    }
}
