//
//  Project.swift
//  swiftcn
//
//  Created by Dicky Darmawan on 03/02/26.
//

import ProjectDescription

let project = Project(
    name: "Swiftcn",
    organizationName: "Dicky Darmawan",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        // MARK: - Example (iOS App)
        // Includes Source/ directly - no framework dependency
        // This demonstrates how components work when copied to a project
        .target(
            name: "Example",
            destinations: .iOS,
            product: .app,
            bundleId: "com.swiftcn.Example",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": ""
                    ],
                    "UISupportedInterfaceOrientations": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ],
                    "UISupportedInterfaceOrientations~ipad": [
                        "UIInterfaceOrientationPortrait",
                        "UIInterfaceOrientationPortraitUpsideDown",
                        "UIInterfaceOrientationLandscapeLeft",
                        "UIInterfaceOrientationLandscapeRight"
                    ]
                ]
            ),
            buildableFolders: [
                "Source/",   // Components, Theme, SDUI (template files)
                "Example/"   // App-specific code
            ],
            dependencies: []
        ),

        // MARK: - Tests
        .target(
            name: "SwiftcnTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.swiftcn.SwiftcnTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: [
                "Source/",   // Test the template files directly
                "Tests/"
            ],
            dependencies: []
        )
    ],
    schemes: [
        .scheme(
            name: "Example",
            buildAction: .buildAction(targets: ["Example"]),
            testAction: .targets(["SwiftcnTests"]),
            runAction: .runAction(executable: "Example")
        )
    ]
)
