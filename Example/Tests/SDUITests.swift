//
//  SDUITests.swift
//  Tests
//
//  Created by Dicky Darmawan on 11/09/26.
//

import Foundation
import Testing
@testable import Example

@Suite("SDUI Tests")
struct SDUITests {
  @Test("Integer props convert to Double")
  func integerPropConvertsToDouble() {
    #expect(AnyCodable.int(16).doubleValue == 16)
  }

  @Test("Typed accessors reject another scalar type")
  func typedAccessorsRejectAnotherType() {
    #expect(AnyCodable.bool(true).stringValue == nil)
    #expect(AnyCodable.string("16").doubleValue == nil)
  }

  @Test("Core registry contains native layout")
  @MainActor
  func coreRegistryContainsNativeLayout() {
    #expect(SDUIRegistry.shared.isRegistered("vstack"))
  }

  @Test("Button registration is explicit")
  @MainActor
  func buttonRegistrationIsExplicit() {
    SDUIRegistry.shared.registerCNButton()
    #expect(SDUIRegistry.shared.isRegistered("button"))
  }

  @Test("Switch configuration reads its initial value")
  func switchConfigurationReadsInitialValue() throws {
    let node = SDUINode(
      id: "switch",
      type: "switch",
      props: ["label": AnyCodable("Wi-Fi"), "isOn": AnyCodable(true)]
    )

    let configuration = try CNSwitch.Configuration(node: node)
    #expect(configuration.label == "Wi-Fi")
    #expect(configuration.isOn)
  }

  @Test("Slider accepts integer wire values")
  func sliderAcceptsIntegerWireValues() throws {
    let node = SDUINode(
      id: "slider",
      type: "slider",
      props: [
        "value": AnyCodable(25),
        "min": AnyCodable(0),
        "max": AnyCodable(100),
        "showValue": AnyCodable(true)
      ]
    )

    let configuration = try CNSlider.Configuration(node: node)
    #expect(configuration.value == 25)
    #expect(configuration.minValue == 0)
    #expect(configuration.maxValue == 100)
    #expect(configuration.showValue)
  }

  @Test("Slider rejects an inverted range")
  func sliderRejectsInvertedRange() {
    let node = SDUINode(
      id: "slider",
      type: "slider",
      props: ["min": AnyCodable(10), "max": AnyCodable(1)]
    )

    #expect(throws: SDUIError.self) {
      try CNSlider.Configuration(node: node)
    }
  }

  @Test("Present props with the wrong type are rejected")
  func presentPropsWithWrongTypeAreRejected() {
    let node = SDUINode(
      id: "switch",
      type: "switch",
      props: ["label": AnyCodable("Wi-Fi"), "isOn": AnyCodable("true")]
    )

    #expect(throws: SDUIError.self) {
      try CNSwitch.Configuration(node: node)
    }
  }

  @Test("Unknown enum props are rejected")
  func unknownEnumPropsAreRejected() {
    let node = SDUINode(
      id: "button",
      type: "button",
      props: ["label": AnyCodable("Save"), "variant": AnyCodable("unknown")]
    )

    #expect(throws: SDUIError.self) {
      try CNButton.Configuration(node: node)
    }
  }

  @Test("Slider rejects values outside its range")
  func sliderRejectsValuesOutsideItsRange() {
    let node = SDUINode(
      id: "slider",
      type: "slider",
      props: ["value": AnyCodable(101), "min": AnyCodable(0), "max": AnyCodable(100)]
    )

    #expect(throws: SDUIError.self) {
      try CNSlider.Configuration(node: node)
    }
  }

  @Test("Slider rejects a non-positive step")
  func sliderRejectsNonPositiveStep() {
    let node = SDUINode(
      id: "slider",
      type: "slider",
      props: ["step": AnyCodable(0)]
    )

    #expect(throws: SDUIError.self) {
      try CNSlider.Configuration(node: node)
    }
  }

  @Test("Legacy switch configuration JSON keeps its default state")
  func legacySwitchConfigurationKeepsDefaultState() throws {
    let data = Data(#"{"label":"Wi-Fi"}"#.utf8)
    let configuration = try JSONDecoder().decode(CNSwitch.Configuration.self, from: data)
    #expect(!configuration.isOn)
  }

  @Test("Legacy slider configuration JSON keeps its defaults")
  func legacySliderConfigurationKeepsDefaults() throws {
    let data = Data(#"{}"#.utf8)
    let configuration = try JSONDecoder().decode(CNSlider.Configuration.self, from: data)
    #expect(configuration.value == 0)
    #expect(configuration.minValue == 0)
    #expect(configuration.maxValue == 100)
  }

  @Test("All featured SDUI templates parse into valid renderers")
  @MainActor
  func allFeaturedTemplatesParseSuccessfully() throws {
    let registry = SDUIRegistry.shared
    registry.registerCNButton()
    registry.registerCNCard()
    registry.registerCNBadge()
    registry.registerCNInput()
    registry.registerCNSwitch()
    registry.registerCNSlider()

    #expect(SDUITemplate.all.count == 3)
    for template in SDUITemplate.all {
      let data = try #require(template.json.data(using: .utf8))
      let nodes = try JSONDecoder().decode([SDUINode].self, from: data)
      #expect(!nodes.isEmpty)
      _ = try SDUIRenderer(jsonString: template.json)
    }
  }
}
