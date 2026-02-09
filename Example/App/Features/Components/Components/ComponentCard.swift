//
//  ComponentCard.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentCard: View {
  @Environment(\.theme) private var theme

  let component: ComponentInfo
  let isCompact: Bool

  var body: some View {
    CNCard(variant: .elevated) {
      VStack(spacing: theme.spacing.sm) {
        Image(systemName: component.iconName)
          .font(isCompact ? .title2 : .largeTitle)
          .foregroundStyle(theme.primary)
          .frame(height: isCompact ? 32 : 48)

        VStack(spacing: theme.spacing.xs) {
          Text(component.cnName)
            .font(.headline)
            .foregroundStyle(theme.foreground)

          Text(component.description)
            .font(.caption)
            .foregroundStyle(theme.mutedForeground)
            .lineLimit(2)
        }

        if component.sduiSupport {
          CNBadge("SDUI", variant: .secondary)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }
}
