//
//  ExampleThemeLoader.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

// MARK: - Example Theme

enum ExampleTheme: String, CaseIterable, Identifiable {
  case ocean = "Ocean"
  case forest = "Forest"
  case rose = "Rose"
  case sunset = "Sunset"
  case purple = "Purple"

  var id: String { rawValue }

  var fileName: String {
    rawValue.lowercased()
  }

  var previewColor: Color {
    switch self {
    case .ocean: Color(hex: "#0284C7")
    case .forest: Color(hex: "#16A34A")
    case .rose: Color(hex: "#E11D48")
    case .sunset: Color(hex: "#EA580C")
    case .purple: Color(hex: "#9333EA")
    }
  }
}

// MARK: - Example Theme Loader

@MainActor
final class ExampleThemeLoader: ObservableObject {
  static let shared = ExampleThemeLoader()

  @Published private(set) var themes: [ExampleTheme: String] = [:]
  @Published private(set) var isLoaded = false

  private init() {}

  func loadIfNeeded() {
    guard !isLoaded else { return }

    for theme in ExampleTheme.allCases {
      if let url = Bundle.main.url(forResource: theme.fileName, withExtension: "json"),
         let data = try? Data(contentsOf: url),
         let json = String(data: data, encoding: .utf8) {
        themes[theme] = json
      }
    }

    isLoaded = true
  }

  func json(for theme: ExampleTheme) -> String {
    themes[theme] ?? "{}"
  }
}
