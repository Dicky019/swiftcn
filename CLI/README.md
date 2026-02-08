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

Initialize swiftcn in your project. Creates a `swiftcn.json` config file, installs theme files, and optionally sets up SDUI infrastructure.

```bash
swiftcn init                       # Interactive prompts
swiftcn init -y                    # Use defaults, skip prompts
swiftcn init --sdui                # Include SDUI infrastructure
swiftcn init -p Components         # Custom components path
swiftcn init --theme-path Theme    # Custom theme path
swiftcn init --sdui-path App/SDUI     # Custom SDUI path (implies --sdui)
```

| Option | Description | Default |
|--------|-------------|---------|
| `-p, --path <path>` | Path to components directory | `Components` |
| `--theme-path <path>` | Path to theme directory | `Theme` |
| `--sdui` | Include SDUI infrastructure | `false` |
| `--sdui-path <path>` | Path to SDUI directory (implies `--sdui`) | `SDUI` |
| `-y, --yes` | Skip prompts and use defaults | `false` |

### `add <component>`

Add a component to your project. Copies the component source files into your configured directory.

```bash
swiftcn add button               # Add a single component
swiftcn add button -f            # Overwrite existing files
swiftcn add button --no-sdui     # Skip SDUI extension file
swiftcn add button -f --no-sdui  # Force without SDUI
```

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --force` | Overwrite existing files | `false` |
| `--no-sdui` | Skip SDUI extension file | includes SDUI |

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
│   └── FetcherService.ts       # Shared fetch logic
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
