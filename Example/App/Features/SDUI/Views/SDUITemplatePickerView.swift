//
//  SDUITemplatePickerView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SDUITemplatePickerView: View {
  @Environment(\.theme) private var theme
  
  let onSelect: (SDUITemplate) -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationStack {
      List {
        Section("Featured Showcases") {
          ForEach(SDUITemplate.all) { template in
            Button {
              onSelect(template)
              dismiss()
            } label: {
              VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                  Text(template.name)
                    .font(.headline)
                    .foregroundStyle(theme.text)
                  Spacer()
                  CNBadge(template.tags.first ?? "Showcase", variant: .secondary)
                }
                
                Text(template.description)
                  .font(.subheadline)
                  .foregroundStyle(theme.textMuted)
                
                HStack(spacing: 6) {
                  ForEach(template.tags, id: \.self) { tag in
                    Text(tag)
                      .font(.system(size: 11, weight: .medium, design: .rounded))
                      .padding(.horizontal, 8)
                      .padding(.vertical, 3)
                      .background(theme.card)
                      .clipShape(Capsule())
                      .foregroundStyle(theme.text)
                      .overlay(
                        Capsule()
                          .stroke(theme.border, lineWidth: 1)
                      )
                  }
                }
                .padding(.top, 4)
              }
              .padding(.vertical, theme.spacing.xs)
            }
          }
        }
      }
      .navigationTitle("Templates")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  SDUITemplatePickerView { template in
    print("Selected: \(template.name)")
  }
}
