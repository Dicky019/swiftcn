//
//  SDUIPlaygroundView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import OSLog
import SwiftUI

private let playgroundLogger = Logger(subsystem: "com.swiftcn.Example", category: "SDUIPlayground")

struct SDUIPlaygroundView: View {
  @Environment(\.theme) private var theme
  
  @State private var jsonInput = SDUITemplate.all.first?.json ?? ""
  @State private var selectedTemplate: SDUITemplate? = SDUITemplate.all.first
  @State private var showTemplatePicker = false
  @State private var showJsonEditor = false
  @State private var lastActionMessage: String?
  @State private var actionDismissTask: Task<Void, Never>?
  @State private var actionHandler = PlaygroundActionHandler()
  
  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
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
          .padding(.bottom, 64)
        }
        .frame(maxHeight: .infinity)

        // Live Action Toast
        if let msg = lastActionMessage {
          HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
              .foregroundStyle(theme.primary)
            Text(msg)
              .font(.system(.caption, design: .monospaced, weight: .semibold))
              .foregroundStyle(theme.text)
              .lineLimit(1)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(
            Capsule()
              .fill(theme.card)
              .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
          )
          .overlay(
            Capsule()
              .stroke(theme.primary.opacity(0.4), lineWidth: 1)
          )
          .padding(.bottom, 16)
          .allowsHitTesting(false)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
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
      .onAppear {
        actionHandler.onAction = { id, payload in
          handleUserAction(id: id, payload: payload)
        }
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

  private func handleUserAction(id: String, payload: [String: AnyCodable]?) {
    var desc = "Action: \(id)"
    if let payload, !payload.isEmpty {
      let values = payload.map { "\($0.key): \($0.value.value)" }.sorted().joined(separator: ", ")
      desc += " [\(values)]"
    }
    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
      lastActionMessage = desc
    }
    actionDismissTask?.cancel()
    actionDismissTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(3))
      guard !Task.isCancelled else { return }
      withAnimation(.easeInOut(duration: 0.25)) {
        lastActionMessage = nil
      }
    }
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

// Interactive demo action handler
@MainActor
final class PlaygroundActionHandler: SDUIActionHandler {
  var onAction: (@MainActor (String, [String: AnyCodable]?) -> Void)?

  func handleAction(id: String, payload: [String: AnyCodable]?) {
    playgroundLogger.debug("[SDUI] Action: \(id, privacy: .public), payload: \(String(describing: payload ?? [:]), privacy: .public)")
    onAction?(id, payload)
  }
  
  func handleNavigation(route: String, params: [String: AnyCodable]?) {
    playgroundLogger.debug("[SDUI] Navigate: \(route, privacy: .public)")
    onAction?("navigate:\(route)", params)
  }
}

#Preview {
  SDUIPlaygroundView()
}
