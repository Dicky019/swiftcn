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

  // MARK: - Pop Operations

  @MainActor
  @Test("popBackStack removes top destination")
  func popBackStack() {
    let nav = NavController()
    nav.navigateTo(Destination.TokenShowcase())
    nav.navigateTo(Destination.ThemeActions())
    nav.popBackStack()
    #expect(nav.stack.count == 1)
    #expect(nav.stack.last?.route == "TokenShowcase")
  }

  @MainActor
  @Test("popBackStack on empty stack does nothing")
  func popBackStackEmpty() {
    let nav = NavController()
    nav.popBackStack()
    #expect(nav.stack.isEmpty)
  }

  @MainActor
  @Test("popUpToRoot clears entire stack")
  func popUpToRoot() {
    let nav = NavController()
    nav.navigateTo(Destination.TokenShowcase())
    nav.navigateTo(Destination.ThemeActions())
    nav.popUpToRoot()
    #expect(nav.stack.isEmpty)
  }

  @MainActor
  @Test("popUpTo exclusive keeps target")
  func popUpToExclusive() {
    let nav = NavController()
    nav.navigateTo(Destination.TokenShowcase())
    nav.navigateTo(Destination.ThemeActions())
    nav.navigateTo(Destination.TokenShowcase())
    nav.popUpTo(Destination.ThemeActions.self, inclusive: false)
    #expect(nav.stack.count == 2)
    #expect(nav.stack.last?.route == "ThemeActions")
  }

  @MainActor
  @Test("popUpTo inclusive removes target")
  func popUpToInclusive() {
    let nav = NavController()
    nav.navigateTo(Destination.TokenShowcase())
    nav.navigateTo(Destination.ThemeActions())
    nav.navigateTo(Destination.TokenShowcase())
    nav.popUpTo(Destination.ThemeActions.self, inclusive: true)
    #expect(nav.stack.count == 1)
    #expect(nav.stack.last?.route == "TokenShowcase")
  }

  // MARK: - Description

  @MainActor
  @Test("description shows stack route names")
  func descriptionShowsRoutes() {
    let nav = NavController()
    #expect(nav.description() == "Root → (empty)")
    nav.navigateTo(Destination.TokenShowcase())
    #expect(nav.description() == "Root → TokenShowcase")
  }

  // MARK: - LaunchSingleTop

  @MainActor
  @Test("launchSingleTop replaces top when same route different params")
  func launchSingleTopReplacesTop() {
    let nav = NavController()
    let button = ComponentInfo.all.first { $0.id == "button" }!
    let card = ComponentInfo.all.first { $0.id == "card" }!
    nav.navigateTo(Destination.ComponentDetail(info: button))
    nav.navigateTo(Destination.ComponentDetail(info: card), launchSingleTop: true)
    #expect(nav.stack.count == 1)
    if let top = nav.stack.last as? Destination.ComponentDetail {
      #expect(top.info.id == "card")
    }
  }
}
