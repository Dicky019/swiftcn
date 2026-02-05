# swiftcn

A shadcn/ui inspired SwiftUI component library. **Not a framework** — Source/ contains template files that the CLI copies into user projects.

## Philosophy

This project follows shadcn/ui's core philosophy:

1. **Copy-paste, not install** - Components are copied into your project via CLI
2. **You own the code** - Full customization, no library dependency
3. **Edit directly** - No wrappers, no protocol overhead
4. **Beautiful defaults** - Design token system provides consistency

## Naming Convention: CN Prefix

All components use the `CN` prefix to avoid conflicts with native SwiftUI types:

| Component | SwiftUI Native | Conflict Avoided |
|-----------|----------------|------------------|
| CNButton | Button | ✅ |
| CNInput | TextField | ✅ |
| CNSwitch | Toggle | ✅ |
| CNSlider | Slider | ✅ |
| CNCard | - | N/A |
| CNBadge | - | N/A |

**Why CN?** References shadcn's iconic `cn()` classname utility.

## Project Structure

```
swiftcn/
├── Source/                          # Template files (copied by CLI, not a framework)
│   ├── Components/                  # UI Components (copy-paste ready)
│   │   ├── CNButton.swift           # Pure UI component
│   │   ├── CNButton+SDUI.swift      # SDUI Configuration (optional)
│   │   ├── CNCard.swift
│   │   ├── CNCard+SDUI.swift
│   │   ├── CNInput.swift
│   │   ├── CNInput+SDUI.swift
│   │   ├── CNBadge.swift
│   │   ├── CNBadge+SDUI.swift
│   │   ├── CNSwitch.swift
│   │   ├── CNSwitch+SDUI.swift
│   │   ├── CNSlider.swift
│   │   └── CNSlider+SDUI.swift
│   ├── Theme/                       # Theme management
│   │   ├── Core/                    # Fundamental types
│   │   │   ├── Theme.swift          # Codable theme model
│   │   │   ├── ThemeTokens.swift    # All token structs
│   │   │   └── Color+Hex.swift      # HEX parsing utility
│   │   ├── Palettes/                # Theme definitions
│   │   │   └── ThemeDefaults.swift  # Default Zinc palette
│   │   └── Provider/                # SwiftUI integration
│   │       ├── ThemeProvider.swift  # @Observable state manager
│   │       ├── ThemeEnvironment.swift
│   │       └── ResolvedTheme.swift
│   └── SDUI/                        # Server-Driven UI (optional)
│       ├── Core/
│       │   ├── AnyCodable.swift
│       │   ├── SDUINode.swift
│       │   └── SDUIError.swift
│       ├── Rendering/
│       │   ├── SDUIRenderer.swift
│       │   └── SDUIRegistry.swift
│       ├── Actions/
│       │   └── SDUIActionHandler.swift
│       └── Wrappers/
│           ├── SDUIInputWrapper.swift
│           ├── SDUISwitchWrapper.swift
│           └── SDUISliderWrapper.swift
├── CLI/                             # CLI tool (Node.js + TypeScript)
│   ├── src/
│   │   ├── index.ts                 # CLI entry point
│   │   ├── commands/
│   │   │   ├── init.ts              # Initialize project
│   │   │   ├── add.ts               # Add component
│   │   │   └── list.ts              # List components
│   │   ├── config/
│   │   │   ├── types.ts             # Project config types
│   │   │   └── loader.ts            # Config loader
│   │   ├── registry/
│   │   │   ├── types.ts             # Registry types
│   │   │   └── loader.ts            # Registry loader
│   │   └── utils/
│   │       ├── ui.ts                # Terminal UI utilities
│   │       └── fetcher.ts           # File fetcher
│   ├── registry.json                # Component manifest
│   ├── package.json
│   └── tsconfig.json
├── Example/                         # Example iOS app
├── Tests/                           # Unit tests
├── docs/
│   └── plans/
├── LICENSE                          # MIT License
├── SECURITY.md                      # Security policy
├── CONTRIBUTING.md                  # Contribution guidelines
├── CODE_OF_CONDUCT.md               # Community guidelines
└── README.md                        # Project overview
```

## Component Pattern

Components follow the extension file pattern:

- **Base file** (`CNButton.swift`) - Pure SwiftUI component, no SDUI dependencies
- **SDUI extension** (`CNButton+SDUI.swift`) - Optional Configuration struct for SDUI

```swift
// CNButton.swift - Pure UI
public struct CNButton: View {
    public enum Size { case sm, md, lg }
    public enum Variant { case `default`, destructive, outline, secondary, ghost, link }

    public init(_ label: String, size: Size = .md, variant: Variant = .default, action: @escaping () -> Void)
}

// CNButton+SDUI.swift - SDUI extension (optional)
extension CNButton {
    public struct Configuration: Codable, Sendable, Hashable {
        public let label: String
        public let size: Size
        public let variant: Variant
        public let actionId: String?
    }
}
```

## Architecture

Source/ is **not** built as a framework. Instead, Example/ and Tests/ include Source/ directly via Tuist's `buildableFolders`. This mirrors how users will use the components — copied directly into their project, no import needed.

## Commands

```bash
# Generate Xcode project
tuist generate

# Build (via xcodebuild)
xcodebuild -workspace Swiftcn.xcworkspace -scheme Example build

# Test
xcodebuild -workspace Swiftcn.xcworkspace -scheme Example test

# Run CLI (Node.js)
cd CLI && npm run build
node dist/index.js list
node dist/index.js add button
node dist/index.js add button --sdui --theme
node dist/index.js init

# Or use npx (when published)
npx swiftcn@latest init
npx swiftcn@latest add button
npx swiftcn@latest list
```

## Design Tokens

Theme-based token system:

- **Theme/Core/** - Fundamental types (Theme, ThemeTokens, Color+Hex)
- **Theme/Palettes/** - Theme definitions (default Zinc, extensible)
- **Theme/Provider/** - SwiftUI integration (ThemeProvider, Environment, ResolvedTheme)

Components consume tokens via `@Environment(\.theme)`.

## Swift File Header

All Swift files must use this header format:

```swift
//
//  <FileName>.swift
//  <RelativePath>
//
//  Created by Dicky Darmawan on <dd/mm/yy>.
//
```

## Tech Stack

- Swift 6 with strict concurrency
- SwiftUI (iOS 17+)
- Tuist for project generation (no Package.swift)
- @Observable for theme management
- CLI: Node.js 20+, TypeScript, Commander.js, @clack/prompts
