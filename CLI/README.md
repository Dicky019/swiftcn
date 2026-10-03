# swiftcn CLI

Command-line tool for adding swiftcn components to your SwiftUI project. Built with Node.js and TypeScript.

## Prerequisites

- Node.js 20+

## Install

```bash
npm install -g swiftcn
```

Or use directly with npx:

```bash
npx swiftcn@latest <command>
```

## Commands

### `init`

Configure an existing SwiftUI project. Init records an architecture preset,
installs theme files, and optionally adds navigation, Offline-First Core and SDUI.
It preserves app entry points, manifests, entitlements and existing features.

```bash
swiftcn init                       # Interactive prompts (preserves existing theme and SDUI files)
swiftcn init -y                    # Fresh defaults; preserve existing options on rerun
swiftcn init -f                    # Overwrite existing theme and SDUI files
swiftcn init --force               # Explicitly overwrite foundation files
swiftcn init --sdui                # Include SDUI infrastructure
swiftcn init -p Components         # Custom components path
swiftcn init --theme-path Theme    # Custom theme path
swiftcn init --sdui-path App/SDUI  # Custom SDUI path (implies --sdui)
swiftcn init --preset mvvm --navigation -y
swiftcn init --preset tca --navigation --offline-first -y
swiftcn init --no-navigation --no-offline-first -y
```

| Option | Description | Default |
|--------|-------------|---------|
| `--preset <native\|mvvm\|tca>` | Architecture ownership recipe | `native` |
| `--navigation` / `--no-navigation` | Enable/disable preset-appropriate navigation | `false` |
| `--offline-first` / `--no-offline-first` | Enable/disable shared sync core | `false` |
| `-p, --path <path>` | Path to components directory | `Components` |
| `--theme-path <path>` | Path to theme directory | `Theme` |
| `--sdui` | Include SDUI infrastructure | `false` |
| `--sdui-path <path>` | Path to SDUI directory (implies `--sdui`) | `SDUI` |
| `-f, --force` | Replace existing selected foundation files | `false` |
| `-y, --yes` | Skip prompts; preserve existing selections on rerun | `false` |

Defaults in the table apply to fresh projects. Configs written by older releases
default to Native with navigation and Offline-First disabled. Reruns preserve
omitted flags and paths; `--no-*` disables the capability in config without
deleting user-owned files. Changing preset warns that existing feature source
is not migrated. Without `--force`, existing files are skipped.

Native uses View-owned `@State`; MVVM uses an `@MainActor @Observable` ViewModel.
For both, navigation copies the exact `Navigation/Router.swift` registry item.
TCA owns `StackState`/`@Presents` and installs no Router. The TCA recipe requires
Swift 6.1+ and TCA 1.26.1, which you add to your project yourself.
See [compile-checked architecture recipes](../docs/architecture-presets.md).

Navigation and Offline-First directories sit beside `componentsPath`:
`App/Components` maps to `App/Navigation` and `App/OfflineFirst`. Theme and SDUI
use their independently configured paths. Offline-First copies only
`SyncTypes.swift`, `RetryPolicy.swift`, and `SyncCoordinator.swift`; a durable
local adapter and external gateway remain application responsibilities.
See [integration contracts](../docs/offline-first.md).

Init validates the selected files from one tagged registry/source snapshot,
stages them on the project filesystem, and writes config last by atomic rename.
Caught failures restore replaced files and remove created files. The next init
recovers an interrupted transaction before reading config or downloading files;
it refuses to interfere with another active transaction. This is recoverable
installation across files, rather than an atomic filesystem operation on the
whole project.

Init rejects reserved metadata/config paths and ambiguous destinations that
differ only in letter casing or Unicode normalization, including on
case-sensitive filesystems. Recovery keeps a live journal owner throughout
cleanup so another process cannot clean up a subsequent init transaction.

### `add <component>`

Add a component or optional feature to your project. Components are copied into the configured components directory; optional features may use their own project directory.

```bash
swiftcn add button               # Add a single component
swiftcn add button -f            # Overwrite existing files
swiftcn add button --no-sdui     # Skip SDUI extension file
swiftcn add navigation           # Add typed SwiftUI navigation
swiftcn add button -f --no-sdui  # Force without SDUI
```

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --force` | Overwrite existing files | `false` |
| `--no-sdui` | Skip SDUI extension file | includes SDUI |

```swift
let registry = SDUIRegistry.shared
registry.registerCNButton()
registry.registerCNSlider()
```

SDUI core installs independently. Each `CNComponent+SDUI.swift` file owns
that component's state wrapper, wire-property parsing, and explicit registry
method. Call each installed component's registration method once during app
startup.

### `list`

List all available components.

```bash
swiftcn list              # Compact list
swiftcn list -v           # Show variants, sizes, and SDUI info
swiftcn list --verbose    # Same as -v
```

| Option | Description | Default |
|--------|-------------|---------|
| `-v, --verbose` | Show detailed information | `false` |

## Available Components

| Component | Description |
|-----------|-------------|
| `button` | CNButton — customizable button with size and variant options |
| `card` | CNCard — container with rounded corners and shadow |
| `input` | CNInput — text input with label and error states |
| `switch` | CNSwitch — toggle switch for boolean values |
| `badge` | CNBadge — small status indicator badge |
| `slider` | CNSlider — range input control |
| `navigation` | Router — typed SwiftUI navigation state |

`swiftcn add navigation` installs `Navigation/Router.swift` into a `Navigation/` directory beside `componentsPath`. It does not change `swiftcn.json`.

TCA-configured projects reject `add navigation` with guidance to use
`StackState` and `@Presents` so navigation has a single owner.

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Watch mode
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Test coverage
npm run test:coverage

# Type check
npm run typecheck
```

## Architecture

Service-based architecture with dependency injection:

```
src/
├── index.ts                    # Entry point, creates container
├── container.ts                # DI container
├── commands/                   # Thin orchestration layer
│   ├── init.ts
│   ├── add.ts
│   └── list.ts
├── services/                   # Core business logic
│   ├── index.ts                # Re-exports
│   ├── GitService.ts           # Git clone & cleanup
│   ├── FileService.ts          # File ops (copy, readJson, writeJson)
│   ├── RegistryService.ts      # Registry loading & component lookup
│   ├── ConfigService.ts        # swiftcn.json read/write
│   ├── FetcherService.ts       # Component fetch logic
│   ├── InitService.ts          # One-snapshot init planning
│   └── FileTransactionService.ts # Staging, rollback and recovery
├── types/                      # Centralized Zod schemas
│   ├── index.ts
│   ├── config.schema.ts
│   ├── registry.schema.ts
│   └── options.schema.ts
├── utils/
│   ├── ui.ts                   # Terminal UI (@clack/prompts)
│   ├── paths.ts                # Path sanitization
│   ├── errors.ts               # SwiftCNError + ErrorCode enum
│   └── constants.ts            # ALLOWED_REPO_URLS, REGISTRY_URL, VERSION
└── __tests__/
    ├── commands/               # Command unit tests + helpers
    ├── services/               # Service unit tests
    ├── types/                  # Schema validation tests
    └── utils/                  # Utility unit tests
```

Commands are thin orchestrators that receive a `Container` via factory functions. Services handle all business logic and are independently testable. The registry is fetched from GitHub at runtime.

Published CLI version `x.y.z` reads registry and templates from Git tag `vx.y.z`.
The release script must create and push that tag before `npm publish`.
Unreleased Offline-First templates therefore require a release tag containing
the new manifest and sources; a locally built CLI never substitutes templates
from `main` when its version's tag lacks them.
