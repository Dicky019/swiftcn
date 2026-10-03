# Init presets and Offline-First implementation

This record is for maintainers continuing or reviewing the init work. Both
14 September plans are complete on `feat/init-presets-offline-first`, starting
from `bab0b075bdb6a00f76fdc774f9cf9d7e1ce6321c`.

## Pre-MR corrections — 4 October 2026

A subsequent pre-MR review reproduced two P1 transaction defects. Recovery
cleanup removed its claim before journal deletion, allowing another recovery
to enter and eventually delete a newer init's journal. Case-sensitive path
comparisons also allowed `.SWIFTCN-TRANSACTION` as a theme destination on
case-insensitive macOS; cleanup deleted all seven files despite reporting them
as installed.

Recovery now publishes its live PID in the journal before rollback/cleanup and
relinquishes that ownership after a caught failure. Another process remains
excluded until journal deletion. Destination preflight uses case-folded,
Unicode-normalized identities for reserved paths, duplicates and ancestors.
Ambiguous destination aliases are rejected on case-sensitive hosts too.

Eight regressions failed against the reviewed code before these fixes. All
61 focused transaction tests now pass, including a three-process check that
holds cleanup at journal unlink, rejects a competing recovery, then interrupts
a subsequent forced init and verifies restoration of the original file. The
original InitService case-variant reproduction now fails before project writes.

Fresh full verification after the fixes passed: 236 CLI tests in 17 files,
source synchronization, 8 architecture tests, and 103 Example test executions
(97 definitions), with no failures or skips. CLI typecheck/build and whitespace
checks also passed. The simulator remains iPhone 18 Pro on iOS 27; oldest-runtime
verification remains pending.

An independent review of the fix delta found no actionable introduced defects
and separately passed all 61 focused transaction tests. Both P1 findings are
closed by reproduction and regression evidence; no remaining findings were
reported for these fixes.

## Delivered behavior

- `init --preset native|mvvm|tca` persists architecture ownership with safe
  defaults for older configs. Omitted rerun flags preserve existing selections.
- Positive/negative navigation and Offline-First flags distinguish omission
  from explicit disable. Disabling leaves copy-owned source intact.
- Native/MVVM navigation reuses the exact existing registry Router. TCA owns
  `StackState`/`@Presents` and rejects `add navigation`.
- Init reads a single tagged registry/source snapshot and preflights selected
  source/config paths before staging. Existing files skip unless forced;
  config is atomically replaced last. Interrupted transactions recover before
  config loading and network work.
- The same three Offline-First files provide value contracts, capped jitter
  retries, and a scoped single-flight coordinator for every preset. Features
  supply workers, durable stores/outboxes, gateways and reconciliation.
- Repository-only SwiftData tests prove actual disk reopen, atomic paired
  writes/ack/cursor operations, account isolation and lightweight migration.
  Failure fixtures cover response loss, replay, partial batches, late ack,
  conflict, tombstones, auth, storage, migration and background expiration.
- Compile-checked Native/MVVM/TCA recipes use separate inward-dependent modules
  and a repository-only iOS test host. No feature or project scaffold is copied
  into a user's application.

Guides: [architecture presets](../../architecture-presets.md) and
[Offline-First integration](../../offline-first.md).

## Final verification

Command:

```sh
./scripts/test-all.sh 'platform=iOS Simulator,name=iPhone 18 Pro'
npm --prefix CLI run typecheck
npm --prefix CLI run build
node CLI/dist/index.js --help
node CLI/dist/index.js init --help
git diff HEAD --check
```

All passed. The combined suite verified:

| Check | Result |
| --- | --- |
| CLI | 228 tests, 16 files passed |
| Source synchronization | Passed; canonical Offline-First copies match |
| Architecture fixtures | 8 passed, none failed or skipped |
| Example | 97 test definitions / 103 executions passed, none failed or skipped |
| Build/typecheck | Passed |
| Swift lint/build/runtime warnings | None in final run |
| Forbidden imports | None in Shared Core; fixture Domain/Application/TCA gates passed |
| Shell syntax and diff whitespace | Passed |

