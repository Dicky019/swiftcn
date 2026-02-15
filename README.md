# swiftcn

Beautifully designed SwiftUI components. Open source. Copy and paste into your apps.

> **Inspired by [shadcn/ui](https://ui.shadcn.com)** — This is not a component library. It's how you build your component library.

## Documentation

Visit [swiftcn.dev/docs](https://swiftcn.dev/docs) for full documentation.

## Quick Start

```bash
# Initialize in your project
npx swiftcn@latest init

# Add components
npx swiftcn@latest add button
npx swiftcn@latest add button --sdui

# List available components
npx swiftcn@latest list
```

Or install globally:

```bash
npm install -g swiftcn
swiftcn init
swiftcn add button
```

## Components

| Component | Description |
|-----------|-------------|
| CNButton | Customizable button with size and variant options |
| CNCard | Container with rounded corners and shadow |
| CNInput | Text input with label and error states |
| CNSwitch | Toggle switch for boolean values |
| CNSlider | Range input control |
| CNBadge | Small status indicator badge |

## Features

- **Copy-paste, not install** — Components are copied into your project via CLI
- **You own the code** — Full customization, no library dependency
- **Beautiful defaults** — Design token system provides consistency
- **SDUI Ready** — Optional Server-Driven UI support with `components_*` routing
- **Swift 6** — Full strict concurrency support
- **Accessibility** — Dynamic Type, Reduce Motion, VoiceOver support
- **Programmatic Navigation** — Class-based destinations with duplicate prevention

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

## Contributing

Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a Pull Request.

## Community

For community-maintained components and templates, see [COMMUNITY_RESOURCES.md](COMMUNITY_RESOURCES.md).

## License

Licensed under the [MIT License](LICENSE).
