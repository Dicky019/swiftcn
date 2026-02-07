// ComponentInfo.swift
// swiftcn Example App

import Foundation

struct ComponentInfo: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let cnName: String
    let description: String
    let iconName: String
    let sduiSupport: Bool

    static let all: [ComponentInfo] = [
        ComponentInfo(
            id: "button",
            name: "Button",
            cnName: "CNButton",
            description: "Clickable button with variants",
            iconName: "rectangle.fill",
            sduiSupport: true
        ),
        ComponentInfo(
            id: "input",
            name: "Input",
            cnName: "CNInput",
            description: "Text input with label and error states",
            iconName: "character.cursor.ibeam",
            sduiSupport: true
        ),
        ComponentInfo(
            id: "card",
            name: "Card",
            cnName: "CNCard",
            description: "Container with variants",
            iconName: "rectangle.portrait",
            sduiSupport: true
        ),
        ComponentInfo(
            id: "switch",
            name: "Switch",
            cnName: "CNSwitch",
            description: "Toggle switch for boolean values",
            iconName: "switch.2",
            sduiSupport: true
        ),
        ComponentInfo(
            id: "slider",
            name: "Slider",
            cnName: "CNSlider",
            description: "Range input control",
            iconName: "slider.horizontal.3",
            sduiSupport: true
        ),
        ComponentInfo(
            id: "badge",
            name: "Badge",
            cnName: "CNBadge",
            description: "Status indicator with variants",
            iconName: "tag",
            sduiSupport: true
        )
    ]
}
