//
//  Router.swift
//  Sources/Navigation
//
//  Created by Dicky Darmawan on 13/09/26.
//

import Observation

@MainActor
@Observable
public final class Router<Route: Hashable> {
  public var path: [Route]

  public init(path: [Route] = []) {
    self.path = path
  }

  public func push(_ route: Route) {
    path.append(route)
  }

  public func pop() {
    guard !path.isEmpty else { return }
    path.removeLast()
  }

  public func popToRoot() {
    path.removeAll()
  }

  public func replace(with routes: [Route]) {
    path = routes
  }

  public func replaceLast(_ count: Int, with routes: [Route]) {
    guard count > 0 else { return }
    let retainedCount = Swift.max(0, path.count - count)
    path = Array(path.prefix(retainedCount)) + routes
  }
}
