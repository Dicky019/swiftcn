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
    HStack(spacing: theme.spacing.md) {
      Image(systemName: iconName)
        .font(.title2)
        .foregroundStyle(isSelected ? theme.primary : theme.mutedForeground)
        .frame(width: 32)
        .animation(.easeInOut(duration: theme.motion.fast), value: isSelected)

      Text(displayName)
        .font(.body)
        .foregroundStyle(theme.text)

      Spacer()

      Image(systemName: "checkmark")
        .foregroundStyle(theme.primary)
        .opacity(isSelected ? 1 : 0)
        .animation(.easeInOut(duration: theme.motion.fast), value: isSelected)
    }
    .padding(.vertical, theme.spacing.sm)
    .contentShape(Rectangle())
    .onTapGesture {
      action()
    }
  }
}
