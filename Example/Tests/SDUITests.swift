//
//  SDUITests.swift
//  Tests
//
//  Created by Dicky Darmawan on 11/09/26.
//

@testable import Example
import Foundation
import SwiftUI
import Testing

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

  @Test("Button configuration reads isLoading wire prop")
  func buttonConfigurationReadsIsLoading() throws {
    let node = SDUINode(
      id: "btn-1",
      type: "button",
      props: [
        "label": AnyCodable("Submit"),
        "isLoading": AnyCodable(true)
      ]
    )

    let configuration = try CNButton.Configuration(node: node)
    #expect(configuration.label == "Submit")
    #expect(configuration.isLoading == true)
  }

  @Test("Button configuration rejects non-boolean isLoading")
  func buttonConfigurationRejectsNonBooleanIsLoading() {
    let node = SDUINode(
      id: "btn-2",
      type: "button",
      props: [
        "label": AnyCodable("Submit"),
        "isLoading": AnyCodable("yes")
      ]
    )

    #expect(throws: SDUIError.self) {
      try CNButton.Configuration(node: node)
    }
  }

  @Test("Card registration is explicit")
  @MainActor
  func cardRegistrationIsExplicit() {
    SDUIRegistry.shared.registerCNCard()
    #expect(SDUIRegistry.shared.isRegistered("card"))
  }

  @Test("Card configuration reads all wire values")
  func cardConfigurationReadsAllWireValues() throws {
    let node = SDUINode(
      id: "card-1",
      type: "card",
      props: [
        "variant": AnyCodable("outlined"),
        "size": AnyCodable("sm"),
        "title": AnyCodable("Deployment"),
        "description": AnyCodable("Deploy to production")
      ]
    )

    let configuration = try CNCard<AnyView>.Configuration(node: node)
    #expect(configuration.variant == .outlined)
    #expect(configuration.size == .sm)
    #expect(configuration.title == "Deployment")
    #expect(configuration.description == "Deploy to production")
  }

  @Test("Card configuration uses defaults when props omitted")
  func cardConfigurationUsesDefaultsWhenPropsOmitted() throws {
    let node = SDUINode(
      id: "card-2",
      type: "card",
      props: [:]
    )

    let configuration = try CNCard<AnyView>.Configuration(node: node)
    #expect(configuration.variant == .elevated)
    #expect(configuration.size == .default)
    #expect(configuration.title == nil)
    #expect(configuration.description == nil)
  }

  @Test("Card configuration rejects invalid scalar types")
  func cardConfigurationRejectsInvalidScalarTypes() {
    let invalidVariant = SDUINode(
      id: "card-err-1",
      type: "card",
      props: ["variant": AnyCodable("unknown_variant")]
    )
    #expect(throws: SDUIError.self) {
      try CNCard<AnyView>.Configuration(node: invalidVariant)
    }

    let invalidSize = SDUINode(
      id: "card-err-2",
      type: "card",
      props: ["size": AnyCodable("invalid_size")]
    )
    #expect(throws: SDUIError.self) {
      try CNCard<AnyView>.Configuration(node: invalidSize)
    }

    let invalidTitle = SDUINode(
      id: "card-err-3",
      type: "card",
      props: ["title": AnyCodable(12345)]
    )
    #expect(throws: SDUIError.self) {
      try CNCard<AnyView>.Configuration(node: invalidTitle)
    }

    let invalidDescription = SDUINode(
      id: "card-err-4",
      type: "card",
      props: ["description": AnyCodable(12345)]
    )
    #expect(throws: SDUIError.self) {
      try CNCard<AnyView>.Configuration(node: invalidDescription)
    }
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
