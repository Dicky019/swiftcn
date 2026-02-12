//
//  SDUIInfoPanelView.swift
//  Example
//
//  Created by Dicky Darmawan on 12/02/26.
//

import SwiftUI

struct SDUIInfoPanelView: View {
  @Environment(\.theme) private var theme

  let jsonString: String

  private var info: ValidationInfo {
    ValidationInfo(jsonString: jsonString)
  }

  var body: some View {
    VStack(spacing: theme.spacing.sm) {
      infoRow("Payload Size", value: info.payloadSizeText)
      Divider()
      infoRow("Node Count", value: info.nodeCountText)
      Divider()
      infoRow("Tree Depth", value: info.depthText)
      Divider()
      validationRow
    }
    .padding(theme.spacing.md)
  }

  private func infoRow(_ label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.subheadline)
        .foregroundStyle(theme.textMuted)
      Spacer()
      Text(value)
        .font(.subheadline.monospaced())
        .foregroundStyle(theme.text)
    }
  }

  private var validationRow: some View {
    HStack {
      Text("Validation")
        .font(.subheadline)
        .foregroundStyle(theme.textMuted)
      Spacer()
      if let error = info.validationError {
        CNBadge(error, variant: .destructive)
      } else {
        CNBadge("Valid", variant: .default)
      }
    }
  }
}

@MainActor
private struct ValidationInfo {
  static let maxPayloadSize = 512 * 1024

  let payloadSize: Int
  let nodeCount: Int
  let depth: Int
  let validationError: String?

  init(jsonString: String) {
    let data = jsonString.data(using: .utf8)
    payloadSize = data?.count ?? 0

    guard let data, !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      nodeCount = 0
      depth = 0
      validationError = "Empty input"
      return
    }

    do {
      let nodes = try JSONDecoder().decode([SDUINode].self, from: data)
      var totalNodes = 0
      var maxDepth = 0
      for node in nodes {
        totalNodes += node.totalNodeCount()
        maxDepth = max(maxDepth, node.maxTreeDepth())
      }
      nodeCount = totalNodes
      depth = maxDepth

      if payloadSize > Self.maxPayloadSize {
        validationError = "Payload too large"
      } else if maxDepth > SDUINode.maxDepth {
        validationError = "Max depth exceeded"
      } else if totalNodes > SDUINode.maxNodeCount {
        validationError = "Max nodes exceeded"
      } else {
        validationError = nil
      }
    } catch {
      nodeCount = 0
      depth = 0
      validationError = "Invalid JSON"
    }
  }

  var payloadSizeText: String {
    let kb = Double(payloadSize) / 1024.0
    let maxKB = Double(Self.maxPayloadSize) / 1024.0
    if kb < 1 {
      return "\(payloadSize) B / \(Int(maxKB)) KB"
    }
    return String(format: "%.1f KB / %d KB", kb, Int(maxKB))
  }

  var nodeCountText: String {
    "\(nodeCount) / \(SDUINode.maxNodeCount) nodes"
  }

  var depthText: String {
    "\(depth) / \(SDUINode.maxDepth) levels"
  }
}
