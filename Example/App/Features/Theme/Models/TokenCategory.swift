//
//  TokenCategory.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

enum TokenCategory: String, CaseIterable, Identifiable {
  case colors = "Colors"
  case chartColors = "Chart Colors"
  case spacing = "Spacing"
  case radius = "Radius"
  case shadows = "Shadows"
  case motion = "Motion"
  case opacity = "Opacity"
  case borderWidth = "Border Width"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .colors: "paintpalette"
    case .chartColors: "chart.bar"
    case .spacing: "arrow.left.and.right"
    case .radius: "square.on.circle"
    case .shadows: "shadow"
    case .motion: "hare"
    case .opacity: "circle.lefthalf.filled"
    case .borderWidth: "rectangle.inset.filled"
    }
  }

  @ViewBuilder
  var destinationView: some View {
    switch self {
    case .colors: ColorsTokenView()
    case .chartColors: ChartColorsTokenView()
    case .spacing: SpacingTokenView()
    case .radius: RadiusTokenView()
    case .shadows: ShadowsTokenView()
    case .motion: MotionTokenView()
    case .opacity: OpacityTokenView()
    case .borderWidth: BorderWidthTokenView()
    }
  }
}
