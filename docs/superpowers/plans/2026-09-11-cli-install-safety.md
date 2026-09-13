# CLI Install Safety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make CLI installation contained, fail-fast, non-destructive by default, and reproducible for each published CLI version.

**Architecture:** Reuse the existing `resolveSecurePath` boundary at every user-controlled and registry-controlled filesystem join. Keep the current services and copy workflow, but surface copy failures and make overwrite/version choices explicit.

**Tech Stack:** Node.js 20+, TypeScript 5, Commander, Zod, fs-extra, simple-git, Vitest.

**Spec:** `docs/superpowers/specs/2026-09-11-foundation-hardening-design.md`

## Global Constraints

- Swift templates remain compatible with Swift 6, iOS 17.0+, macOS 14.0+, and Xcode 16+.
- Components remain copy-paste owned source, not a framework.
- CLI requires Node.js 20 or newer.
- Preserve existing files unless `--force` is supplied.
- Use the installed CLI's exact `v<version>` tag for registry and source.
- Reuse `CLI/src/utils/paths.ts`; do not create another path utility.
- Keep the current service/container structure.
- Add no dependency.

## File Map

- `CLI/src/commands/init.ts`: contain user-selected paths and pass the force option.
- `CLI/src/commands/add.ts`: contain paths loaded from `swiftcn.json`.
- `CLI/src/services/FetcherService.ts`: contain registry paths and surface copy errors.
- `CLI/src/services/GitService.ts`: clone the exact source ref.
- `CLI/src/types/options.schema.ts`: parse the init force flag.
- `CLI/src/utils/constants.ts`: derive the immutable release ref and registry URL.
- `CLI/src/__tests__/**`: regression coverage for each boundary.
- `CLI/README.md`: safe overwrite and release behavior.

---

### Task 1: Contain project-configured paths

**Files:**
- Modify: `CLI/src/commands/init.ts:1-177`
- Modify: `CLI/src/commands/add.ts:1-104`
- Test: `CLI/src/__tests__/commands/init.test.ts`
- Test: `CLI/src/__tests__/commands/add.test.ts`

**Interfaces:**
- Consumes: `resolveSecurePath(basePath: string, relativePath: string): string` from `CLI/src/utils/paths.ts`.
- Produces: component, theme, and SDUI destination roots contained by the command's `cwd`.

- [ ] **Step 1: Add failing command-boundary tests**

Append these cases to the existing command suites:

```ts
// init.test.ts
it("rejects a components path outside the project", async () => {
  const container = await runInit(["--path", "../outside", "-y"]);

  expect(container.fetcher.fetchTheme).not.toHaveBeenCalled();
  expect(container.config.write).not.toHaveBeenCalled();
});

it("rejects an absolute theme path", async () => {
  const container = await runInit(["--theme-path", "/tmp/theme", "-y"]);

  expect(container.fetcher.fetchTheme).not.toHaveBeenCalled();
  expect(container.config.write).not.toHaveBeenCalled();
});
```

```ts
// add.test.ts
it("rejects a configured components path outside the project", async () => {
  const unsafeConfig = { ...sampleConfig, componentsPath: "../outside" };
  const container = await runAdd(["button"], {
    config: {
      load: vi.fn().mockResolvedValue(unsafeConfig),
      write: vi.fn(),
      exists: vi.fn().mockResolvedValue(true),
    },
    registry: {
      load: vi.fn().mockResolvedValue({}),
      getComponent: vi.fn().mockResolvedValue(sampleButton),
      listComponents: vi.fn().mockResolvedValue(sampleComponents),
      getThemeFiles: vi.fn().mockResolvedValue([]),
      getSduiFiles: vi.fn().mockResolvedValue([]),
    },
  });

  expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
});
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
cd CLI && npm test -- src/__tests__/commands/init.test.ts src/__tests__/commands/add.test.ts
```

Expected: the new cases fail because the fetcher is called for paths outside `cwd`.

- [ ] **Step 3: Route configured paths through the existing containment helper**

Add this import to both command files:

```ts
import { resolveSecurePath } from "../utils/paths.js";
```

In `init.ts`, replace the three destination joins:

```ts
const fullComponentsPath = resolveSecurePath(cwd, componentsPath);
const fullThemePath = resolveSecurePath(cwd, themePath);

// Inside `if (withSdui)`:
const fullSduiPath = resolveSecurePath(cwd, sduiPath);
```

In `add.ts`, replace the component destination join:

```ts
const destDir = resolveSecurePath(cwd, config.componentsPath);
```

Keep `node:path` imports because both commands still use `path.relative`.

- [ ] **Step 4: Run focused tests**

Run:

```bash
cd CLI && npm test -- src/__tests__/commands/init.test.ts src/__tests__/commands/add.test.ts src/__tests__/utils/paths.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CLI/src/commands/init.ts CLI/src/commands/add.ts CLI/src/__tests__/commands/init.test.ts CLI/src/__tests__/commands/add.test.ts
git commit -m "fix(cli): contain configured install paths"
```

---

### Task 2: Contain registry paths and fail on copy errors

