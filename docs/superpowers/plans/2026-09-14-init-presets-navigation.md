# Init Presets and Navigation Implementation Plan

**Status:** Completed 3 October 2026. [Implementation and verification record](../reports/2026-10-03-init-presets-offline-first.md).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add clean-architecture preset selection and preset-aware navigation to `swiftcn init`, with backward-compatible config and recoverable all-or-nothing file installation.

**Architecture:** Keep `init.ts` as prompt/output orchestration. A dedicated initializer reads the registry and templates from one tagged checkout, while a file transaction stages, journals, applies, and rolls back exact file mutations. Presets produce config and documented recipes; Native/MVVM reuse PR #7's Router, while TCA never installs it.

**Tech Stack:** Node.js 20+, TypeScript strict mode, Commander.js, Clack prompts, Zod, fs-extra, Vitest, Swift 6.1 fixture package, SwiftUI, Composable Architecture 1.26.1.

**Spec:** `docs/superpowers/specs/2026-09-14-init-presets-clean-architecture-design.md`

## Global Constraints

- Supported presets are exactly `native`, `mvvm`, and `tca`; fresh noninteractive init defaults to `native`.
- Native/MVVM navigation must install the existing `Sources/Navigation/Router.swift`; TCA navigation must use `StackState`/`@Presents` and install no Router.
- Existing config without new fields parses as `preset: "native"`, `navigation: false`, `offlineFirst: false`.
- Omitted rerun options preserve existing config; negated options explicitly disable config without deleting copy-owned source.
- Do not edit user `App.swift`, Xcode/Tuist/SPM manifests, target membership, entitlements, or existing feature source.
- Do not generate sample features, empty layers, base ViewModel protocols, service locators, or a runtime abstraction shared by the presets.
- All paths remain inside the project root, and all source paths remain inside the tagged checkout's `Sources/` directory.
- Swift templates use Swift 6 strict concurrency and iOS 17+; the TCA fixture pins 1.26.1 and requires Swift tools 6.1+.
- Preserve current theme, SDUI, skip, force, and copy-owned behavior.

---

## File Structure

### Create

- `CLI/src/services/InitService.ts` — read one tagged registry/source snapshot, map selected files to destinations, and invoke the transaction.
- `CLI/src/services/FileTransactionService.ts` — stage, journal, apply, rollback, and recover exact init mutations.
- `CLI/src/__tests__/services/InitService.test.ts` — source selection, destination mapping, one-clone behavior, and preflight validation.
- `CLI/src/__tests__/services/FileTransactionService.test.ts` — skip/replace, rollback, config-last, and stale-journal recovery.
- `docs/architecture-presets.md` — project-facing Native, MVVM, and TCA recipes, including PR #7 navigation ownership.
- `Fixtures/ArchitecturePresets/Package.swift` — compile/test harness with separate Clean Architecture modules and TCA 1.26.1.
- `Fixtures/ArchitecturePresets/Sources/PresetDomain/Score.swift` — pure domain value and invariant used only to verify recipes.
- `Fixtures/ArchitecturePresets/Sources/PresetApplication/IncrementScore.swift` — use case depending inward on `PresetDomain`.
- `Fixtures/ArchitecturePresets/Sources/NativePreset/NativeScoreView.swift` — View-owned `@State` recipe.
- `Fixtures/ArchitecturePresets/Sources/MVVMPreset/ScoreViewModel.swift` — `@MainActor @Observable` state/orchestration owner.
- `Fixtures/ArchitecturePresets/Sources/MVVMPreset/MVVMScoreView.swift` — render-only MVVM view.
- `Fixtures/ArchitecturePresets/Sources/TCAPreset/ScoreFeature.swift` — reducer/effect adapter around the use case.
- `Fixtures/ArchitecturePresets/Sources/TCAPreset/AppFeature.swift` — `StackState` and `@Presents` navigation ownership.
- `Fixtures/ArchitecturePresets/Tests/ArchitecturePresetTests/ArchitecturePresetTests.swift` — behavioral assertions for the three recipes.
- `scripts/test-architecture-presets.sh` — fixture build/test and forbidden-import gate.

### Modify

