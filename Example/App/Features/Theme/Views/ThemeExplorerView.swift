//
//  ThemeExplorerView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeExplorerView: View {
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
        Text("Explore design tokens and theme configuration")
          .font(.subheadline)
          .foregroundStyle(theme.textMuted)
          .padding(.horizontal, theme.spacing.md)

        // Explore section
        HStack(spacing: theme.spacing.md) {
          NavigationLink {
            TokenShowcaseView()
          } label: {
            CNCard(variant: .elevated) {
              VStack(spacing: theme.spacing.sm) {
                Image(systemName: "paintpalette")
                  .font(.title2)
                  .foregroundStyle(theme.primary)
                Text("Design Tokens")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundStyle(theme.text)
              }
              .frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.plain)

          NavigationLink {
            ThemeActionsView()
          } label: {
            CNCard(variant: .elevated) {
              VStack(spacing: theme.spacing.sm) {
                Image(systemName: "wand.and.stars")
                  .font(.title2)
                  .foregroundStyle(theme.primary)
                Text("Theme Actions")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .foregroundStyle(theme.text)
              }
              .frame(maxWidth: .infinity)
            }
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal, theme.spacing.md)

        // Quick Reference header
        Text("Quick Reference")
          .font(.headline)
          .foregroundStyle(theme.text)
          .padding(.horizontal, theme.spacing.md)

        // Category grid
        LazyVGrid(columns: columns, spacing: theme.spacing.md) {
          ForEach(TokenCategory.allCases) { category in
            NavigationLink {
              category.destinationView
            } label: {
              CNCard(variant: .outlined) {
                HStack(spacing: theme.spacing.sm) {
                  Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(theme.primary)
                    .frame(width: 28)
                  Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.text)
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.mutedForeground)
                }
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, theme.spacing.md)
      }
      .padding(.vertical, theme.spacing.md)
    }
    .navigationTitle("Theme")
    .background(theme.background)
  }
}

#Preview {
  NavigationStack {
    ThemeExplorerView()
  }
  .environment(ThemeProvider())
}
