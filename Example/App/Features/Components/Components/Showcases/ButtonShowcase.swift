//
//  ButtonShowcase.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct ButtonShowcase: View {
  @Environment(\.theme) private var theme
  @State private var showMotionDemo = false

  var body: some View {
    VStack(spacing: theme.spacing.md) {
      Text("Button Variants")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: theme.spacing.sm) {
        CNButton("Default", variant: .default) {}
        CNButton("Destructive", variant: .destructive) {}
        CNButton("Outline", variant: .outline) {}
        CNButton("Secondary", variant: .secondary) {}
        CNButton("Ghost", variant: .ghost) {}
        CNButton("Link", variant: .link) {}
      }

      Text("Sizes")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      HStack(spacing: theme.spacing.sm) {
        CNButton("Small", size: .sm) {}
        CNButton("Medium", size: .md) {}
        CNButton("Large", size: .lg) {}
      }

      Text("States")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      HStack(spacing: theme.spacing.sm) {
        CNButton("Enabled") {}
        CNButton("Disabled") {}
          .disabled(true)
      }

      Text("Motion Tokens Demo")
        .font(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.md)

      VStack(spacing: theme.spacing.sm) {
        HStack(spacing: theme.spacing.sm) {
          Text("fast: \(theme.motion.fast, specifier: "%.2f")s")
            .font(.caption)
            .foregroundStyle(theme.mutedForeground)
          Text("normal: \(theme.motion.normal, specifier: "%.2f")s")
            .font(.caption)
            .foregroundStyle(theme.mutedForeground)
          Text("slow: \(theme.motion.slow, specifier: "%.2f")s")
            .font(.caption)
            .foregroundStyle(theme.mutedForeground)
        }

        CNButton(showMotionDemo ? "Hide" : "Show Animation") {
          withAnimation(.easeInOut(duration: theme.motion.normal)) {
            showMotionDemo.toggle()
          }
        }

        if showMotionDemo {
          HStack(spacing: theme.spacing.md) {
            VStack {
              Circle()
                .fill(theme.primary)
                .frame(width: 40, height: 40)
              Text("fast")
                .font(.caption2)
            }
            .transition(.scale.animation(.easeInOut(duration: theme.motion.fast)))

            VStack {
              Circle()
                .fill(theme.secondary)
                .frame(width: 40, height: 40)
              Text("normal")
                .font(.caption2)
            }
            .transition(.scale.animation(.easeInOut(duration: theme.motion.normal)))

            VStack {
              Circle()
                .fill(theme.accent)
                .frame(width: 40, height: 40)
              Text("slow")
                .font(.caption2)
            }
            .transition(.scale.animation(.easeInOut(duration: theme.motion.slow)))
          }
        }
      }
    }
  }
}