**Files:**
- Modify: `CLI/src/services/FetcherService.ts:1-106`
- Modify: `CLI/src/utils/constants.ts:24-32`
- Test: `CLI/src/__tests__/services/FetcherService.test.ts`

**Interfaces:**
- Consumes: `resolveSecurePath`, `SwiftCNError`, and `ErrorCode.FILE_COPY_FAILED`.
- Produces: all fetch methods reject on containment, prefix, or copy failure.

- [ ] **Step 1: Add failing fetcher tests**

Add to `FetcherService.test.ts`:

```ts
it("rejects a source path that escapes Sources", async () => {
  await expect(
    service.fetchComponents(["../../outside.swift"], "/dest")
  ).rejects.toThrow("outside the allowed directory");
  expect(mockFile.copy).not.toHaveBeenCalled();
});

it("rejects a theme file without the Theme prefix", async () => {
  vi.mocked(mockRegistry.getThemeFiles).mockResolvedValue([
    "Components/CNButton.swift",
  ]);

  await expect(service.fetchTheme("/dest/theme")).rejects.toThrow(
    "must start with Theme/"
  );
});

it("rejects when a file copy returns an error", async () => {
  vi.mocked(mockFile.copy).mockResolvedValue({
    status: "error",
    path: "/dest/CNButton.swift",
    error: "disk full",
  });

  await expect(
    service.fetchComponents(["Components/CNButton.swift"], "/dest")
  ).rejects.toThrow("disk full");
});
```

- [ ] **Step 2: Run the test and verify failure**

Run:

```bash
cd CLI && npm test -- src/__tests__/services/FetcherService.test.ts
```

Expected: all three new cases fail.

- [ ] **Step 3: Add the minimal registry boundary**

Add imports:

```ts
import { resolveSecurePath } from "../utils/paths.js";
import { ErrorCode, SwiftCNError } from "../utils/errors.js";
```

Add this file-local helper:

```ts
function destinationPath(file: string, stripPrefix: string | null): string {
  if (!stripPrefix) return path.basename(file);
  if (file.startsWith(stripPrefix)) return file.slice(stripPrefix.length);

  throw new SwiftCNError(
    `Registry path must start with ${stripPrefix}: ${file}`,
    ErrorCode.INVALID_INPUT
  );
}
```

Replace path and result handling inside `fetchFiles`:

```ts
const sourceRoot = path.join(tempDir, SOURCE_PATH);

for (const file of files) {
  const sourcePath = resolveSecurePath(sourceRoot, file);
  const relativePath = destinationPath(file, options.stripPrefix);
  const destPath = resolveSecurePath(destDir, relativePath);
  const copyResult = await this.file.copy(sourcePath, destPath, {
    force: options.force,
  });

  if (copyResult.status === "error") {
    throw new SwiftCNError(
      copyResult.error ?? `Failed to copy ${file}`,
      ErrorCode.FILE_COPY_FAILED
    );
  }

  if (copyResult.status === "added") result.added.push(destPath);
  if (copyResult.status === "skipped") result.skipped.push(destPath);
}
```

Delete `ALLOWED_SOURCE_PATHS` from `constants.ts`; actual source and destination containment replaces the unused declaration.

- [ ] **Step 4: Run fetcher and utility tests**

Run:

```bash
cd CLI && npm test -- src/__tests__/services/FetcherService.test.ts src/__tests__/utils/paths.test.ts src/__tests__/utils/errors.test.ts
```

Expected: PASS, including cleanup after rejected fetches.

- [ ] **Step 5: Commit**

```bash
git add CLI/src/services/FetcherService.ts CLI/src/utils/constants.ts CLI/src/__tests__/services/FetcherService.test.ts
git commit -m "fix(cli): validate registry copy boundaries"
```

---

### Task 3: Preserve templates unless force is explicit

**Files:**
- Modify: `CLI/src/types/options.schema.ts:3-10`
- Modify: `CLI/src/commands/init.ts:11-219`
- Test: `CLI/src/__tests__/types/options.schema.test.ts`
- Test: `CLI/src/__tests__/commands/init.test.ts`
- Modify: `CLI/README.md`

**Interfaces:**
- Produces: `InitOptionsSchema.parse(...).force: boolean | undefined`.
- Produces: `swiftcn init -f` and `swiftcn init --force`.

- [ ] **Step 1: Add failing tests**

Add to `options.schema.test.ts`:

```ts
it("accepts the init force flag", () => {
  expect(InitOptionsSchema.parse({ force: true }).force).toBe(true);
});
```

Add to `init.test.ts`:

```ts
it("preserves existing templates by default", async () => {
  const container = await runInit(["-y"]);
  expect(container.fetcher.fetchTheme).toHaveBeenCalledWith(
    expect.any(String),
    { force: undefined }
  );
});

it("overwrites theme and SDUI only with force", async () => {
  const container = await runInit(["--sdui", "--force", "-y"]);
  expect(container.fetcher.fetchTheme).toHaveBeenCalledWith(
    expect.any(String),
    { force: true }
  );
  expect(container.fetcher.fetchSdui).toHaveBeenCalledWith(
    expect.any(String),
    { force: true }
  );
});
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
cd CLI && npm test -- src/__tests__/types/options.schema.test.ts src/__tests__/commands/init.test.ts
```

