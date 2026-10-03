# swiftcn

Beautifully designed SwiftUI components. Open source. Copy and paste into your apps.

> **Inspired by [shadcn/ui](https://ui.shadcn.com)** — This is not a component library. It's how you build your component library.

## Introduction and Motivation

swiftcn is the home for the features and core capabilities I build in production projects. The long-term goal is to bring all of that work into this repository as reusable code, so I can easily clone the repository or copy the pieces I need into another project without rebuilding them from scratch.

This goal extends beyond UI components to feature implementations, architecture patterns, and core application infrastructure. Each contribution should be easy to copy, adapt, and use independently in another project, following the project's existing code ownership and CLI template approach.

## Documentation

Visit [swiftcn.dev/docs](https://swiftcn.dev/docs) for full documentation.

## Quick Start

```bash
# Initialize in your project
npx swiftcn@latest init

# Add components
npx swiftcn@latest add button
npx swiftcn@latest add button --sdui
npx swiftcn@latest add navigation

# List available components
npx swiftcn@latest list
```

Or install globally:

```bash
npm install -g swiftcn
swiftcn init
swiftcn add button
```

## Architecture Presets

Configure an existing SwiftUI app with Native, MVVM, or TCA while keeping
Domain and Application independent of presentation and infrastructure:

```bash
swiftcn init --preset native -y
swiftcn init --preset mvvm --navigation -y
swiftcn init --preset tca --navigation --offline-first -y
```

Native and MVVM navigation use the existing Router; TCA owns navigation in
reducer state. Offline-First installs three shared sync files for any preset.
Your feature supplies the durable local store, outbox and external gateway.
Reruns preserve existing selections; disabling a capability leaves owned files intact.
Init does not edit app entry points or project manifests, generate sample features,
or install TCA. TCA recipes require Swift 6.1+ and TCA 1.26.1.

See [architecture recipes](docs/architecture-presets.md) and
[Offline-First integration](docs/offline-first.md).

## Theme Setup

```swift
@State private var themeProvider = ThemeProvider()

ContentView()
    .environment(themeProvider)
    .withThemeTracking(themeProvider)
```

`Theme` is the Codable transport value, `ThemeProvider` owns main-actor UI state,
and components synchronously read `ResolvedTheme` from `@Environment(\.theme)`.

## Components

| Component | Description |
|-----------|-------------|
| CNButton | Customizable button with size and variant options |
| CNCard | Container with rounded corners and shadow |
| CNInput | Text input with label and error states |
| CNSwitch | Toggle switch for boolean values |
| CNSlider | Range input control |
| CNBadge | Small status indicator badge |
| Router | Typed SwiftUI navigation state |

## Features

- **Copy-paste, not install** — Components are copied into your project via CLI
- **You own the code** — Full customization, no library dependency
- **Beautiful defaults** — Design token system provides consistency
- **SDUI Ready** — Optional Server-Driven UI support
- **Swift 6** — Full strict concurrency support
- **Accessibility** — Dynamic Type, Reduce Motion, VoiceOver support

For native MVVM navigation, tabs, deep links, restoration, and TCA guidance, see [Navigation](docs/navigation.md).

## Requirements

- Xcode 16+ (Swift 6)
- iOS 17+
- macOS 14+ (Sonoma)

## Development

The `Example/` directory is a self-contained iOS app that demonstrates all components. It has its own `Project.swift` and source files synced from `Sources/` into `App/` — just like a real user project after running `npx swiftcn add`.

See [Example/README.md](Example/README.md) for setup instructions.

After editing template files in `Sources/`, sync them to the Example app:

```bash
./scripts/sync-source.sh
```

### Testing

```bash
# Run all tests (CLI + Example)
./scripts/test-all.sh

# Run all tests including Maestro E2E
./scripts/test-all.sh --e2e
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

## Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a Pull Request.

## Community

For community-maintained components and templates, see [COMMUNITY_RESOURCES.md](COMMUNITY_RESOURCES.md).

## License

Licensed under the [MIT License](LICENSE).
