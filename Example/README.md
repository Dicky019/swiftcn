# Example App

Self-contained demo app showcasing all swiftcn components. This mirrors how a real user project looks after running `npx swiftcn add` — components, theme, and SDUI files live directly in `App/` alongside your app code.

## Prerequisites

- Xcode 16+ (Swift 6)
- [Tuist](https://docs.tuist.dev/guides/quick-start/install-tuist)

## Setup

```bash
# From the Example/ directory
tuist generate
```

This generates `Example.xcworkspace`. Open it in Xcode or build from the command line.

## Build

```bash
xcodebuild -workspace Example.xcworkspace -scheme Example build
```

## Test

```bash
xcodebuild -workspace Example.xcworkspace -scheme Example test
```

### E2E Testing with Maestro

The Example app includes automated E2E tests powered by [Maestro](https://docs.maestro.dev):

```bash
# Run all E2E flows
./scripts/test-e2e.sh

# Or run a specific flow
maestro test .maestro/sdui-ecommerce-checkout.yaml
maestro test .maestro/sdui-template-picker.yaml
maestro test .maestro/sdui-json-editor.yaml
maestro test .maestro/sdui-stress-test.yaml
maestro test .maestro/sdui-tabs-toggle-stress.yaml
```

## Structure

```
Example/
├── Project.swift       # Tuist manifest
├── swiftcn.json        # CLI config (component install paths)
├── App/                # All compiled code (app + synced sources)
│   ├── App.swift       # @main entry point
│   ├── Components/     # CN components (synced from Sources/) + app helpers
│   ├── Theme/          # Design tokens & ThemeProvider (synced from Sources/)
│   ├── SDUI/           # Server-Driven UI engine (synced from Sources/)
│   ├── Features/       # Feature modules (Components, SDUI, Settings, Theme)
│   └── Navigation/     # Router, tabs, routes
└── Tests/              # Unit tests
    ├── ThemeTests.swift
    ├── ComponentTests.swift
    ├── TokenTests.swift
    └── Fixtures/
```

## Syncing Sources

Components, Theme, and SDUI in `App/` are copies of the root `Sources/` directory. After editing template files at the project root, sync them here:

```bash
# From the project root
./scripts/sync-source.sh

# Preview changes without applying
./scripts/sync-source.sh --dry-run
```
