//
//  Project.swift
//  Fixtures/ArchitecturePresets
//
//  Created by Dicky Darmawan on 03/10/26.
//

import ProjectDescription

let project = Project(
  name: "ArchitecturePresets",
  packages: [.local(path: ".")],
  settings: .settings(base: [
    "SWIFT_VERSION": "6.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "CODE_SIGNING_ALLOWED": "NO"
  ]),
  targets: [
    .target(
      name: "ArchitecturePresetsHost",
      destinations: .iOS,
      product: .app,
      bundleId: "com.swiftcn.fixtures.architecture",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: ["UILaunchScreen": [:]]),
      sources: ["Host/**"],
      dependencies: [
        .package(product: "NativePreset"),
        .package(product: "MVVMPreset"),
        .package(product: "TCAPreset")
      ]
    ),
    .target(
      name: "ArchitecturePresetTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.swiftcn.fixtures.architecture.tests",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [.target(name: "ArchitecturePresetsHost")]
    )
  ],
  schemes: [
    .scheme(
      name: "ArchitecturePresets",
      buildAction: .buildAction(targets: ["ArchitecturePresetsHost"]),
      testAction: .targets(["ArchitecturePresetTests"])
    )
  ]
)
