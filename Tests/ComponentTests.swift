//
//  ComponentTests.swift
//  Tests
//
//  Created by Dicky Darmawan on 03/02/26.
//

import Testing
import SwiftUI
@testable import Swiftcn

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

    // MARK: - CNCard

    @Test("CNCard.Variant has all cases")
    func cardVariantsExist() {
        #expect(CNCard<AnyView>.Variant.allCases.count == 3)
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
