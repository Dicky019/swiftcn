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
  @State private var actionHandler = PlaygroundActionHandler()
  @State private var selectedTab: BottomTab = .editor

  private enum BottomTab: String, CaseIterable {
    case editor = "Editor"
    case actionLog = "Action Log"
    case info = "Info"
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        templateBar
        Divider()
        previewArea
        Divider()
        bottomPanel
      }
      .background(theme.background)
      .navigationTitle("SDUI Playground")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
    }
  }

  // MARK: - Template Bar

  private var templateBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: theme.spacing.sm) {
        ForEach(SDUITemplate.TemplateCategory.allCases, id: \.self) { category in
          templateCategorySection(category)
        }
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm)
    }
    .background(theme.card)
  }

  private func templateCategorySection(_ category: SDUITemplate.TemplateCategory) -> some View {
    HStack(spacing: theme.spacing.xs) {
      Text(category.rawValue)
        .font(.caption2)
        .foregroundStyle(theme.textMuted)
        .textCase(.uppercase)

      ForEach(SDUITemplate.templates(for: category)) { template in
        Button {
          selectedTemplate = template
          jsonInput = template.json
        } label: {
          CNBadge(
            template.name,
            variant: selectedTemplate?.id == template.id ? .default : .outline
          )
        }
      }
    }
  }

  // MARK: - Preview Area

  private var previewArea: some View {
    ScrollView {
      VStack(spacing: theme.spacing.md) {
        renderResult
      }
      .padding(theme.spacing.md)
    }
    .frame(maxHeight: .infinity)
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
