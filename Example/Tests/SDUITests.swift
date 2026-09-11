//
//  SDUITests.swift
//  Tests
//
//  Created by Dicky Darmawan on 11/09/26.
//

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
}