- `CLI/src/types/options.schema.ts` — architecture preset and tri-state navigation options.
- `CLI/src/types/config.schema.ts` — persisted preset/navigation/offline defaults.
- `CLI/src/types/index.ts` — export new init service types if required by callers.
- `CLI/src/services/index.ts` — export the two new services.
- `CLI/src/container.ts` — expose `initializer: InitService`.
- `CLI/src/utils/errors.ts` — add transaction-specific error codes without string matching.
- `CLI/src/__tests__/utils/errors.test.ts` — assert the new codes remain stable.
- `CLI/src/commands/init.ts` — prompts, merge rules, initializer call, help, warnings, and preset-specific next steps.
- `CLI/src/commands/add.ts` — refuse the native Router item for a TCA-configured project.
- `CLI/src/__tests__/types/options.schema.test.ts` — valid/invalid preset and tri-state flags.
- `CLI/src/__tests__/services/ConfigService.test.ts` — legacy defaults and new config round trip.
- `CLI/src/__tests__/commands/helpers.ts` — initializer mock and expanded sample configs.
- `CLI/src/__tests__/commands/init.test.ts` — preset/navigation matrix and rerun semantics.
- `CLI/src/__tests__/commands/add.test.ts` — TCA navigation refusal and legacy/native success.
- `CLI/README.md` — CLI flags and exact behavior.
- `README.md` — architecture preset overview and recipe link.
- `scripts/test-all.sh` — run the architecture fixture gate.

## Interfaces

```ts
export const ArchitecturePresetSchema = z.enum(["native", "mvvm", "tca"]);
export type ArchitecturePreset = z.infer<typeof ArchitecturePresetSchema>;

export interface InitFileRequest {
  sourcePath: string;
  destinationPath: string;
}

export interface InitTransactionInput {
  cwd: string;
  files: InitFileRequest[];
  config: ProjectConfig;
  force?: boolean;
}

export interface InitTransactionResult {
  added: string[];
  replaced: string[];
  skipped: string[];
}

export interface FileTransactionService {
  recover(cwd: string): Promise<void>;
  apply(input: InitTransactionInput): Promise<InitTransactionResult>;
}

export interface InitializeProjectInput {
  cwd: string;
  config: ProjectConfig;
  includeSdui: boolean;
  includeNavigationRouter: boolean;
  force?: boolean;
}

export interface InitService {
  initialize(input: InitializeProjectInput): Promise<InitTransactionResult>;
}
```

---

### Task 1: Add backward-compatible preset configuration

**Files:**

- Modify: `CLI/src/types/options.schema.ts`
- Modify: `CLI/src/types/config.schema.ts`
- Modify: `CLI/src/__tests__/types/options.schema.test.ts`
- Modify: `CLI/src/__tests__/services/ConfigService.test.ts`
- Modify: `CLI/src/__tests__/commands/helpers.ts`
- Modify: `Example/swiftcn.json`

**Interfaces:**

- Produces: `ArchitecturePresetSchema`, `ArchitecturePreset`, optional `InitOptions.preset`, optional `InitOptions.navigation`, and required defaulted `ProjectConfig.preset/navigation/offlineFirst`.

- [x] **Step 1: Write failing schema tests**

```ts
it.each(["native", "mvvm", "tca"])("accepts preset %s", (preset) => {
  expect(InitOptionsSchema.parse({ preset }).preset).toBe(preset);
});

it("rejects an unknown preset", () => {
  expect(() => InitOptionsSchema.parse({ preset: "viper" })).toThrow();
});

it("preserves an omitted navigation option as undefined", () => {
  expect(InitOptionsSchema.parse({}).navigation).toBeUndefined();
});

it("applies safe defaults to legacy config", () => {
  expect(projectConfigSchema.parse({ componentsPath: "Components" })).toEqual({
    componentsPath: "Components",
    prefix: "CN",
    preset: "native",
    navigation: false,
    offlineFirst: false,
  });
});
```

- [x] **Step 2: Run the focused tests and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/types/options.schema.test.ts src/__tests__/services/ConfigService.test.ts`

Expected: FAIL because preset/navigation/offline config fields do not exist.

- [x] **Step 3: Implement the schemas**

```ts
export const ArchitecturePresetSchema = z.enum(["native", "mvvm", "tca"]);

export const InitOptionsSchema = z.object({
  path: z.string().default("Components"),
  themePath: z.string().default("Theme"),
  sdui: z.boolean().optional(),
  sduiPath: z.string().default("SDUI"),
  preset: ArchitecturePresetSchema.optional(),
  navigation: z.boolean().optional(),
  offlineFirst: z.boolean().optional(),
  force: z.boolean().optional(),
  yes: z.boolean().optional(),
});

