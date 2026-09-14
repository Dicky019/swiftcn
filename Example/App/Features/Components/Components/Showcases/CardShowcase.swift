//
//  CardShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct CardShowcase: View {
  @Environment(\.theme) private var theme

  @State private var projectName = ""
  @State private var framework = "Next.js"

  var body: some View {
    VStack(spacing: theme.spacing.md) {
      // 1. Full Featured Card
      Text("Full Featured Card")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)

      CNCard(
        title: "Create project",
        description: "Deploy your new project in one-click.",
        variant: .elevated,
        action: {
          CNButton("Draft", size: .sm, variant: .ghost) { }
        },
        footer: {
          HStack {
            CNButton("Cancel", size: .sm, variant: .outline) { }
            Spacer()
            CNButton("Deploy", size: .sm) { }
          }
        }
      ) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          CNInput("Name of your project", text: $projectName, label: "Name")
          CNInput("Select framework", text: $framework, label: "Framework")
        }
      }

      // 2. Scheduled Reports (with Footer Divider)
      Text("Scheduled Reports")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      CNCard(
        title: "Scheduled reports",
        description: "Weekly snapshots. No more manual exports.",
        variant: .elevated,
        size: .sm,
        hasFooterDivider: true,
        footer: {
          CNButton("Set up scheduled reports", size: .sm) { }
            .frame(maxWidth: .infinity)
        }
      ) {
        VStack(spacing: theme.spacing.sm) {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text("Weekly Executive Summary")
                .font(.subheadline.weight(.medium))
              Text("Every Monday at 9:00 AM")
                .font(.caption)
                .foregroundStyle(theme.textMuted)
            }
            Spacer()
            CNBadge("Active", variant: .secondary)
          }

          Divider()

          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text("Monthly Retention Digest")
                .font(.subheadline.weight(.medium))
              Text("First day of each month")
                .font(.caption)
                .foregroundStyle(theme.textMuted)
            }
            Spacer()
            CNBadge("Paused", variant: .outline)
          }
        }
      }

      // 3. Small Card (size: .sm)
      Text("Small Card")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      CNCard(
        title: "Quick Stats",
        description: "Real-time sync performance.",
        variant: .outlined,
        size: .sm
      ) {
        HStack {
          VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Latency")
              .font(.caption)
              .foregroundStyle(theme.textMuted)
            Text("24ms")
              .font(.subheadline.weight(.semibold))
          }
          Spacer()
          VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Uptime")
              .font(.caption)
              .foregroundStyle(theme.textMuted)
            Text("99.98%")
              .font(.subheadline.weight(.semibold))
          }
          Spacer()
          VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Errors")
              .font(.caption)
              .foregroundStyle(theme.textMuted)
            Text("0.01%")
              .font(.subheadline.weight(.semibold))
          }
        }
      }

      // 4. Variant Comparison (.elevated, .outlined, .filled)
      Text("Variant Comparison")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      CNCard(variant: .elevated) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text("Elevated Card")
            .font(.headline)
          Text("This card has a shadow for depth.")
            .font(.body)
            .foregroundStyle(theme.textMuted)
        }
      }

      CNCard(variant: .outlined) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text("Outlined Card")
            .font(.headline)
          Text("This card has a border instead of shadow.")
            .font(.body)
            .foregroundStyle(theme.textMuted)
        }
      }

      CNCard(variant: .filled) {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text("Filled Card")
            .font(.headline)
          Text("This card has just a background color.")
            .font(.body)
            .foregroundStyle(theme.textMuted)
        }
      }
    }
  }
}
