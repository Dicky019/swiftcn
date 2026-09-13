//
//  ComponentInfo.swift
//  Example
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Foundation

struct ComponentInfo: Identifiable, Hashable, Sendable {
  let id: String
  let name: String
  let cnName: String
  let description: String
  let iconName: String
  let sduiSupport: Bool
  
  static let all: [Self] = [
    .init(
      id: "button",
      name: "Button",
      cnName: "CNButton",
      description: "Clickable button with variants",
      iconName: "rectangle.fill",
      sduiSupport: true
    ),
    .init(
      id: "input",
      name: "Input",
      cnName: "CNInput",
      description: "Text input with label and error states",
      iconName: "character.cursor.ibeam",
      sduiSupport: true
    ),
    .init(
      id: "card",
      name: "Card",
      cnName: "CNCard",
      description: "Container with variants",
      iconName: "rectangle.portrait",
      sduiSupport: true
    ),
    .init(
      id: "switch",
      name: "Switch",
      cnName: "CNSwitch",
      description: "Toggle switch for boolean values",
      iconName: "switch.2",
      sduiSupport: true
    ),
    .init(
      id: "slider",
      name: "Slider",
      cnName: "CNSlider",
      description: "Range input control",
      iconName: "slider.horizontal.3",
      sduiSupport: true
    ),
    .init(
      id: "badge",
      name: "Badge",
      cnName: "CNBadge",
      description: "Status indicator with variants",
      iconName: "tag",
      sduiSupport: true
    )
  ]
}
