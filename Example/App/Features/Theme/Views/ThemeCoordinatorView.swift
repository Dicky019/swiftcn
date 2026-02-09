//
//  ThemeCoordinatorView.swift
//  Example
//
//  Created by Dicky Darmawan on 09/02/26.
//

import SwiftUI

struct ThemeCoordinatorView: View {
  var body: some View {
    NavigationStack {
      ThemeExplorerView()
    }
  }
}

#Preview {
  ThemeCoordinatorView()
    .environment(ThemeProvider())
}
