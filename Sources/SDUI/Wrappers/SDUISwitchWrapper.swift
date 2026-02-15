//
//  SDUISwitchWrapper.swift
//  Sources/SDUI/Wrappers
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// Wrapper for CNSwitch that manages its own state in SDUI context
struct SDUISwitchWrapper: View {
  let label: String
  let initialValue: Bool
  let switchId: String?
  var actionHandler: SDUIActionHandler?

  @State private var isOn: Bool

  init(label: String, initialValue: Bool, switchId: String?, actionHandler: SDUIActionHandler?) {
    self.label = label
    self.initialValue = initialValue
    self.switchId = switchId
    self.actionHandler = actionHandler
    self._isOn = State(initialValue: initialValue)
  }

  var body: some View {
    CNSwitch(label, isOn: $isOn)
      .onChange(of: isOn) { _, newValue in
        if let switchId {
          actionHandler?.handleAction(id: switchId, payload: ["value": AnyCodable(newValue)])
        }
      }
      .onChange(of: initialValue) { _, newValue in
        isOn = newValue
      }
  }
}
