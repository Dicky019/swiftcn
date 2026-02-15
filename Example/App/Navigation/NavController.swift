//
//  NavController.swift
//  Example
//
//  Created by Dicky Darmawan on 13/02/26.
//

import SwiftUI

/// Manages the navigation stack with push, pop, and advanced operations.
/// Inject via SwiftUI Environment — one instance per navigation-enabled tab.
@MainActor
@Observable
final class NavController {
  var stack: [BaseDestination] = []

  // MARK: - Push

  /// Navigate to a single destination.
  /// - Parameter launchSingleTop: If true, pops the existing instance first if it's already on top.
  func navigateTo(_ destination: BaseDestination, launchSingleTop: Bool = false) {
    guard stack.last != destination else { return }
    if launchSingleTop, let last = stack.last, last.route == destination.route {
      stack.removeLast()
    }
    stack.append(destination)
  }

  /// Navigate to multiple destinations in sequence.
  func navigateTo(_ destinations: [BaseDestination]) {
    stack.append(contentsOf: destinations)
  }

  /// Navigate after popping up to a specific destination type.
  /// - Parameters:
  ///   - destination: The destination to push.
  ///   - popUpTo: Pop the stack until this type is found.
  ///   - inclusive: If true, also removes the found destination.
  func navigateTo(
    _ destination: BaseDestination,
    popUpTo: BaseDestination.Type,
    inclusive: Bool = false
  ) {
    performPopUpTo(popUpTo, inclusive: inclusive)
    guard stack.last != destination else { return }
    stack.append(destination)
  }

  /// Navigate with both launchSingleTop and popUpTo semantics.
  func navigateTo(
    _ destination: BaseDestination,
    launchSingleTop: Bool = false,
    popUpTo: BaseDestination.Type,
    inclusive: Bool = false
  ) {
    performPopUpTo(popUpTo, inclusive: inclusive)
    guard stack.last != destination else { return }
    if launchSingleTop, let last = stack.last, last.route == destination.route {
      stack.removeLast()
    }
    stack.append(destination)
  }

  // MARK: - Pop

  /// Pop the top destination from the stack.
  func popBackStack() {
    guard !stack.isEmpty else { return }
    stack.removeLast()
  }

  /// Pop all destinations until the given type is found.
  /// - Parameter inclusive: If true, also removes the found destination.
  func popUpTo(_ destination: BaseDestination.Type, inclusive: Bool = false) {
    performPopUpTo(destination, inclusive: inclusive)
  }

  /// Clear the entire stack back to root.
  func popUpToRoot() {
    stack.removeAll()
  }

  // MARK: - Description

  /// Human-readable description of the current stack for debugging.
  func description() -> String {
    let routes = stack.map(\.route)
    return "Root → " + (routes.isEmpty ? "(empty)" : routes.joined(separator: " → "))
  }

  // MARK: - Private

  private func performPopUpTo(_ destinationType: BaseDestination.Type, inclusive: Bool) {
    let targetRoute = String(describing: destinationType)
    guard let index = stack.lastIndex(where: { $0.route == targetRoute }) else { return }
    let removeFrom = inclusive ? index : index + 1
    if removeFrom < stack.count {
      stack.removeSubrange(removeFrom..<stack.count)
    }
  }
}