export const projectConfigSchema = z.object({
  componentsPath: z.string(),
  tokensPath: z.string().optional(),
  themePath: z.string().optional(),
  sduiPath: z.string().optional(),
  prefix: z.string().default("CN"),
  preset: ArchitecturePresetSchema.default("native"),
  navigation: z.boolean().default(false),
  offlineFirst: z.boolean().default(false),
});
```

Export `ArchitecturePreset` from the schema module and import the schema into `config.schema.ts`; do not duplicate the enum.

Update every typed `ProjectConfig` fixture and `Example/swiftcn.json` with explicit `preset: "native"`, `navigation: false`, and `offlineFirst: false`. Keep the legacy-default test as an untyped object passed directly to `projectConfigSchema.parse`.

- [x] **Step 4: Run focused tests and typecheck**

Run: `npm --prefix CLI test -- src/__tests__/types/options.schema.test.ts src/__tests__/services/ConfigService.test.ts`

Expected: PASS.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 5: Commit**

```bash
git add -- CLI/src/types/options.schema.ts CLI/src/types/config.schema.ts CLI/src/__tests__/types/options.schema.test.ts CLI/src/__tests__/services/ConfigService.test.ts CLI/src/__tests__/commands/helpers.ts Example/swiftcn.json
git commit -m "feat(cli): add architecture preset config"
```

---

### Task 2: Implement the recoverable file transaction

**Files:**

- Create: `CLI/src/services/FileTransactionService.ts`
- Create: `CLI/src/__tests__/services/FileTransactionService.test.ts`
- Modify: `CLI/src/services/index.ts`

**Interfaces:**

- Consumes: `ProjectConfig` from Task 1.
- Produces: `FileTransactionService.recover(cwd)` and `FileTransactionService.apply(input)` with the signatures in the plan-level interface block.

- [x] **Step 1: Write real-filesystem failing tests**

Use a fresh `fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-init-"))` per test and remove it in `afterEach`. Cover these exact cases:

In `beforeEach`, create two source files plus `firstDestination`/`secondDestination`, build `requests` from those paths, and use the Task 1 native config as `config`.

```ts
it("skips an existing file without force and writes config last", async () => {
  await fs.outputFile(path.join(cwd, "Theme.swift"), "owned");
  await service.apply({ cwd, files: requests, config, force: false });
  expect(await fs.readFile(path.join(cwd, "Theme.swift"), "utf8")).toBe("owned");
  expect(await fs.readJson(path.join(cwd, "swiftcn.json"))).toMatchObject(config);
});

it("restores every original when a later move fails", async () => {
  const originalMove = fs.move.bind(fs);
  let moveCount = 0;
  const move = vi.spyOn(fs, "move");
  move.mockImplementation(async (...args) => {
    moveCount += 1;
    if (moveCount === 2) throw new Error("disk full");
    return originalMove(...args);
  });
  await expect(service.apply({ cwd, files: requests, config, force: true })).rejects.toThrow("disk full");
  expect(await fs.readFile(firstDestination, "utf8")).toBe("original");
  expect(await fs.pathExists(secondDestination)).toBe(false);
});

it("recovers a stale applying journal before another init", async () => {
  await writeInterruptedFixture(cwd);
  await service.recover(cwd);
  expect(await fs.readFile(replacedDestination, "utf8")).toBe("original");
  expect(await fs.pathExists(createdDestination)).toBe(false);
});
```

`writeInterruptedFixture(cwd)` is a test helper in the same test file. It creates `.swiftcn-transaction/backup`, writes one replaced-file backup and one newly-created destination, then writes a version-1 `applying` journal with a deliberately dead `ownerPid` and the corresponding `backup-created`/`applied` entry states.

Also assert that an active journal whose owner PID is alive fails with `INIT_ALREADY_RUNNING`, and that every destination outside `cwd` is rejected before staging.

- [x] **Step 2: Run the focused test and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/services/FileTransactionService.test.ts`

Expected: FAIL because the service module does not exist.

- [x] **Step 3: Implement journal types and validation**

```ts
type MutationAction = "create" | "replace" | "skip";
type MutationState = "planned" | "backup-created" | "applied";

