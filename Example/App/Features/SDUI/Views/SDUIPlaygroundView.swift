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
  @State private var showJsonEditor = false
  @State private var actionHandler = DemoActionHandler()
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Preview Area
        ScrollView {
          VStack(spacing: theme.spacing.md) {
            if let template = selectedTemplate {
              HStack {
                CNBadge(template.name, variant: .secondary)
                Spacer()
              }
            }

            if let renderer = try? SDUIRenderer(jsonString: jsonInput, actionHandler: actionHandler) {
              renderer
            } else {
              ContentUnavailableView(
                "Invalid JSON",
                systemImage: "exclamationmark.triangle",
                description: Text("Check your JSON syntax in the JSON Editor")
              )
            }
          }
          .padding(theme.spacing.md)
        }
        .frame(maxHeight: .infinity)
      }
      .background(theme.background)
      .navigationTitle("SDUI Playground")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showTemplatePicker = true
          } label: {
            Label("Templates", systemImage: "doc.text")
              .foregroundStyle(theme.primary)
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showJsonEditor = true
          } label: {
            Label("JSON Input", systemImage: "curlybraces")
              .foregroundStyle(theme.primary)
          }
        }
      }
      .sheet(isPresented: $showTemplatePicker) {
        SDUITemplatePickerView { template in
          selectedTemplate = template
          jsonInput = template.json
        }
        .presentationDetents([.medium, .large])
      }
      .sheet(isPresented: $showJsonEditor) {
        jsonEditorSheet
      }
    }
  }

  private var jsonEditorSheet: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        TextEditor(text: $jsonInput)
          .font(.system(.caption, design: .monospaced))
          .foregroundStyle(theme.text)
          .scrollContentBackground(.hidden)
          .padding(theme.spacing.sm)
          .background(theme.card)
          .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
          .overlay(
            RoundedRectangle(cornerRadius: theme.radius.md)
              .stroke(theme.border, lineWidth: theme.borderWidth.regular)
          )
          .padding(theme.spacing.md)
          .onChange(of: jsonInput) { _, newValue in
            selectedTemplate = SDUITemplate.all.first { $0.json == newValue }
          }
      }
      .background(theme.background)
      .navigationTitle("JSON Input")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Format") {
            formatJSON()
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            showJsonEditor = false
          }
          .fontWeight(.semibold)
        }
      }
    }
    .presentationDetents([.medium, .large])
  }

  private func formatJSON() {
    guard
      let data = jsonInput.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data),
      let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
      let string = String(data: formatted, encoding: .utf8)
    else { return }
    jsonInput = string
  }
}

// Demo action handler
@MainActor
final class DemoActionHandler: SDUIActionHandler {
  func handleAction(id: String, payload: [String: AnyCodable]?) {
    print("Action: \(id), payload: \(payload ?? [:])")
  }
  
  func handleNavigation(route: String, params: [String: AnyCodable]?) {
    print("Navigate: \(route)")
  }
}

#Preview {
  SDUIPlaygroundView()
}
