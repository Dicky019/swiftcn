//
//  TemplatePickerSheet.swift
//  Example
//
//  Created by Dicky Darmawan on 15/02/26.
//

import SwiftUI

struct TemplatePickerSheet: View {
  @Environment(\.theme) private var theme
  @Environment(\.dismiss) private var dismiss

  @Binding var selectedTemplate: SDUITemplate?
  @Binding var jsonInput: String

  var body: some View {
    NavigationStack {
      List {
        ForEach(SDUITemplate.TemplateCategory.allCases, id: \.self) { category in
          Section(category.rawValue) {
            ForEach(SDUITemplate.templates(for: category)) { template in
              Button {
                selectedTemplate = template
                jsonInput = template.json
                dismiss()
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                      .font(.body)
                      .foregroundStyle(theme.text)
                    Text(template.description)
                      .font(.caption)
                      .foregroundStyle(theme.textMuted)
                  }
                  Spacer()
                  if selectedTemplate?.id == template.id {
                    Image(systemName: "checkmark")
                      .foregroundStyle(theme.primary)
                      .font(.body.weight(.semibold))
                  }
                }
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
          Button("Done") { dismiss() }
        }
      }
    }
  }
}
