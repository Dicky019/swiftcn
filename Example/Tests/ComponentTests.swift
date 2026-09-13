//
//  ComponentTests.swift
//  Tests
//
//  Created by Dicky Darmawan on 03/02/26.
//

@testable import Example
import SwiftUI
import Testing

@Suite("Component Tests")
struct ComponentTests {
  
  // MARK: - CNButton
  
  @Test("CNButton.Size has all cases")
  func buttonSizesExist() {
    #expect(CNButton.Size.allCases.count == 3)
  }
  
  @Test("CNButton.Variant has all cases")
  func buttonVariantsExist() {
    #expect(CNButton.Variant.allCases.count == 6)
  }

  @Test("CNButton.Configuration supports isLoading with default false")
  func buttonConfigurationLoading() throws {
    let configDefault = CNButton.Configuration(label: "Submit")
    #expect(configDefault.isLoading == false)

    let configLoading = CNButton.Configuration(label: "Loading", isLoading: true)
    #expect(configLoading.isLoading == true)

    let encoded = try JSONEncoder().encode(configLoading)
    let decoded = try JSONDecoder().decode(CNButton.Configuration.self, from: encoded)
    #expect(decoded.isLoading == true)
  }

  @Test("CNButton can be instantiated for all variants including link")
  @MainActor
  func buttonInstantiation() {
    let linkButton = CNButton("Terms of Service", variant: .link) {}
    let smButton = CNButton("Small", size: .sm) {}
    _ = linkButton
    _ = smButton
  }
  
  // MARK: - CNCard
  
  @Test("CNCard.Variant has all cases")
  func cardVariantsExist() {
    #expect(CNCard<AnyView>.Variant.allCases.count == 3)
  }

  // MARK: - CNSwitch

  @Test("CNSwitchToggleStyle can be instantiated")
  @MainActor
  func switchToggleStyleExists() {
    _ = CNSwitchToggleStyle()
    _ = CNSwitchToggleStyle(standalone: true)
  }

  @Test("CNSwitch can be instantiated with label and standalone with accessibilityLabel")
  @MainActor
  func switchInstantiation() {
    var isOn = false
    let binding = Binding(get: { isOn }, set: { isOn = $0 })
    let labeledSwitch = CNSwitch("Airplane Mode", isOn: binding)
    let standaloneSwitch = CNSwitch(accessibilityLabel: "Airplane Mode", isOn: binding)
    _ = labeledSwitch
    _ = standaloneSwitch
  }
  
  // MARK: - CNBadge
  
  @Test("CNBadge.Variant has all cases")
  func badgeVariantsExist() {
    #expect(CNBadge.Variant.allCases.count == 4)
  }
  
  // MARK: - ColorSchemePreference
  
  @Test("ColorSchemePreference has all three options")
  func colorSchemePreferenceHasAllOptions() {
    #expect(ColorSchemePreference.allCases.count == 3)
  }
}