interface JournalEntry {
  destinationPath: string;
  stagedPath: string;
  backupPath?: string;
  action: MutationAction;
  state: MutationState;
}

interface TransactionJournal {
  version: 1;
  ownerPid: number;
  state: "staging" | "applying";
  entries: JournalEntry[];
}
```

The implementation owns these private helpers with no exported abstraction:

```ts
private stageEntries(input: InitTransactionInput): Promise<JournalEntry[]>;
private writeJournal(journal: TransactionJournal): Promise<void>;
private markJournal(entry: JournalEntry, state: MutationState): Promise<void>;
private moveOriginalToBackup(entry: JournalEntry): Promise<void>;
private rollback(entries: JournalEntry[]): Promise<void>;
```

Add `INIT_ALREADY_RUNNING` and `INIT_TRANSACTION_FAILED` to `ErrorCode`; use `PATH_TRAVERSAL` for destination escapes. Wrap apply/rollback failures in `INIT_TRANSACTION_FAILED` while preserving the original message as `cause`.

Use `<cwd>/.swiftcn-transaction/` for stage, backup, and `journal.json`. Validate all destination paths with `path.relative(cwd, destination)` and reject absolute/`..` escapes. Validate duplicate destinations before copying anything. A live `ownerPid` means another init is active; a dead owner is recoverable.

- [x] **Step 4: Implement stage/apply/rollback ordering**

Implement this exact order:

```ts
await this.recover(input.cwd);
await fs.ensureDir(stageDirectory);
const entries = await this.stageEntries(input);
await this.writeJournal({
  version: 1,
  ownerPid: process.pid,
  state: "applying",
  entries,
});

try {
  for (const entry of entries) {
    if (entry.action === "skip") continue;
    if (entry.action === "replace") await moveOriginalToBackup(entry);
    await markJournal(entry, entry.action === "replace" ? "backup-created" : "planned");
    await fs.ensureDir(path.dirname(entry.destinationPath));
    await fs.move(entry.stagedPath, entry.destinationPath, { overwrite: false });
    await markJournal(entry, "applied");
  }
  await fs.remove(transactionDirectory);
} catch (error) {
  await rollback([...entries].reverse());
  await fs.remove(transactionDirectory);
  throw error;
}
```

Append the staged `swiftcn.json` entry last and always classify it as create/replace, independent of `force`. Write both staged config and journal with temp-file-plus-rename. Recovery reverses `applied` creates, restores every backup, tolerates already-missing staged files, and never deletes an unjournaled path.

- [x] **Step 5: Run focused tests and typecheck**

Run: `npm --prefix CLI test -- src/__tests__/services/FileTransactionService.test.ts`

Expected: PASS for create, skip, replace, rollback, recovery, active-owner, and path-containment cases.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add -- CLI/src/services/FileTransactionService.ts CLI/src/services/index.ts CLI/src/utils/errors.ts CLI/src/__tests__/services/FileTransactionService.test.ts CLI/src/__tests__/utils/errors.test.ts
git commit -m "feat(cli): make init file writes recoverable"
```

---

### Task 3: Build one-snapshot init planning and installation

**Files:**

- Create: `CLI/src/services/InitService.ts`
- Create: `CLI/src/__tests__/services/InitService.test.ts`
- Modify: `CLI/src/services/index.ts`
- Modify: `CLI/src/container.ts`
- Modify: `CLI/src/__tests__/commands/helpers.ts`

**Interfaces:**

- Consumes: `FileTransactionService` and `ProjectConfig` from Tasks 1–2; existing `GitService`, `FileService`, `SOURCE_PATH`, and `SOURCE_REF`.
- Produces: `InitService.initialize(input)` and `Container.initializer`.

- [x] **Step 1: Write failing initializer tests**

```ts
it("clones once and installs theme plus the PR 7 router", async () => {
  const result = await initializer.initialize({
    cwd: "/project",
    config: nativeConfig,
    includeSdui: false,
    includeNavigationRouter: true,
  });
  expect(git.clone).toHaveBeenCalledTimes(1);
  expect(transaction.apply).toHaveBeenCalledWith(expect.objectContaining({
    files: expect.arrayContaining([
      expect.objectContaining({ destinationPath: "/project/Theme/Core/Theme.swift" }),
      expect.objectContaining({ destinationPath: "/project/Navigation/Router.swift" }),
    ]),
  }));
  expect(result.added).toBeDefined();
});

it("does not request Router for TCA navigation", async () => {
  await initializer.initialize({
    cwd: "/project",
    config: tcaNavigationConfig,
    includeSdui: false,
    includeNavigationRouter: false,
  });
  expect(transaction.apply).not.toHaveBeenCalledWith(expect.objectContaining({
    files: expect.arrayContaining([
      expect.objectContaining({ sourcePath: expect.stringContaining("Navigation/Router.swift") }),
    ]),
  }));
});
```

