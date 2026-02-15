//
//  NavControllerTests.swift
//  Tests
//
//  Created by Dicky Darmawan on 15/02/26.
//

import Testing
@testable import Example

@Suite("NavController Tests")
struct NavControllerTests {

  // MARK: - Duplicate Prevention

  @MainActor
  @Test("navigateTo ignores duplicate destination on top of stack")
  func ignoresDuplicateOnTop() {
    let nav = NavController()
    let dest = Destination.TokenShowcase()
    nav.navigateTo(dest)
    nav.navigateTo(Destination.TokenShowcase())
    #expect(nav.stack.count == 1)
  }

  @MainActor
  @Test("navigateTo allows same type with different params")
  func allowsSameTypeDifferentParams() {
    let nav = NavController()
    let button = ComponentInfo.all.first { $0.id == "button" }!
    let card = ComponentInfo.all.first { $0.id == "card" }!
    nav.navigateTo(Destination.ComponentDetail(info: button))
    nav.navigateTo(Destination.ComponentDetail(info: card))
    #expect(nav.stack.count == 2)
  }

  @MainActor
  @Test("navigateTo allows different type after existing")
  func allowsDifferentType() {
    let nav = NavController()
    nav.navigateTo(Destination.TokenShowcase())
    nav.navigateTo(Destination.ThemeActions())
    #expect(nav.stack.count == 2)
  }

  @MainActor
  @Test("navigateTo with popUpTo still prevents duplicate on top")
  func popUpToPreventsDuplicate() {
    let nav = NavController()
    let showcase = Destination.TokenShowcase()
    let actions = Destination.ThemeActions()
    nav.navigateTo(showcase)
    nav.navigateTo(actions)
    nav.navigateTo(Destination.TokenShowcase(), popUpTo: Destination.ThemeActions.self, inclusive: true)
    #expect(nav.stack.count == 1)
  }

  @MainActor
  @Test("batch navigateTo does not filter duplicates")
  func batchDoesNotFilterDuplicates() {
    let nav = NavController()
    let a = Destination.TokenShowcase()
    let b = Destination.TokenShowcase()
    nav.navigateTo([a, b])
    #expect(nav.stack.count == 2)
  }
}
