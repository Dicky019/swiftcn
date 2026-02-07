//
//  SDUISliderWrapper.swift
//  Sources/SDUI/Wrappers
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Wrapper for CNSlider that manages its own state in SDUI context
struct SDUISliderWrapper: View {
    let label: String
    let initialValue: Double
    let range: ClosedRange<Double>
    let step: Double?
    let sliderId: String?
    weak var actionHandler: SDUIActionHandler?

    @State private var value: Double

    init(label: String, initialValue: Double, range: ClosedRange<Double>, step: Double?, sliderId: String?, actionHandler: SDUIActionHandler?) {
        self.label = label
        self.initialValue = initialValue
        self.range = range
        self.step = step
        self.sliderId = sliderId
        self.actionHandler = actionHandler
        self._value = State(initialValue: initialValue)
    }

    var body: some View {
        if let step {
            CNSlider(label, value: $value, in: range, step: step)
                .onChange(of: value) { _, newValue in
                    if let sliderId {
                        actionHandler?.handleAction(id: sliderId, payload: ["value": newValue])
                    }
                }
        } else {
            CNSlider(label, value: $value, in: range)
                .onChange(of: value) { _, newValue in
                    if let sliderId {
                        actionHandler?.handleAction(id: sliderId, payload: ["value": newValue])
                    }
                }
        }
    }
}
