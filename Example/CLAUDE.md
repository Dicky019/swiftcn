# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the **Example app** subdirectory of the swiftcn project. See the parent `/CLAUDE.md` for full project context.

## What This Directory Is

Self-contained demo app showcasing swiftcn components. Mirrors how a real user project looks after `npx swiftcn add` — components, theme, and SDUI files live directly in `App/` alongside app code.

## Commands

All commands run from this `Example/` directory unless noted otherwise.

```bash
# Generate Xcode workspace (required before building)
tuist generate

# Build
xcodebuild -workspace Example.xcworkspace -scheme Example build

# Run all tests
xcodebuild -workspace Example.xcworkspace -scheme Example test \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" -quiet

# Run tests with specific simulator
xcodebuild test -workspace Example.xcworkspace -scheme Example \
  -destination "platform=iOS Simulator,name=iPhone 16"

# Alternative: use script from project root
../scripts/test-example.sh
../scripts/test-example.sh "platform=iOS Simulator,name=iPhone 16"
```

## Syncing Source Files

Components, Theme, and SDUI in `App/` are **copies** of the root `Sources/` directory. After editing template files at project root:

```bash
# From project root (NOT from Example/)
./scripts/sync-source.sh

# Preview changes first
./scripts/sync-source.sh --dry-run
```

## Key Paths

| Path | Purpose |
|------|---------|
| `Project.swift` | Tuist manifest |
| `swiftcn.json` | CLI config (component install paths) |
| `App/` | All compiled code (buildable folder) |
| `App/Components/` | CN components (synced from Sources/) |
| `App/Theme/` | Design tokens & ThemeProvider |
| `App/SDUI/` | Server-Driven UI engine |
| `App/Features/` | Feature modules (Components, SDUI, Settings) |
| `App/Navigation/` | NavController, BaseDestination, Destination, AppNavController |
| `Tests/` | Unit tests using Swift Testing framework |

## Testing

Uses Swift Testing framework (`import Testing`, `@Test`, `@Suite`). Tests are in the `ExampleTests` target.

```swift
@Suite("Component Tests")
struct ComponentTests {
  @Test("CNButton.Size has all cases")
  func buttonSizesExist() {
    #expect(CNButton.Size.allCases.count == 3)
  }
}
```

## Swift File Header

All Swift files must use this header format:

```swift
//
//  <FileName>.swift
//  Example
//
//  Created by Dicky Darmawan on <dd/mm/yy>.
//
```

**Exception**: Files in `App/Components/`, `App/Theme/`, and `App/SDUI/` use relative path instead of "Example":

```swift
//
//  CNButton.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on <dd/mm/yy>.
//
```

These are synced from `Sources/` — edit the original files there, not in `App/`.

## Code Formatting

- **Indentation**: Spaces, not tabs
- **Tab width**: 2 spaces
- **Indent width**: 2 spaces

## Gotchas

- **Always run `tuist generate` first** — the workspace doesn't exist until generated
- **Tuist `buildableFolders` paths are relative to `Project.swift`** — `App/` not `Example/App/`
- **Files in App/Components/, App/Theme/, App/SDUI/ are copies** — edit `Sources/` at project root, then sync
- **Don't edit synced files directly** — changes will be overwritten by `sync-source.sh`
