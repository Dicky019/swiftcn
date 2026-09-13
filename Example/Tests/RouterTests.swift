//
//  RouterTests.swift
//  Example/Tests
//
//  Created by Dicky Darmawan on 13/09/26.
//

@testable import Example
import Testing

@Suite("Router Tests")
@MainActor
struct RouterTests {
  enum Route: Hashable {
    case home
    case cart
    case shipping
    case payment
    case confirmation
    case receipt
  }

  @Test("push appends a route")
  func pushAppendsRoute() {
    let router = Router<Route>(path: [.home])

    router.push(.cart)

    #expect(router.path == [.home, .cart])
  }

  @Test("pop removes the last route")
  func popRemovesLastRoute() {
    let router = Router<Route>(path: [.home, .cart])

    router.pop()

    #expect(router.path == [.home])
  }

  @Test("pop on an empty path is a no-op")
  func popOnEmptyPathIsNoOp() {
    let router = Router<Route>()

    router.pop()

    #expect(router.path.isEmpty)
  }

  @Test("popToRoot clears the path")
  func popToRootClearsPath() {
    let router = Router<Route>(path: [.home, .cart, .shipping])

    router.popToRoot()

    #expect(router.path.isEmpty)
  }

  @Test("replace installs an entire path")
  func replaceInstallsEntirePath() {
    let router = Router<Route>(path: [.home, .cart])

    router.replace(with: [.confirmation, .receipt])

    #expect(router.path == [.confirmation, .receipt])
  }

  @Test("replaceLast preserves the prefix and replaces the suffix")
  func replaceLastPreservesPrefix() {
    let router = Router<Route>(
      path: [.home, .cart, .shipping, .payment]
    )

    router.replaceLast(2, with: [.confirmation, .receipt])

    #expect(router.path == [.home, .cart, .confirmation, .receipt])
  }

  @Test("replaceLast replaces the whole path when count is oversized")
  func replaceLastWithOversizedCountReplacesWholePath() {
    let router = Router<Route>(path: [.home, .cart])

    router.replaceLast(99, with: [.receipt])

    #expect(router.path == [.receipt])
  }

  @Test("replaceLast ignores nonpositive counts")
  func replaceLastIgnoresNonpositiveCounts() {
    let router = Router<Route>(path: [.home, .cart])

    router.replaceLast(0, with: [.shipping])
    router.replaceLast(-1, with: [.payment])

    #expect(router.path == [.home, .cart])
  }
}
