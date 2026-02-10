//
//  ComponentDetailView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ComponentDetailView: View {
  @Environment(\.theme) private var theme
  
  let component: ComponentInfo
  
  var body: some View {
    ScrollView {
      VStack(spacing: theme.spacing.lg) {
        componentShowcase
        
        // Component Info Card
        CNCard(variant: .outlined) {
          VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
              Text(component.cnName)
                .font(.headline)
                .foregroundStyle(theme.text)
              
              Spacer()
              
              if component.sduiSupport {
                CNBadge("SDUI Ready", variant: .default)
              }
            }
            
            Text(component.description)
              .font(.body)
              .foregroundStyle(theme.textMuted)
            
            Divider()
            
            // Usage hint
            Text("Usage")
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundStyle(theme.text)
            
            Text("Copy this component into your project and customize as needed.")
              .font(.caption)
              .foregroundStyle(theme.textMuted)
          }
        }
        
        Spacer()
      }
      .padding(theme.spacing.md)
    }
    .navigationTitle(component.cnName)
    .background(theme.background)
  }
  
  @ViewBuilder
  private var componentShowcase: some View {
    CNCard(variant: .elevated) {
      VStack(spacing: theme.spacing.lg) {
        switch component.id {
        case "button": ButtonShowcase()
        case "input": InputShowcase()
        case "card": CardShowcase()
        case "switch": SwitchShowcase()
        case "slider": SliderShowcase()
        case "badge": BadgeShowcase()
        default:
          Text("Component preview")
            .foregroundStyle(theme.textMuted)
        }
      }
    }
  }
}
