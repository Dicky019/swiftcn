//
//  ThemeModeRow.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ThemeModeRow: View {
  @Environment(\.theme) private var theme
  
  let mode: ColorSchemePreference
  let isSelected: Bool
  let action: () -> Void
  
  private var iconName: String {
    switch mode {
    case .light: "sun.max.fill"
    case .dark: "moon.fill"
    case .system: "circle.lefthalf.filled"
    }
  }
  
  private var displayName: String {
    switch mode {
    case .light: "Light"
    case .dark: "Dark"
    case .system: "System"
    }
  }
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: iconName)
          .font(.title2)
          .foregroundStyle(isSelected ? theme.primary : theme.mutedForeground)
          .frame(width: 32)
        
        Text(displayName)
          .font(.body)
          .foregroundStyle(theme.foreground)
        
        Spacer()
        
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(theme.primary)
        }
      }
      .padding(.vertical, theme.spacing.xs)
    }
    .buttonStyle(.plain)
  }
}