Also assert `App/Components` maps to sibling `App/Theme`, `App/SDUI`, and `App/Navigation`; invalid registry prefixes and missing source files fail before `transaction.apply`; cleanup runs after success and failure.

- [x] **Step 2: Run the focused test and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/services/InitService.test.ts`

Expected: FAIL because `InitService` does not exist.

- [x] **Step 3: Implement exact file selection**

Call `transaction.recover(cwd)` before network work. Then clone `ALLOWED_REPO_URLS[0]` at `SOURCE_REF` once. Read and validate `<checkout>/CLI/registry.json` with `registrySchema`, then build requests as follows:

```ts
const files = [
  ...registry.theme.core,
  ...registry.theme.palettes,
  ...registry.theme.provider,
].map((source) => this.mapPrefixed(sourceRoot, source, "Theme/", fullThemePath));

if (input.includeSdui && fullSduiPath) {
  files.push(
    ...[...registry.sdui.core, ...registry.sdui.wrappers]
      .map((source) => this.mapPrefixed(sourceRoot, source, "SDUI/", fullSduiPath))
  );
}

if (input.includeNavigationRouter) {
  const navigation = registry.components.navigation;
  if (!navigation || navigation.files.length !== 1 || navigation.files[0] !== "Navigation/Router.swift") {
    throw new SwiftCNError("Navigation registry must contain only Navigation/Router.swift", ErrorCode.REGISTRY_LOAD_FAILED);
  }
  files.push(this.mapPrefixed(
    sourceRoot,
    navigation.files[0],
    "Navigation/",
    fullNavigationPath
  ));
}
```

Define one private mapper and use it for every registry group:

```ts
private mapPrefixed(
  sourceRoot: string,
  source: string,
  prefix: string,
  destinationRoot: string
): InitFileRequest {
  if (!source.startsWith(prefix)) {
    throw new SwiftCNError(
      `Registry path must start with ${prefix}: ${source}`,
      ErrorCode.INVALID_INPUT
    );
  }
  return {
    sourcePath: resolveSecurePath(sourceRoot, source),
    destinationPath: resolveSecurePath(destinationRoot, source.slice(prefix.length)),
  };
}
```

`fullThemePath` and `fullSduiPath` resolve `config.themePath ?? "Theme"` and `config.sduiPath` inside `cwd`. `fullNavigationPath` is `resolveSecurePath(cwd, path.join(path.dirname(config.componentsPath), "Navigation"))`. Resolve every source against `<checkout>/Sources` and verify it exists before calling the transaction.

- [x] **Step 4: Wire the service into the container**

```ts
export interface Container {
  git: GitService;
  file: FileService;
  registry: RegistryService;
  config: ConfigService;
  fetcher: FetcherService;
  initializer: InitService;
}
```

Construct one `FileTransactionServiceImpl`, inject it into `InitServiceImpl`, and add an initializer mock returning `{ added: [], replaced: [], skipped: [] }` in command test helpers.

- [x] **Step 5: Run focused tests and typecheck**

Run: `npm --prefix CLI test -- src/__tests__/services/InitService.test.ts src/__tests__/commands/init.test.ts`

Expected: initializer tests PASS; existing init command tests may still use the old fetcher path until Task 4.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add -- CLI/src/services/InitService.ts CLI/src/services/index.ts CLI/src/container.ts CLI/src/__tests__/services/InitService.test.ts CLI/src/__tests__/commands/helpers.ts
git commit -m "feat(cli): plan init from one source snapshot"
```

---

### Task 4: Integrate preset and navigation UX into `init`

**Files:**

- Modify: `CLI/src/commands/init.ts`
- Modify: `CLI/src/__tests__/commands/init.test.ts`
- Modify: `CLI/src/index.ts`

**Interfaces:**

- Consumes: `Container.initializer`, `ArchitecturePreset`, and the defaulted config schema.
- Produces: `--preset`, `--navigation`, `--no-navigation`; idempotent config merge; Native/MVVM Router request; TCA next-step guidance.

