// swift-tools-version: 6.1
//
//  Package.swift
//  Fixtures/ArchitecturePresets
//
//  Created by Dicky Darmawan on 03/10/26.
//

import PackageDescription

let package = Package(
  name: "ArchitecturePresets",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "NativePreset", targets: ["NativePreset"]),
    .library(name: "MVVMPreset", targets: ["MVVMPreset"]),
    .library(name: "TCAPreset", targets: ["TCAPreset"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      exact: "1.26.1"
    )
  ],
  targets: [
    .target(name: "PresetDomain"),
    .target(name: "PresetApplication", dependencies: ["PresetDomain"]),
    .target(name: "PresetNavigation"),
    .target(name: "NativePreset", dependencies: ["PresetApplication", "PresetNavigation"]),
    .target(name: "MVVMPreset", dependencies: ["PresetApplication", "PresetNavigation"]),
    .target(name: "TCAPreset", dependencies: [
      "PresetApplication",
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    ]),
    .testTarget(name: "ArchitecturePresetTests", dependencies: [
      "NativePreset", "MVVMPreset", "TCAPreset"
    ])
  ],
  swiftLanguageModes: [.v6]
)