Environment: Xcode 27, Swift 6.4, iPhone 18 Pro simulator on iOS 27. Swift 6
complete strict concurrency and iOS 17 deployment minimum are configured.
The exact oldest Swift 6.1/iOS 17 environment was not available for execution.

New behaviors were exercised through failing tests before implementation.
Initial combined verification encountered an intentional missing-method RED
step in a fixture being finalized; the final rerun above used frozen code and
completed successfully.

## Review and correction

A separate agent reviewed CLI, transactions and Offline-First against the spec.
The harness rejected an additional fresh reviewer at its thread limit, so the
architecture fixture author supplied the review seat; the recipe portion
therefore received author review rather than an independent review.

The review reproduced one Important defect: a new request arriving after
`cancel()` while an old worker was still retiring joined the cancelled task
and left its trigger unrun. The fix waits for retirement before enqueueing a
fresh request and rechecks caller cancellation after suspension. Two
regressions failed before the fix and passed afterward; final full verification
also passed. They cover fresh work, multiple fresh triggers, cancellation of a
waiting caller, and maximum one active worker. No other blocking findings or
deferred minor findings remained.

## Execution decisions

Each decision includes its reason and practical cost if it needs revisiting.

- Use a feature branch in the visible clean checkout; avoid changing `main`.
  Revisit by moving work to a worktree if separate filesystem isolation is needed.
- Run disjoint transaction, recipe and Offline-First work in parallel while
  keeping CLI integration with the coordinator. Revisit costs integration work.
- Validate Offline-First manifests with an exact tuple, but allow an absent
  field in older registries; enabling an unavailable capability fails before
  installation. Revisit costs tightening support for older tagged releases.
- Use a repository-only Tuist iOS host rather than host-macOS package tests.
  This compiles real SwiftUI/TCA recipes; the cost is fixture maintenance.
- Keep the TCA score recipe synchronous as specified, with asynchronous
  integration bridges in the Offline-First guide. More elaborate I/O examples
  require an additional feature design.
- Publish transaction metadata through a seeded PID/UUID bootstrap directory
  and atomic rename. This closes termination before the first journal write;
  the cost is extra reserved scratch-directory handling.
- Infer completed moves from staged/backup disk state, and rename created
  files back to staging during rollback. This makes recovery resumable even
  between journal writes; revisiting requires alternative crash-state evidence.
- Back up config through copy-to-temp and atomic rename, preserving the old
  config until final replacement. The cost is a temporary extra config copy.
- Record committed state and completed rollback before cleanup, then remove
  the journal last. This distinguishes interrupted apply from cleanup and
  permits safe removal of empty residue; the cost is additional journal states.
- Claim recovery ownership atomically and recheck directory/journal identity;
  relinquish caught-failure ownership only for the same transaction. This
  prevents concurrent recovery or replacement from acting on stale metadata;
  the cost is ownership-claim bookkeeping.
- Include generated config in overlap validation so source destinations beneath
  `swiftcn.json/` fail before staging. The cost is reserving this generated path.
- Cancelled callers waiting for flight retirement return cancelled without
  adding their trigger; other fresh callers can resume work. The cost is that
  a cancelled caller must make a new request if it later wants work resumed.

## Boundaries and release

Production adapters, backend policies, Keychain integration, entitlements and
background scheduling remain application responsibilities; choosing them
requires a separate integration task. Mixed architectures, automatic migration
and feature scaffolding remain excluded from v1; those uses need manual or
separately designed integration. Tooling verifies shipped templates/recipes,
while owners assess their customized application source.

Transaction guarantees cover caught I/O errors and process termination under
SwiftCN ownership. Power-loss/fsync guarantees and arbitrary hostile external
filesystem mutation were not assessed; those need additional durability or
sandbox work. Testing on a newer installed SDK does not substitute for a
future oldest-runtime compatibility run.

The implementation is local and unreleased. `SOURCE_REF` follows the CLI
package version, and the existing release tag does not gain new templates.
Distribution requires a version bump and matching new source tag before npm
publication. No existing tag was rewritten, and no push, merge or publish
was performed.
