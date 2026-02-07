# swiftcn

A shadcn/ui inspired SwiftUI component library. **Not a framework** — Sources/ contains template files that the CLI copies into user projects.

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
├── Sources/                          # Canonical templates (CLI serves from here, NOT compiled)
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
├── Example/                         # Self-contained demo app (has its own Project.swift)
│   ├── Project.swift                # Tuist manifest (run `tuist generate` from here)
│   ├── swiftcn.json                 # CLI config (component install paths)
│   ├── App/                         # All compiled code (app + synced sources)
│   │   ├── App.swift                # @main entry point
│   │   ├── Components/              # CN components (synced) + app helpers (InfoRow)
│   │   ├── Theme/                   # ← synced from Sources/Theme/
│   │   ├── SDUI/                    # ← synced from Sources/SDUI/
│   │   ├── Features/
│   │   │   ├── Components/          # Component gallery & showcases
│   │   │   │   ├── Models/
│   │   │   │   ├── Views/
│   │   │   │   └── Components/      # ComponentCard + Showcases/
│   │   │   ├── SDUI/                # SDUI playground
│   │   │   │   ├── Models/
│   │   │   │   └── Views/
│   │   │   └── Settings/            # Theme & preferences
│   │   │       ├── Components/
│   │   │       ├── ViewModels/
│   │   │       └── Views/
│   │   └── Navigation/
│   │       ├── AppRoute.swift
│   │       ├── AppRouter.swift
│   │       ├── ComponentRoute.swift
│   │       └── MainTabView.swift
│   └── Tests/                       # Unit tests
│       ├── ThemeTests.swift
│       ├── ComponentTests.swift
│       ├── TokenTests.swift
│       └── Fixtures/
│           └── custom-theme.json
├── scripts/
│   ├── sync-source.sh               # Syncs Sources/ → Example/App/
│   ├── test-example.sh              # Runs Example unit tests (xcodebuild)
│   ├── test-cli.sh                  # Runs CLI unit tests (Vitest)
│   └── test-all.sh                  # Runs all tests (CLI + Example)
├── CLI/                             # CLI tool (Node.js + TypeScript)
│   ├── src/
│   │   ├── index.ts                 # CLI entry point
│   │   ├── container.ts             # DI container
│   │   ├── commands/
│   │   │   ├── init.ts              # Initialize project
│   │   │   ├── add.ts               # Add component
│   │   │   └── list.ts              # List components
│   │   ├── services/                # Core business logic
│   │   │   ├── index.ts             # Re-exports
│   │   │   ├── GitService.ts        # Git clone & cleanup
│   │   │   ├── FileService.ts       # File ops (copy, readJson, writeJson)
│   │   │   ├── RegistryService.ts   # Registry loading & component lookup
│   │   │   ├── ConfigService.ts     # swiftcn.json read/write
│   │   │   └── FetcherService.ts    # Shared fetch logic
│   │   ├── types/                   # Centralized Zod schemas
│   │   │   ├── index.ts
│   │   │   ├── config.schema.ts
│   │   │   ├── registry.schema.ts
│   │   │   └── options.schema.ts
│   │   ├── utils/
│   │   │   ├── ui.ts                # Terminal UI (@clack/prompts)
│   │   │   ├── paths.ts             # Path sanitization
│   │   │   ├── errors.ts            # SwiftCNError + ErrorCode enum
│   │   │   └── constants.ts         # ALLOWED_REPO_URLS, SOURCE_PATH
│   │   └── __tests__/               # Unit tests (Vitest)
│   │       ├── services/            # 5 service test files
│   │       └── utils/               # paths, errors tests
│   ├── registry.json                # Component manifest
│   ├── package.json
│   ├── tsconfig.json
│   └── vitest.config.ts
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

Sources/ is the **canonical template directory** — the CLI serves files from here, but it is never compiled directly. Example/ is fully self-contained with its own `Project.swift`: source files are synced into `Example/App/` (via `scripts/sync-source.sh`), living alongside the app code — just like a real user project after running `npx swiftcn add`. Tuist's `buildableFolders` compiles `App/` for the Example target (paths relative to `Example/`). No imports needed — types resolve within the same compilation unit.

## Commands

```bash
# Generate Xcode project (run from Example/)
cd Example && tuist generate

# Build (via xcodebuild, from project root)
xcodebuild -workspace Example/Example.xcworkspace -scheme Example build

# Test (via scripts)
./scripts/test-all.sh               # Run all tests (CLI + Example)
./scripts/test-example.sh            # Example tests only
./scripts/test-cli.sh                # CLI tests only

# Test with custom simulator
./scripts/test-example.sh "platform=iOS Simulator,name=iPhone 17 Pro"

# Sync Sources/ → Example/App/ after editing templates
./scripts/sync-source.sh
./scripts/sync-source.sh --dry-run  # Preview changes

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

## Gotchas

- **Tuist `buildableFolders` paths are relative to `Project.swift` location**, not repo root
- **No root Project.swift or Workspace.swift** — run `tuist generate` from `Example/`
- **After editing Sources/, always run `./scripts/sync-source.sh`** — Example/App/ has copies, not symlinks
- **`rsync --delete` in sync script** — only syncs Components/, Theme/, SDUI/ subdirs into App/
- **CLI `SOURCE_PATH`** in `CLI/src/utils/constants.ts` points to root `Sources/` — keep in sync if renamed

## Subdirectory READMEs

- `Example/README.md` — Setup, build, test instructions for the demo app
- `CLI/README.md` — Install, commands, development, architecture
- `Sources/README.md` — Template file overview and editing workflow

## Tech Stack

- Swift 6 with strict concurrency
- SwiftUI (iOS 17+)
- Tuist for project generation (no Package.swift)
- @Observable for theme management
- CLI: Node.js 20+, TypeScript, Commander.js, @clack/prompts
