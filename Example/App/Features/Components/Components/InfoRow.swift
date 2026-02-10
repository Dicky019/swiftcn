//
//  InfoRow.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import SwiftUI

struct InfoRow: View {
  @Environment(\.theme) private var theme
  
  let label: String
  let value: String
  
  var body: some View {
    HStack {
      Text(label)
        .font(.subheadline)
        .foregroundStyle(theme.textSecondary)
      
      Spacer()
      
      Text(value)
        .font(.body)
        .foregroundStyle(theme.text)
    }
  }
}
