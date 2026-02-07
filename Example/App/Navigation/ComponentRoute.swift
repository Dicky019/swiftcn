//
//  ComponentRoute.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Foundation

/// Navigation routes for Components feature
enum ComponentRoute: Hashable {
  /// Navigate to component detail/showcase
  case detail(ComponentInfo)

  // Future routes could include:
  // case showcase(ComponentInfo, ShowcaseVariant)
  // case codeExample(ComponentInfo)
  // case documentation(ComponentInfo)
}
