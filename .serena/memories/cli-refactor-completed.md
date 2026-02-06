# CLI Refactor Status

## Completed: 2026-02-07

The CLI was refactored from a flat structure to a Service-Based Architecture per `docs/plans/2026-02-06-cli-refactor-design.md`.

## Architecture

```
CLI/src/
├── index.ts                    # Entry point, creates container
├── container.ts                # DI container (createContainer, createTestContainer)
├── commands/                   # Thin orchestration layer
│   ├── init.ts                 # createInitCommand(container)
│   ├── add.ts                  # createAddCommand(container)
│   └── list.ts                 # createListCommand(container)
├── services/                   # Core business logic
│   ├── index.ts                # Re-exports
│   ├── GitService.ts           # Git clone, cleanup (uses ALLOWED_REPO_URLS)
│   ├── FileService.ts          # File ops (copy, readJson w/ Zod, writeJson)
│   ├── RegistryService.ts      # Registry loading/caching, component lookup
│   ├── ConfigService.ts        # swiftcn.json read/write/exists
│   └── FetcherService.ts       # Shared fetch logic (eliminates 3 duplicated fns)
├── types/                      # Centralized schemas
│   ├── index.ts
│   ├── config.schema.ts
│   ├── registry.schema.ts
│   └── options.schema.ts
├── utils/
│   ├── ui.ts                   # Terminal UI (unchanged per constraint)
│   ├── paths.ts                # Path sanitization
│   ├── errors.ts               # SwiftCNError + ErrorCode enum
│   └── constants.ts            # ALLOWED_REPO_URLS, SOURCE_PATH, etc.
└── __tests__/
    ├── utils/                  # paths.test.ts, errors.test.ts
    └── services/               # All 5 service test files
```

## Key Patterns

- Commands receive `Container` via factory functions: `createInitCommand(container)`
- Services have interface + Impl pattern for testability
- `FetcherService` has a private `fetchFiles()` method that replaces 3 duplicated functions
- `FileService.readJson` uses `ZodType<T, ZodTypeDef, unknown>` to handle schemas with `.default()`
- `RegistryService` caches the parsed registry after first load
- `GitService` validates URLs against `ALLOWED_REPO_URLS` constant

## Deleted Files

- `src/utils/fetcher.ts` → FetcherService
- `src/config/loader.ts` → ConfigService
- `src/config/types.ts` → types/config.schema.ts
- `src/registry/loader.ts` → RegistryService
- `src/registry/types.ts` → types/registry.schema.ts

## Test Coverage

55 tests across 7 files. All passing.
