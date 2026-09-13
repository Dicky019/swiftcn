//
//  Project.swift
//  Example/
//
//  Created by Dicky Darmawan on 03/02/26.
//

import ProjectDescription

let swiftLintScript: TargetScript = .pre(
    script: """
    if [[ "$(uname -m)" == arm64 ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
    else
        export PATH="/usr/local/bin:$PATH"
    fi

    if which swiftlint >/dev/null 2>&1; then
        cd "$SRCROOT/.."
        swiftlint lint --config .swiftlint.yml
    else
        echo "warning: SwiftLint not installed. Install via Homebrew: 'brew install swiftlint'"
    fi
    """,
    name: "Run SwiftLint",
    basedOnDependencyAnalysis: false
)

let project = Project(
    name: "Example",
    organizationName: "Dicky Darmawan",
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "DEVELOPMENT_TEAM": "6LKBYRNM9Y"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        // MARK: - Example (iOS App)
        // Example/ is self-contained: Sources/ has copied components, App/ has demo code
        // Mirrors how a real user project looks after `npx swiftcn add`
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
                "App/"      // App-specific code
            ],
            scripts: [
                swiftLintScript
            ],
            dependencies: []
        ),

        .target(
            name: "SDUICoreCompile",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.swiftcn.SDUICoreCompile",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: [
                "App/SDUI/"
            ],
            dependencies: [],
            settings: .settings(base: [
                "DEFINES_MODULE": "NO"
            ])
        ),

        // MARK: - Tests
        .target(
            name: "ExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.swiftcn.ExampleTests",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            buildableFolders: [
                "Tests/"    // Test files
            ],
            dependencies: [
                .target(name: "Example")
            ]
        )
    ],
    schemes: [
        .scheme(
            name: "Example",
            buildAction: .buildAction(targets: ["SDUICoreCompile", "Example"]),
            testAction: .targets(["ExampleTests"]),
            runAction: .runAction(executable: "Example")
        )
    ]
)
