//
//  SDUIPlaygroundView.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct SDUIPlaygroundView: View {
  @Environment(\.theme) private var theme
  @Environment(AppNavController.self) private var appNav

  @State private var jsonInput = SDUITemplate.all.first?.json ?? ""
  @State private var selectedTemplate: SDUITemplate? = SDUITemplate.all.first
  @State private var actionHandler = PlaygroundActionHandler()
  @State private var selectedTab: BottomTab = .editor
  @State private var showTemplatePicker = false

  private enum BottomTab: String, CaseIterable {
    case editor = "Editor"
    case actionLog = "Action Log"
    case info = "Info"
  }

  var body: some View {
    @Bindable var navController = appNav.sdui

    NavigationStack(path: $navController.stack) {
      VStack(spacing: 0) {
        previewArea
        Divider()
        bottomPanel
      }
      .background(theme.background)
      .navigationTitle("SDUI Playground")
      .navigationDestination(for: BaseDestination.self) { destination in
        AnyView(destination.getScreen())
      }
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showTemplatePicker = true
          } label: {
            Label("Templates", systemImage: "list.bullet")
          }
        }
      }
      .sheet(isPresented: $showTemplatePicker) {
        TemplatePickerSheet(
          selectedTemplate: $selectedTemplate,
          jsonInput: $jsonInput
        )
        .presentationDetents([.medium, .large])
      }
    }
    .environment(appNav.sdui)
    .onAppear {
      actionHandler.navController = appNav.sdui
      actionHandler.appNavController = appNav
    }
  }

  // MARK: - Preview Area

  private var previewArea: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: theme.spacing.md) {
        if selectedTemplate?.id == "full-example" {
          counterDisplay
        }
        renderResult
      }
      .padding(theme.spacing.md)
    }
    .frame(maxHeight: .infinity)
  }

  private var counterDisplay: some View {
    Text("\(actionHandler.counter)")
      .font(.system(size: 48, weight: .bold, design: .rounded))
      .foregroundStyle(theme.text)
      .contentTransition(.numericText())
      .animation(.snappy, value: actionHandler.counter)
  }

  @ViewBuilder
  private var renderResult: some View {
    switch parseResult {
    case .success(let renderer):
      renderer
    case .failure(let error):
      ContentUnavailableView(
        "Render Error",
        systemImage: "exclamationmark.triangle",
        description: Text(error.localizedDescription)
      )
    }
  }

  private var parseResult: Result<SDUIRenderer, Error> {
    Result { try SDUIRenderer(jsonString: jsonInput, actionHandler: actionHandler) }
  }

  // MARK: - Bottom Panel

  private var bottomPanel: some View {
    VStack(spacing: 0) {
      Picker("Tab", selection: $selectedTab) {
        ForEach(BottomTab.allCases, id: \.self) { tab in
          Text(tab.rawValue).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, theme.spacing.md)
      .padding(.top, theme.spacing.sm)

      Group {
        switch selectedTab {
        case .editor:
          editorTab
        case .actionLog:
          SDUIActionLogView(handler: actionHandler)
        case .info:
          SDUIInfoPanelView(jsonString: jsonInput)
        }
      }
      .frame(height: 250)
    }
    .background(theme.card)
  }

  // MARK: - Editor Tab

  private var editorTab: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      HStack {
        if let template = selectedTemplate {
          CNBadge(template.name, variant: .secondary)
        }

        Spacer()

        Button {
          formatJSON()
        } label: {
          Label("Format", systemImage: "text.alignleft")
            .font(.caption)
        }
        .foregroundStyle(theme.primary)

        Button {
          UIPasteboard.general.string = jsonInput
        } label: {
          Label("Copy", systemImage: "doc.on.doc")
            .font(.caption)
        }
        .foregroundStyle(theme.primary)
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.top, theme.spacing.sm)

      TextEditor(text: $jsonInput)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(theme.text)
        .scrollContentBackground(.hidden)
        .padding(theme.spacing.sm)
        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
        .overlay(
          RoundedRectangle(cornerRadius: theme.radius.md)
            .stroke(theme.border, lineWidth: theme.borderWidth.regular)
        )
        .padding(.horizontal, theme.spacing.md)
        .padding(.bottom, theme.spacing.sm)
        .onChange(of: jsonInput) {
          selectedTemplate = SDUITemplate.all.first { $0.json == jsonInput }
        }
    }
  }

  // MARK: - Helpers

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

#Preview {
  SDUIPlaygroundView()
}