Expected: force is stripped by Zod and `init` always passes `true`.

- [ ] **Step 3: Implement explicit force**

Add to `InitOptionsSchema`:

```ts
force: z.boolean().optional(),
```

Add the Commander option and help row:

```ts
.option("-f, --force", "Overwrite existing theme and SDUI files")

ui.command("-f, --force            ", "Overwrite existing theme and SDUI files");
```

Pass the parsed value:

```ts
const themeResult = await container.fetcher.fetchTheme(fullThemePath, {
  force: options.force,
});

const sduiResult = await container.fetcher.fetchSdui(fullSduiPath, {
  force: options.force,
});
```

Document:

```markdown
swiftcn init              # Preserve existing theme and SDUI files
swiftcn init --force      # Explicitly overwrite foundation files
```

- [ ] **Step 4: Run focused tests**

Run:

```bash
cd CLI && npm test -- src/__tests__/types/options.schema.test.ts src/__tests__/commands/init.test.ts
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CLI/src/types/options.schema.ts CLI/src/commands/init.ts CLI/src/__tests__/types/options.schema.test.ts CLI/src/__tests__/commands/init.test.ts CLI/README.md
git commit -m "fix(cli): preserve installed templates by default"
```

---

### Task 4: Pin registry and source to the installed version

**Files:**
- Modify: `CLI/src/utils/constants.ts:6-47`
- Modify: `CLI/src/services/GitService.ts:7-21`
- Modify: `CLI/src/services/FetcherService.ts:5-76`
- Modify: `CLI/src/__tests__/services/FetcherService.test.ts`
- Create: `CLI/src/__tests__/utils/constants.test.ts`
- Modify: `CLI/README.md`

**Interfaces:**
- Produces: `SOURCE_REF: string`, always `v${VERSION}`.
- Produces: `GitService.clone(repoUrl: string, targetDir: string, ref?: string): Promise<void>`.
- Consumes: release tags created before npm publication.

- [ ] **Step 1: Add failing ref consistency tests**

Create `constants.test.ts`:

```ts
import { describe, expect, it } from "vitest";
import { REGISTRY_URL, SOURCE_REF, VERSION } from "../../utils/constants.js";

describe("release source constants", () => {
  it("pins registry assets to the installed CLI version", () => {
    expect(SOURCE_REF).toBe(`v${VERSION}`);
    expect(REGISTRY_URL).toContain(`/${SOURCE_REF}/CLI/registry.json`);
  });
});
```

Add to the first `FetcherService` test:

```ts
expect(mockGit.clone).toHaveBeenCalledWith(
  expect.any(String),
  "/tmp/swiftcn-123",
  expect.stringMatching(/^v\d+\.\d+\.\d+$/)
);
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```bash
cd CLI && npm test -- src/__tests__/utils/constants.test.ts src/__tests__/services/FetcherService.test.ts
```

Expected: `SOURCE_REF` is absent, registry uses `main`, and clone receives two arguments.

- [ ] **Step 3: Implement the version-derived ref**

Replace the main-branch registry URL:

```ts
export const SOURCE_REF = `v${VERSION}`;
export const REGISTRY_URL =
  `https://raw.githubusercontent.com/Dicky019/swiftcn/${SOURCE_REF}/CLI/registry.json`;
```

Update the Git service:

```ts
export interface GitService {
  clone(repoUrl: string, targetDir: string, ref?: string): Promise<void>;
  cleanup(tempDir: string): Promise<void>;
  createTempDir(prefix: string): string;
}

async clone(repoUrl: string, targetDir: string, ref?: string): Promise<void> {
  if (!ALLOWED_REPO_URLS.includes(repoUrl as typeof ALLOWED_REPO_URLS[number])) {
    throw new Error(`Untrusted repository URL: ${repoUrl}`);
  }

  const args = ["--depth=1", "--single-branch"];
  if (ref) args.push("--branch", ref);
  await simpleGit().clone(repoUrl, targetDir, args);
}
```

Import and pass the ref in `FetcherService.ts`:

```ts
import {
  ALLOWED_REPO_URLS,
  SOURCE_PATH,
  SOURCE_REF,
} from "../utils/constants.js";

await this.git.clone(repoUrl, tempDir, SOURCE_REF);
```

- [ ] **Step 4: Document the release invariant and run the full CLI suite**

Add:

```markdown
Published CLI version `x.y.z` reads registry and templates from Git tag `vx.y.z`.
The release script must create and push that tag before `npm publish`.
```

Run:

```bash
cd CLI && npm run typecheck && npm test
```

Expected: typecheck and all Vitest tests PASS.

- [ ] **Step 5: Commit**

```bash
git add CLI/src/utils/constants.ts CLI/src/services/GitService.ts CLI/src/services/FetcherService.ts CLI/src/__tests__/services/FetcherService.test.ts CLI/src/__tests__/utils/constants.test.ts CLI/README.md
git commit -m "fix(cli): pin templates to release version"
```
