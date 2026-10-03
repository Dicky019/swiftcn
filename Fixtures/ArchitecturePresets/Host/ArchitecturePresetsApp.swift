//
//  ArchitecturePresetsApp.swift
//  Fixtures/ArchitecturePresets/Host
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ComposableArchitecture
import MVVMPreset
import NativePreset
import SwiftUI
import TCAPreset

@main
struct ArchitecturePresetsApp: App {
  var body: some Scene {
    WindowGroup {
      TabView {
        NativeRootView().tabItem { Label("Native", systemImage: "swift") }
        MVVMRootView().tabItem { Label("MVVM", systemImage: "rectangle.stack") }
        TCAAppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
          .tabItem { Label("TCA", systemImage: "arrow.triangle.branch") }
      }
    }
  }
}
