//
//  SDUIActionLogView.swift
//  Example
//
//  Created by Dicky Darmawan on 12/02/26.
//

import SwiftUI

struct SDUIActionLogView: View {
  @Environment(\.theme) private var theme

  let handler: PlaygroundActionHandler

  var body: some View {
    VStack(spacing: 0) {
      if handler.logEntries.isEmpty {
        ContentUnavailableView(
          "No Actions Yet",
          systemImage: "list.bullet.rectangle",
          description: Text("Interact with the preview to see actions here")
        )
      } else {
        HStack {
          Spacer()
          Button("Clear") {
            handler.clearLog()
          }
          .font(.caption)
          .foregroundStyle(theme.primary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.top, theme.spacing.sm)

        ScrollView {
          LazyVStack(alignment: .leading, spacing: theme.spacing.xs) {
            ForEach(handler.logEntries.reversed()) { entry in
              entryRow(entry)
            }
          }
          .padding(.horizontal, theme.spacing.md)
          .padding(.vertical, theme.spacing.sm)
        }
      }
    }
  }

  private func entryRow(_ entry: ActionLogEntry) -> some View {
    HStack(alignment: .top, spacing: theme.spacing.sm) {
      Circle()
        .fill(dotColor(for: entry.kind))
        .frame(width: 8, height: 8)
        .padding(.top, 5)

      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text(entry.actionId)
            .font(.headline)
            .foregroundStyle(theme.text)

          Spacer()

          Text(entry.timestamp, format: .dateTime.hour().minute().second())
            .font(.caption)
            .foregroundStyle(theme.textMuted)
        }

        if let payload = entry.payloadDescription, !payload.isEmpty {
          Text(payload)
            .font(.caption)
            .foregroundStyle(theme.textMuted)
            .lineLimit(1)
        }

        Text(kindLabel(entry.kind))
          .font(.caption2)
          .foregroundStyle(theme.textMuted)
      }
    }
    .padding(.vertical, theme.spacing.xs)
  }

  private func dotColor(for kind: ActionLogEntry.Kind) -> Color {
    switch kind {
    case .action: .green
    case .navigation: .blue
    case .blocked: .red
    }
  }

  private func kindLabel(_ kind: ActionLogEntry.Kind) -> String {
    switch kind {
    case .action: "Action"
    case .navigation: "Navigation"
    case .blocked: "Blocked"
    }
  }
}