- [x] **Step 1: Replace fetcher-oriented command assertions with failing behavior tests**

Add table-driven tests for all three presets and both navigation states:

```ts
it.each([
  ["native", true],
  ["mvvm", true],
  ["tca", false],
] as const)("maps %s navigation to Router=%s", async (preset, includeNavigationRouter) => {
  const container = await runInit(["--preset", preset, "--navigation", "-y"]);
  expect(container.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({
    includeNavigationRouter,
    config: expect.objectContaining({ preset, navigation: true }),
  }));
});
```

Add cases for fresh `-y` defaults, `--no-navigation`, unknown preset failing before initializer, legacy config, omitted options preserving existing values, explicit preset change warning, prompt cancellation before initializer, and no direct `fetchTheme`/`fetchSdui` call.

- [x] **Step 2: Run the command test and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/commands/init.test.ts`

Expected: FAIL because the options and initializer flow are not wired.

- [x] **Step 3: Register flags and merge config without losing omission state**

```ts
.option("--preset <preset>", "Architecture preset: native, mvvm, or tca")
.option("--navigation", "Include preset-appropriate navigation")
.option("--no-navigation", "Disable navigation in config without deleting files")
```

Load existing config before prompts. Use raw Commander values to distinguish omission from `false`:

```ts
const existing = await container.config.load(cwd);
const preset = options.preset ?? existing?.preset ?? "native";
const navigation = rawOptions.navigation ?? existing?.navigation ?? false;
const offlineFirst = existing?.offlineFirst ?? false;
```

Paths follow the same rule: explicit raw flag, then existing config, then schema default. In interactive mode, prompt only for values without explicit flags and use existing values as initial values. Keep SDUI semantics unchanged.

Remove the current upfront “overwrite swiftcn.json?” branch and all pre-transaction `ensureDir` calls. Idempotent reruns are resolved by the transaction's `skip|replace` plan; prompt cancellation must return from the action before calling the initializer.

- [x] **Step 4: Call the initializer once and print preset-specific next steps**

```ts
await container.initializer.initialize({
  cwd,
  config,
  includeSdui: Boolean(config.sduiPath),
  includeNavigationRouter: config.navigation && config.preset !== "tca",
  force: options.force,
});
```

Render `added`, `replaced`, and `skipped` paths from this one result; do not call `ConfigService.write` or any fetcher afterward.

Native output says View owns local `@State` and calls a use case. MVVM output says `@MainActor @Observable` ViewModel owns screen state and emits typed navigation outcomes. TCA output names TCA 1.26.1/Swift 6.1 and says `StackState`/`@Presents`; it must not mention installing Router. All three link to `docs/architecture-presets.md` on the tagged repository.

- [x] **Step 5: Update custom help and root CLI help**

Add exact examples for `--preset mvvm --navigation -y` and `--preset tca --navigation -y`. State that navigation is opt-in and TCA does not install Router. Do not claim that init edits package manifests.

- [x] **Step 6: Run command tests and typecheck**

Run: `npm --prefix CLI test -- src/__tests__/commands/init.test.ts`

Expected: PASS for the preset/navigation/rerun matrix.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 7: Commit**

```bash
git add -- CLI/src/commands/init.ts CLI/src/__tests__/commands/init.test.ts CLI/src/index.ts
git commit -m "feat(cli): initialize clean architecture presets"
```

---

### Task 5: Prevent duplicate navigation ownership in TCA

**Files:**

- Modify: `CLI/src/commands/add.ts`
- Modify: `CLI/src/__tests__/commands/add.test.ts`

**Interfaces:**

- Consumes: defaulted `ProjectConfig.preset`.
- Produces: a pre-write guard for `swiftcn add navigation` when `preset === "tca"`.

- [x] **Step 1: Write failing add-command tests**

```ts
it("rejects Router installation for a TCA project", async () => {
  const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});
  const container = await runAdd(["navigation"], {
    config: {
      load: vi.fn().mockResolvedValue({
        ...sampleConfig,
        preset: "tca",
        navigation: true,
        offlineFirst: false,
      }),
      write: vi.fn(),
      exists: vi.fn().mockResolvedValue(true),
    },
    registry: {
      ...mockRegistry,
      getComponent: vi.fn().mockResolvedValue(sampleNavigation),
    },
  });
  expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
  expect(logSpy.mock.calls.flat().join("\n")).toContain("StackState");
});

