//
//  TokenRows.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

// MARK: - Color Row

struct ColorRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let color: Color

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      RoundedRectangle(cornerRadius: 4)
        .fill(color)
        .frame(width: 40, height: 24)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(theme.border, lineWidth: 1)
        )
    }
  }
}

// MARK: - Spacing Row

struct SpacingRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let value: CGFloat

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("\(Int(value))pt")
        .foregroundStyle(theme.textSecondary)
      Rectangle()
        .fill(theme.primary.opacity(0.3))
        .frame(width: max(value, 1), height: 16)
    }
  }
}

// MARK: - Radius Row

struct RadiusRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let value: CGFloat

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("\(Int(value))pt")
        .foregroundStyle(theme.textSecondary)
      RoundedRectangle(cornerRadius: min(value, 16))
        .fill(theme.primary)
        .frame(width: 32, height: 32)
    }
  }
}

// MARK: - Shadow Row

struct ShadowRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let shadow: ThemeShadow

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("r:\(Int(shadow.radius)) y:\(Int(shadow.y))")
        .font(.caption)
        .foregroundStyle(theme.textSecondary)
      RoundedRectangle(cornerRadius: theme.radius.md)
        .fill(theme.card)
        .frame(width: 40, height: 24)
        .shadow(
          color: .black.opacity(shadow.opacity),
          radius: shadow.radius,
          y: shadow.y
        )
    }
  }
}

// MARK: - Motion Row

struct MotionRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let duration: Double
  @State private var isAnimating = false

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("\(duration, specifier: "%.2f")s")
        .foregroundStyle(theme.textSecondary)
      Circle()
        .fill(theme.primary)
        .frame(width: 16, height: 16)
        .offset(x: isAnimating ? 20 : 0)
        .animation(.easeInOut(duration: duration), value: isAnimating)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      isAnimating.toggle()
    }
  }
}

// MARK: - Opacity Row

struct OpacityRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let value: Double

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("\(Int(value * 100))%")
        .foregroundStyle(theme.textSecondary)
      RoundedRectangle(cornerRadius: 4)
        .fill(theme.primary.opacity(value))
        .frame(width: 40, height: 24)
    }
  }
}

// MARK: - Border Width Row

struct BorderWidthRow: View {
  @Environment(\.theme) private var theme
  let name: String
  let value: CGFloat

  var body: some View {
    HStack {
      Text(name)
      Spacer()
      Text("\(value, specifier: "%.1f")pt")
        .foregroundStyle(theme.textSecondary)
      RoundedRectangle(cornerRadius: 4)
        .stroke(theme.border, lineWidth: max(value, 0.5))
        .frame(width: 40, height: 24)
    }
  }
}
