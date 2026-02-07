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

Initialize swiftcn in your project. Creates a `swiftcn.json` config file and sets up the Sources directory.

```bash
swiftcn init
```

### `add <component>`

Add a component to your project. Copies the component source files into your configured directory.

```bash
swiftcn add button
swiftcn add button --sdui    # Include SDUI extension
swiftcn add button --theme   # Include theme files
```

### `list`

List all available components.

```bash
swiftcn list
```

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
│   ├── GitService.ts           # Git clone & cleanup
│   ├── FileService.ts          # File ops (copy, readJson, writeJson)
│   ├── RegistryService.ts      # Registry loading & component lookup
│   ├── ConfigService.ts        # swiftcn.json read/write
│   └── FetcherService.ts       # Shared fetch logic
├── types/                      # Centralized Zod schemas
│   ├── config.schema.ts
│   ├── registry.schema.ts
│   └── options.schema.ts
├── utils/
│   ├── ui.ts                   # Terminal UI (@clack/prompts)
│   ├── paths.ts                # Path sanitization
│   ├── errors.ts               # SwiftCNError + ErrorCode enum
│   └── constants.ts            # ALLOWED_REPO_URLS, SOURCE_PATH
└── __tests__/
    ├── services/               # Service unit tests
    └── utils/                  # Utility unit tests
```

Commands are thin orchestrators that receive a `Container` via factory functions. Services handle all business logic and are independently testable.
