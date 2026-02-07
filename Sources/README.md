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
└── SDUI/                # Server-Driven UI (optional)
    ├── Core/            # SDUINode, AnyCodable, SDUIError
    ├── Rendering/       # SDUIRenderer, SDUIRegistry
    ├── Actions/         # SDUIActionHandler
    └── Wrappers/        # Input, Switch, Slider state wrappers
```

## Component Pattern

Each component has two files:

- **Base file** (`CNButton.swift`) — Pure SwiftUI component, no SDUI dependency
- **SDUI extension** (`CNButton+SDUI.swift`) — Optional `Configuration` struct for server-driven rendering

The `--sdui` flag on `swiftcn add` controls whether the extension file is included.

## Editing Templates

After editing files here, sync to the Example app (`Example/App/`):

```bash
./scripts/sync-source.sh
```

The CLI reads from this directory at runtime (via git clone), so changes here are what users receive.