it.each(["native", "mvvm"])("keeps navigation installable for %s", async (preset) => {
  const container = await runAdd(["navigation"], {
    config: {
      load: vi.fn().mockResolvedValue({
        ...sampleConfig,
        preset,
        navigation: false,
        offlineFirst: false,
      }),
      write: vi.fn(),
      exists: vi.fn().mockResolvedValue(true),
    },
    registry: {
      ...mockRegistry,
      getComponent: vi.fn().mockResolvedValue(sampleNavigation),
    },
  });
  expect(container.fetcher.fetchComponents).toHaveBeenCalled();
});
```

Define `mockRegistry` in the test block with the existing `RegistryService` methods and empty arrays, matching the mock shape already used in `add.test.ts`.

- [x] **Step 2: Run the focused test and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/commands/add.test.ts`

Expected: FAIL because TCA currently installs the Router item.

- [x] **Step 3: Add the guard immediately after component lookup**

```ts
if (componentName.toLowerCase() === "navigation" && config.preset === "tca") {
  ui.error("TCA owns navigation in reducer state.");
  ui.end("Use StackState and @Presents; Router<Route> was not installed.");
  process.exit(1);
  return;
}
```

The explicit `return` is required because command tests mock `process.exit`.

- [x] **Step 4: Run add and regression tests**

Run: `npm --prefix CLI test -- src/__tests__/commands/add.test.ts src/__tests__/types/registry.schema.test.ts`

Expected: PASS; Native/MVVM still resolve `Navigation/Router.swift` to the sibling Navigation directory.

- [x] **Step 5: Commit**

```bash
git add -- CLI/src/commands/add.ts CLI/src/__tests__/commands/add.test.ts
git commit -m "fix(cli): keep TCA navigation reducer-owned"
```

---

### Task 6: Publish compile-checked architecture recipes

**Files:**

- Create: all files under `Fixtures/ArchitecturePresets/` listed in File Structure.
- Create: `docs/architecture-presets.md`
- Create: `scripts/test-architecture-presets.sh`
- Modify: `README.md`
- Modify: `CLI/README.md`
- Modify: `scripts/test-all.sh`

**Interfaces:**

- Consumes: PR #7 `Router<Route>` API and TCA 1.26.1 APIs.
- Produces: compile-checked Native/MVVM/TCA recipes and one repository verification command.

