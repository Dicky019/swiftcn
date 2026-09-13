# swiftcn

A shadcn/ui inspired SwiftUI component library. **Not a framework** — `Sources/` contains template files that the CLI copies into user projects.

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

```swift
let registry = SDUIRegistry.shared
registry.registerCNButton()
registry.registerCNSlider()
```

SDUI core installs independently. Each `CNComponent+SDUI.swift` file owns
that component's state wrapper, wire-property parsing, and explicit registry
method. Call each installed component's registration method once during app
startup.

## Architecture

`Sources/` is the **canonical template directory** — the CLI serves files from here, but it is never compiled directly. `Example/` is fully self-contained with its own `Project.swift`: source files are synced into `Example/App/` (via `scripts/sync-source.sh`), living alongside the app code — just like a real user project after running `npx swiftcn add`. Tuist's `buildableFolders` compiles `App/` for the Example target (paths relative to `Example/`). No imports needed — types resolve within the same compilation unit.

## Directory Guide

| Path | Purpose |
|------|---------|
| `Sources/Components/` | Canonical SwiftUI component templates and their optional SDUI extensions. |
| `Sources/Theme/` | Canonical theme models, palettes, tokens, and SwiftUI environment integration. |
| `Sources/SDUI/` | Canonical server-driven UI models, actions, registry, and renderer. |
| `CLI/src/` | TypeScript CLI commands, services, schemas, and utilities. |
| `CLI/src/__tests__/` | Vitest coverage for the CLI, organized to mirror `CLI/src/`. |
| `Example/App/` | Tuist-managed demo app plus synced copies of templates from `Sources/`. |
| `Example/App/Features/` | Demo-only screens and models for components, themes, settings, and SDUI. |
| `Example/Tests/` | Swift Testing suites and fixtures for the demo app and copied templates. |
| `.maestro/` | Maestro end-to-end flows and reusable mobile test subflows. |
| `scripts/` | Shared sync, test, E2E, and publishing scripts. |
| `docs/` | Project plans and supporting development documentation. |

Generated folders such as `.build/`, `derivedData/`, and `Example/Derived/` are build artifacts. Do not treat them as source or commit them.

## Commands

```bash
# Generate Xcode project (run from Example/)
cd Example && tuist generate

# Build (via xcodebuild, from project root)
xcodebuild -workspace Example/Example.xcworkspace -scheme Example build

# Test (via scripts)
./scripts/test-all.sh               # Run all tests (CLI + Example)
./scripts/test-example.sh           # Example tests only
./scripts/test-cli.sh               # CLI tests only

# Test with custom simulator
./scripts/test-example.sh "platform=iOS Simulator,name=iPhone 17 Pro"

# Sync Sources/ → Example/App/ after editing templates
./scripts/sync-source.sh
./scripts/sync-source.sh --dry-run  # Preview changes

# Run CLI (Node.js)
cd CLI && npm run build
node dist/index.js list
node dist/index.js add button
node dist/index.js add button -f
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
//  Created by <git user.name> on <dd/mm/yy>.
//
```

## Gotchas

- **Tuist `buildableFolders` paths are relative to `Project.swift` location**, not repo root
- **No root Project.swift or Workspace.swift** — run `tuist generate` from `Example/`
- **After editing Sources/, always run `./scripts/sync-source.sh`** — `Example/App/` has copies, not symlinks
- **`rsync --delete` in sync script** — only syncs `Components/`, `Theme/`, and `SDUI/` subdirectories into `App/`
- **CLI `SOURCE_PATH`** in `CLI/src/utils/constants.ts` points to root `Sources/` — keep in sync if renamed

## Subdirectory READMEs

- `Example/README.md` — Setup, build, test instructions for the demo app
- `CLI/README.md` — Install, commands, development, architecture
- `Sources/README.md` — Template file overview and editing workflow

## Coding Conventions

- Use two-space indentation in Swift and TypeScript, following nearby files.
- Swift targets version 6 with complete strict concurrency.
- Preserve standard Swift file headers, `MARK` sections, semantic design tokens, and accessibility modifiers.
- TypeScript uses strict mode and ES modules. Use `PascalCase` for types and classes, and `camelCase` for functions and variables.
- Keep diffs consistent with nearby code; no repository-wide formatter is configured.

## Testing Guidelines

- Use Swift Testing (`@Suite`, `@Test`, `#expect`) in files named `*Tests.swift`.
- Name Vitest files `*.test.ts` beneath `CLI/src/__tests__/`.
- Add focused regression coverage for changed behavior.
- Run the smallest relevant test first, then `./scripts/test-all.sh` before opening a PR.
- Use Maestro for user-visible SDUI workflows.

## Commit and Pull Request Guidelines

- Use Conventional Commits such as `feat(sdui): ...`, `fix(button): ...`, `test(sdui): ...`, or `docs: ...`.
- Keep commits focused and imperative.
- Open PRs against `main` with a concise problem/solution summary, linked issue or discussion, and test results.
- Include screenshots or recordings for visual changes.
- Discuss new features before implementation.
- Never commit generated workspaces, build output, dependencies, or secrets.

## Tech Stack

- Swift 6 with strict concurrency
- SwiftUI (iOS 17+)
- Tuist for project generation (no Package.swift)
- @Observable for theme management
- CLI: Node.js 20+, TypeScript, Commander.js, @clack/prompts
