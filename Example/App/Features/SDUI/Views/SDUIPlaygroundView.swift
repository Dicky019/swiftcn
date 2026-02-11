//
//  SDUIPlaygroundView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SDUIPlaygroundView: View {
  @Environment(\.theme) private var theme
  
  @State private var jsonInput = SDUITemplate.all.first?.json ?? ""
  @State private var selectedTemplate: SDUITemplate? = SDUITemplate.all.first
  @State private var showTemplatePicker = false
  @State private var actionHandler = DemoActionHandler()
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Preview Area
        ScrollView {
          VStack(spacing: theme.spacing.md) {
            if let renderer = try? SDUIRenderer(jsonString: jsonInput, actionHandler: actionHandler) {
              renderer
            } else {
              ContentUnavailableView(
                "Invalid JSON",
                systemImage: "exclamationmark.triangle",
                description: Text("Check your JSON syntax")
              )
            }
          }
          .padding(theme.spacing.md)
        }
        .frame(maxHeight: .infinity)
        
        Divider()
        
        // JSON Editor
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          HStack {
            Text("JSON Input")
              .font(.headline)
              .foregroundStyle(theme.text)

            if let template = selectedTemplate {
              CNBadge(template.name, variant: .secondary)
            }

            Spacer()

            Button {
              showTemplatePicker = true
            } label: {
              Label("Templates", systemImage: "doc.text")
                .foregroundStyle(theme.primary)
            }
          }

          TextEditor(text: $jsonInput)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(theme.text)
            .scrollContentBackground(.hidden)
            .padding(theme.spacing.sm)
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
            .overlay(
              RoundedRectangle(cornerRadius: theme.radius.md)
                .stroke(theme.border, lineWidth: theme.borderWidth.regular)
            )
        }
        .padding(theme.spacing.md)
        .background(theme.card)
      }
      .background(theme.background)
      .navigationTitle("SDUI Playground")
      .sheet(isPresented: $showTemplatePicker) {
        SDUITemplatePickerView { template in
          selectedTemplate = template
          jsonInput = template.json
        }
      }
    }
  }
}

// Demo action handler
@MainActor
final class DemoActionHandler: SDUIActionHandler {
  func handleAction(id: String, payload: [String: AnyCodable]?) {
    print("Action: \(id), payload: \(String(describing: payload))")
  }

  func handleNavigation(route: String, params: [String: AnyCodable]?) {
    print("Navigate: \(route)")
  }
}

#Preview {
  SDUIPlaygroundView()
}