- [x] **Step 1: Create the failing package manifest and dependency graph**

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "ArchitecturePresets",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      exact: "1.26.1"
    )
  ],
  targets: [
    .target(name: "PresetDomain"),
    .target(name: "PresetApplication", dependencies: ["PresetDomain"]),
    .target(name: "NativePreset", dependencies: ["PresetApplication"]),
    .target(name: "MVVMPreset", dependencies: ["PresetApplication"]),
    .target(
      name: "TCAPreset",
      dependencies: [
        "PresetApplication",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(
      name: "ArchitecturePresetTests",
      dependencies: ["NativePreset", "MVVMPreset", "TCAPreset"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
```

Run: `swift test --package-path Fixtures/ArchitecturePresets`

Expected: FAIL because target source files do not exist.

- [x] **Step 2: Add the shared inward-only domain and use case**

```swift
// PresetDomain/Score.swift
public struct Score: Equatable, Sendable {
  public private(set) var value: Int
  public init(value: Int = 0) { self.value = max(0, value) }
  public mutating func increment() { value += 1 }
}

// PresetApplication/IncrementScore.swift
import PresetDomain

public struct IncrementScore: Sendable {
  public init() {}
  public func execute(_ score: Score) -> Score {
    var score = score
    score.increment()
    return score
  }
}
```

- [x] **Step 3: Add distinct Native and MVVM presentation recipes**

Native owns `@State private var score = Score()` directly and assigns `increment.execute(score)`. MVVM defines:

```swift
@MainActor @Observable
public final class ScoreViewModel {
  public private(set) var score: Score
  public private(set) var outcome: ScoreNavigationOutcome?
  private let increment: IncrementScore

  public init(score: Score = Score(), increment: IncrementScore = IncrementScore()) {
    self.score = score
    self.increment = increment
  }

  public func incrementTapped() { score = increment.execute(score) }
  public func detailsTapped() { outcome = .showDetails(score: score.value) }
}
```

The MVVM View only renders `model.score` and calls those intent methods. It never mutates Router. The fixture outcome enum is `Equatable, Sendable` and carries only the stable integer value.

- [x] **Step 4: Add the TCA reducer and navigation recipe**

```swift
@Reducer
public struct ScoreFeature {
  @ObservableState
  public struct State: Equatable { public var score = Score() }
  public enum Action { case incrementTapped }
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .incrementTapped:
        state.score = IncrementScore().execute(state.score)
        return .none
      }
    }
  }
}

@Reducer
public struct AppFeature {
  @Reducer public enum Path { case score(ScoreFeature) }
  @Reducer public enum Destination { case score(ScoreFeature) }

  @ObservableState
  public struct State: Equatable {
    public var path = StackState<Path.State>()
    @Presents public var destination: Destination.State?
  }

  public enum Action {
    case path(StackActionOf<Path>)
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
      .forEach(\.path, action: \.path)
      .ifLet(\.$destination, action: \.destination)
  }
}
```

Add `NavigationStack(path: $store.scope(\.path, action: \.path))` in the TCA view. Do not import or instantiate `Router` anywhere in `TCAPreset`.

- [x] **Step 5: Add behavioral tests and the import gate**

```swift
@Test @MainActor
func nativeUseCaseChangesViewFacingValueWithoutViewModel() {
  let result = IncrementScore().execute(Score())
  #expect(result.value == 1)
}

@Test @MainActor
func mvvmOwnsStateAndEmitsOutcome() {
  let model = ScoreViewModel()
  model.incrementTapped()
  model.detailsTapped()
  #expect(model.score.value == 1)
  #expect(model.outcome == .showDetails(score: 1))
}

@Test @MainActor
func tcaReducerOwnsState() async {
  let store = TestStore(initialState: ScoreFeature.State()) { ScoreFeature() }
  await store.send(.incrementTapped) { $0.score = Score(value: 1) }
}
```

The shell gate runs the package test, rejects `SwiftUI|ComposableArchitecture|SwiftData|CoreData|URLSession|Router` imports under `PresetDomain`, and rejects `Router` under `TCAPreset`.

- [x] **Step 6: Write docs from the compile-checked code**

`docs/architecture-presets.md` must explain the exact ownership difference, show Router ownership for Native/MVVM, show TCA navigation state, identify TCA 1.26.1/Swift 6.1, and state that users copy/adapt only code their feature needs. Link the four existing Archify HTML diagrams. Update both READMEs and CLI help examples to the same flags.

- [x] **Step 7: Run fixture and full CLI verification**

Run: `./scripts/test-architecture-presets.sh`

Expected: all fixture tests PASS and forbidden-import scan returns no match.

Run: `npm --prefix CLI test`

Expected: all CLI tests PASS.

- [x] **Step 8: Commit**

```bash
git add -- Fixtures/ArchitecturePresets docs/architecture-presets.md scripts/test-architecture-presets.sh scripts/test-all.sh README.md CLI/README.md
git commit -m "docs: add compile-checked architecture recipes"
```

---

### Task 7: Verify the preset increment end to end

**Files:**

- Modify only if verification exposes a defect in files already listed above.

**Interfaces:**

- Consumes: all preceding tasks.
- Produces: a green repository verification record; no new product API.

- [x] **Step 1: Run formatting and static checks**

Run: `git diff --check`

Expected: no output and exit 0.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 2: Run the complete relevant suite**

Run: `./scripts/test-architecture-presets.sh`

Expected: PASS.

Run: `./scripts/test-cli.sh`

Expected: PASS.

- [x] **Step 3: Exercise built CLI help**

Run: `npm --prefix CLI run build`

Expected: PASS.

Run: `node CLI/dist/index.js init --help`

Expected: output lists `native|mvvm|tca`, positive/negative navigation flags, and no VIPER option. Tagged-network installation remains covered by mocked initializer tests until the release tag containing these templates exists.

- [x] **Step 4: Run the repository suite**

Run: `./scripts/test-all.sh`

Expected: CLI, sync-source, architecture fixture, and Example tests PASS.

- [x] **Step 5: Record verification**

If a verification command fails, fix only the already-listed owning file, rerun that command, and commit the exact corrected paths with `fix(cli): close init preset verification gaps`. If every command passes, make no verification-only commit.
