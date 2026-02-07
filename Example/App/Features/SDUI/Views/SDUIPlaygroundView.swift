// SDUIPlaygroundView.swift
// swiftcn Example App

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
                    .padding()
                }
                .frame(maxHeight: .infinity)
                .background(theme.background)

                Divider()

                // JSON Editor
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    HStack {
                        Text("JSON Input")
                            .font(.headline)

                        if let template = selectedTemplate {
                            CNBadge(template.name, variant: .secondary)
                        }

                        Spacer()

                        Button {
                            showTemplatePicker = true
                        } label: {
                            Label("Templates", systemImage: "doc.text")
                                .font(.caption)
                        }
                    }

                    TextEditor(text: $jsonInput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.md)
                                .stroke(theme.border, lineWidth: 1)
                        )
                }
                .padding()
                .background(theme.card)
            }
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
final class DemoActionHandler: SDUIActionHandler {
    func handleAction(id: String, payload: [String: Any]?) {
        print("Action: \(id), payload: \(payload ?? [:])")
    }

    func handleNavigation(route: String, params: [String: Any]?) {
        print("Navigate: \(route)")
    }
}

#Preview {
    SDUIPlaygroundView()
}
