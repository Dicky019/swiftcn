# swiftcn Foundation Hardening Design

**Date:** 2026-09-11

## Goal

Harden swiftcn's existing copy-paste architecture before adding new foundation abstractions. Keep the current `Theme -> ThemeProvider -> ResolvedTheme -> Environment` flow, make CLI installation safe and reproducible, and make optional SDUI compile without requiring every CN component.

## Context

swiftcn is not a Swift Package or binary framework. `Sources/` contains canonical templates, the CLI copies those templates into an application's source tree, and `Example/App/` is a synchronized consumer fixture. Architecture changes therefore have to preserve both the Swift runtime contract and the CLI distribution contract.

The existing theme architecture already keeps immutable data in `Sendable` structs and mutable UI state in a main-actor `@Observable` provider. Rendering consumes a synchronous `ResolvedTheme` value from SwiftUI's environment. No actor or `await` is needed for token reads in `View.body`.

## Global Requirements

- Swift 6 language mode with complete strict concurrency checking.
- iOS 17.0 or newer.
- macOS 14.0 or newer where the templates support macOS.
- Xcode 16 or newer.
- Swift template core uses Apple platform frameworks only; no third-party Swift dependency.
- Components remain copy-paste owned source, not a binary framework.
- Existing public `CN` component names remain unchanged.
- Canonical Swift edits happen under `Sources/`, followed by `./scripts/sync-source.sh`.
- New non-trivial behavior is introduced test-first.
- Preserve user-owned files unless the user explicitly supplies a force option.

## Accepted Architecture

### Distribution boundary

The CLI treats configured paths and registry file paths as untrusted input. Every resolved destination must remain inside the current project or the explicitly supplied destination directory. Copy errors stop the command. Registry metadata and source templates are fetched from the same version tag as the installed CLI.

### Theme boundary

`Theme` remains the Codable transport model with light and dark schemes represented as hexadecimal strings. `ThemeProvider` remains `@MainActor` because it owns observable UI state and `UserDefaults` interaction. `ResolvedTheme` remains the synchronous, `Sendable` SwiftUI color representation consumed by components.

`EnvironmentValues.theme` uses SwiftUI's `@Entry` macro. JSON hexadecimal strings are validated while decoding, before a theme can replace the current theme.

### SDUI boundary

The base SDUI registry only references native SwiftUI layout primitives. Each `CNComponent+SDUI.swift` file owns that component's wire-property parsing and an explicit `SDUIRegistry.registerCNComponent()` method. Installing SDUI without installing components therefore still compiles.

`AnyCodable` exposes typed accessors. Integer JSON values convert safely to `Double` where numeric UI values require a floating-point number. Action payloads use `[String: AnyCodable]` instead of `[String: Any]`.

## Non-goals

- Do not add `ColorPair`; it would duplicate `Theme.ColorScheme` and `ResolvedTheme` while losing the existing Codable transport model.
- Do not add `SwiftcnThemeMode`; retain `ColorSchemePreference`.
- Do not add fold or hinge geometry. Use `ViewThatFits`, size classes, and `Layout` inside concrete components when a demonstrated layout need appears.
- Do not add a generic Swift configuration or utility layer.
- Do not rewrite the CLI dependency-injection structure as part of this hardening work.
- Do not add a third-party package.

## Workstreams

1. `2026-09-11-cli-install-safety.md` makes installation contained, fail-fast, non-destructive, and version-pinned.
2. `2026-09-11-sdui-modular-contracts.md` makes SDUI independently compilable and aligns its wire contracts.
3. `2026-09-11-theme-foundation.md` validates theme input and adopts `@Entry` without changing the runtime flow.

Each workstream can ship independently. The recommended execution order is CLI safety, SDUI contracts, then theme modernization.

## Acceptance Criteria

- CLI paths containing `..` or absolute paths cannot write outside the project.
- A registry entry cannot read outside cloned `Sources/` or write outside its destination.
- Any failed file copy fails the command.
- `swiftcn init` skips existing theme and SDUI files unless `--force` is passed.
- Registry metadata and cloned source use `v<CLI_VERSION>`.
- SDUI core compiles with zero CN components installed.
- Integer JSON spacing and slider values are honored.
- Invalid slider ranges produce an invalid-component view rather than a runtime trap.
- Component SDUI parsing lives with the component's `+SDUI` file.
- Invalid theme HEX values fail decoding and leave the active theme unchanged.
- `EnvironmentValues.theme` is declared with `@Entry`.
- Existing component call sites continue reading `@Environment(\.theme)` unchanged.
