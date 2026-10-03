//
//  Score.swift
//  Fixtures/ArchitecturePresets/Sources/PresetDomain
//
//  Created by Dicky Darmawan on 03/10/26.
//

public struct Score: Equatable, Sendable {
  public private(set) var value: Int

  public init(value: Int = 0) {
    self.value = max(0, value)
  }

  public mutating func increment() {
    value += 1
  }
}
