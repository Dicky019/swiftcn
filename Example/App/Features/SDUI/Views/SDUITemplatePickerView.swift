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
        ForEach(SDUITemplate.TemplateCategory.allCases, id: \.self) { category in
          Section(category.rawValue) {
            ForEach(SDUITemplate.templates(for: category)) { template in
              Button {
                onSelect(template)
                dismiss()
              } label: {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                  Text(template.name)
                    .font(.headline)
                    .foregroundStyle(theme.foreground)
                  Text(template.description)
                    .font(.caption)
                    .foregroundStyle(theme.mutedForeground)
                }
                .padding(.vertical, theme.spacing.xs)
              }
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
