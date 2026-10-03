# Sources

Canonical template files served by the CLI. These files are **not compiled directly** — they are copied into user projects via `npx swiftcn add`.

## Structure

```
Sources/
├── Components/          # UI Components
│   ├── CNButton.swift
│   ├── CNButton+SDUI.swift
│   ├── CNCard.swift
│   ├── CNCard+SDUI.swift
│   ├── CNInput.swift
│   ├── CNInput+SDUI.swift
│   ├── CNBadge.swift
│   ├── CNBadge+SDUI.swift
│   ├── CNSwitch.swift
│   ├── CNSwitch+SDUI.swift
│   ├── CNSlider.swift
│   └── CNSlider+SDUI.swift
├── Theme/               # Design token system
│   ├── Core/            # Theme model, tokens, Color+Hex
│   ├── Palettes/        # Theme definitions (default Zinc)
│   └── Provider/        # ThemeProvider, Environment, ResolvedTheme
├── Navigation/          # Optional typed SwiftUI navigation
│   └── Router.swift
├── OfflineFirst/        # Optional external-system-agnostic sync
│   ├── SyncTypes.swift
│   ├── RetryPolicy.swift
│   └── SyncCoordinator.swift
└── SDUI/                # Server-Driven UI (optional)
    ├── Core/            # SDUINode, AnyCodable, SDUIError
    ├── Rendering/       # SDUIRenderer, SDUIRegistry
    └── Actions/         # SDUIActionHandler
```

`Navigation/Router.swift` is a nonvisual optional template. Native/MVVM install
it with `swiftcn init --navigation` or `swiftcn add navigation`. TCA uses
reducer-owned navigation instead. `Sources/` remains the canonical source
for every template.

`swiftcn init --offline-first` copies the same three `OfflineFirst/` files
for every preset, beside the configured components directory. They provide
sync outcomes, a retry policy, and one scoped single-flight coordinator.
Your feature owns the worker, local persistence, durable outbox, reconciliation,
and external gateway. See [Offline-First integration](../docs/offline-first.md).
Disabling a capability only updates config; copied code belongs to the user.

## Component Pattern

Each component has two files:

- **Base file** (`CNButton.swift`) — Pure SwiftUI component, no SDUI dependency
- **SDUI extension** (`CNButton+SDUI.swift`) — Optional `Configuration` struct for server-driven rendering

The `--sdui` flag on `swiftcn add` controls whether the extension file is included.

```swift
let registry = SDUIRegistry.shared
registry.registerCNButton()
registry.registerCNSlider()
```

SDUI core installs independently. Each `CNComponent+SDUI.swift` file owns
that component's state wrapper, wire-property parsing, and explicit registry
method. Call each installed component's registration method once during app
startup.

## Theme Setup

```swift
@State private var themeProvider = ThemeProvider()

ContentView()
    .environment(themeProvider)
    .withThemeTracking(themeProvider)
```

`Theme` is the Codable transport value, `ThemeProvider` owns main-actor UI state,
and components synchronously read `ResolvedTheme` from `@Environment(\.theme)`.

## Editing Templates

After editing files here, sync to the Example app (`Example/App/`):

```bash
./scripts/sync-source.sh
```

The CLI reads from this directory at runtime (via git clone), so changes here are what users receive.
