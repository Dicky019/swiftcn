//
//  ThemeExplorerView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeExplorerView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    List {
      Section("Explore") {
        NavigationLink {
          TokenShowcaseView()
        } label: {
          Label("Design Tokens", systemImage: "paintpalette")
        }

        NavigationLink {
          ThemeActionsView()
        } label: {
          Label("Theme Actions", systemImage: "wand.and.stars")
        }
      }

      Section("Quick Reference") {
        ForEach(TokenCategory.allCases) { category in
          NavigationLink {
            category.destinationView
          } label: {
            HStack {
              Image(systemName: category.icon)
                .frame(width: 24)
                .foregroundStyle(theme.primary)
              Text(category.rawValue)
              Spacer()
            }
          }
        }
      }
    }
    .navigationTitle("Theme")
  }
}

#Preview {
  NavigationStack {
    ThemeExplorerView()
  }
  .environment(ThemeProvider())
}
