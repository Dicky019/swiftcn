# Offline-First Core Implementation Plan

**Status:** Completed 3 October 2026. [Implementation and verification record](../reports/2026-10-03-init-presets-offline-first.md).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in, external-system-agnostic Offline-First Core that coordinates single-flight sync safely while leaving entity storage, outbox payloads, reconciliation, and backend mapping to application adapters.

**Architecture:** Ship only shared value outcomes, retry policy, a feature-owned `SyncWorker` boundary, and one scoped coordinator actor. Install the same three files for Native, MVVM, and TCA. Verify deeper data-loss semantics with repository-only contract fixtures, including a durable SwiftData adapter that is never copied into user projects.

**Tech Stack:** Swift 6 strict concurrency, iOS 17+, Swift Testing, SwiftData test fixture, Node.js 20+, TypeScript, Zod, Vitest.

**Spec:** `docs/superpowers/specs/2026-09-14-init-presets-clean-architecture-design.md`

## Global Constraints

- This plan starts after `2026-09-14-init-presets-navigation.md` is complete.
- `--offline-first` is opt-in and composes with exactly `native`, `mvvm`, and `tca`.
- Shared Core must not import SwiftUI, ComposableArchitecture, Router, SwiftData, CoreData, networking APIs, or vendor SDKs.
- UI reads local source of truth; local projection and durable outbox commit together; page application and cursor advance commit together.
- Stable operation IDs survive retries; client code must not claim exactly-once behavior without server deduplication.
- One coordinator instance owns one account/store scope and at most one active worker pass.
- Retry is capped exponential backoff with full jitter, server hints, and a finite per-request budget.
- Persistence, payload schema, conflict policy, tombstones, migration, auth, BackgroundTasks, and transport mapping remain adapter/feature responsibilities.
- Disabling config never deletes copy-owned source or runtime data.
- Swift files use the repository header, two-space indentation, and `Sendable`-safe values; do not add `@unchecked Sendable`.

---

## File Structure

### Create

- `Sources/OfflineFirst/SyncTypes.swift` — public scopes, triggers, pass results, outcomes, and `SyncWorker`.
- `Sources/OfflineFirst/RetryPolicy.swift` — deterministic capped backoff, jitter, and server-hint calculation.
- `Sources/OfflineFirst/SyncCoordinator.swift` — one-scope actor, trigger coalescing, retry loop, and cancellation.
- `Example/Tests/OfflineFirst/RetryPolicyTests.swift` — boundary cases for retry calculation.
- `Example/Tests/OfflineFirst/SyncCoordinatorTests.swift` — concurrency, coalescing, retry, cancellation, and scope tests.
- `Example/Tests/OfflineFirst/SwiftDataReferenceStore.swift` — repo-only durable entity/outbox/cursor adapter.
- `Example/Tests/OfflineFirst/SwiftDataReferenceStoreTests.swift` — atomic write, reopen, migration, cursor, and account-isolation tests.
- `Example/Tests/OfflineFirst/SyncContractHarness.swift` — repo-only feature worker plus deterministic server/store doubles.
- `Example/Tests/OfflineFirst/SyncContractTests.swift` — lost response, late ack, partial batch, replay, conflict, tombstone, auth, and expiration tests.
- `docs/offline-first.md` — integration contract and Native/MVVM/TCA presentation bridges.

### Modify

- `CLI/registry.json` — add the exact three-file Offline-First Core manifest.
- `CLI/src/types/registry.schema.ts` — validate the manifest.
- `CLI/src/services/InitService.ts` — include Offline-First sources when requested.
- `CLI/src/commands/init.ts` — positive/negative flags, prompt, config merge, and adapter warning.
- `CLI/src/__tests__/types/registry.schema.test.ts` — exact manifest assertion.
- `CLI/src/__tests__/services/InitService.test.ts` — preset-independent file mapping.
- `CLI/src/__tests__/commands/init.test.ts` — full preset × Offline-First matrix and rerun behavior.
- `CLI/src/__tests__/commands/helpers.ts` — Offline-First transaction fixture result if needed.
- `scripts/sync-source.sh` — sync `Sources/OfflineFirst/` into `Example/App/OfflineFirst/`.
- `scripts/test-sync-source.sh` — ensure Offline-First copies remain synchronized.
- `Sources/README.md` — document the new optional template directory.
- `CLI/README.md` — document init flags and non-goals.
- `README.md` — link the integration guide and diagram.

## Interfaces

The public Swift signatures are copied exactly from the spec:

```swift
public struct SyncScope: Hashable, Sendable {
  public let rawValue: String
  public init(rawValue: String)
}

public enum SyncTrigger: Hashable, Sendable {
  case launch, foreground, manual, localMutation, connectivityHint
}

public enum RetryReason: Equatable, Sendable {
  case transport, timeout, serverBusy
}

public enum SyncBlockReason: Equatable, Sendable {
  case authentication, conflict, permanentRejection, storage, migration
}

public enum SyncPassResult: Equatable, Sendable {
  case noWork
  case completed
  case retry(reason: RetryReason, serverHint: Duration?)
  case blocked(SyncBlockReason)
  case expired
}

public enum SyncOutcome: Equatable, Sendable {
  case noWork
  case completed
  case deferred(RetryReason)
  case blocked(SyncBlockReason)
  case cancelled
  case expired
}

public protocol SyncWorker: Sendable {
  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult
}

public struct RetryPolicy: Equatable, Sendable {
  public init(maximumAttempts: Int, baseDelay: Duration, maximumDelay: Duration)
  public func delay(
    forAttempt attempt: Int,
    serverHint: Duration?,
    jitter: Double
  ) -> Duration?
}

public typealias SyncSleeper = @Sendable (Duration) async throws -> Void
public typealias SyncJitter = @Sendable () -> Double

public actor SyncCoordinator<Worker: SyncWorker> {
  public init(scope: SyncScope, worker: Worker, retryPolicy: RetryPolicy)
  public init(
    scope: SyncScope,
    worker: Worker,
    retryPolicy: RetryPolicy,
    sleep: @escaping SyncSleeper,
    jitter: @escaping SyncJitter
  )
  public func request(_ trigger: SyncTrigger) async -> SyncOutcome
  public func cancel()
}
```

---

### Task 1: Add shared sync values and deterministic retry policy

**Files:**

- Create: `Sources/OfflineFirst/SyncTypes.swift`
- Create: `Sources/OfflineFirst/RetryPolicy.swift`
- Create: `Example/Tests/OfflineFirst/RetryPolicyTests.swift`
- Modify: `scripts/sync-source.sh`
- Modify: `scripts/test-sync-source.sh`

**Interfaces:**

- Produces: all value types and `SyncWorker` above; `RetryPolicy.init(maximumAttempts:baseDelay:maximumDelay:)`; `delay(forAttempt:serverHint:jitter:)`.

- [x] **Step 1: Write failing retry tests**

```swift
@Suite("RetryPolicy")
struct RetryPolicyTests {
  let policy = RetryPolicy(
    maximumAttempts: 3,
    baseDelay: .seconds(2),
    maximumDelay: .seconds(10)
  )

  @Test func usesOneBasedExponentialAttempts() {
    #expect(policy.delay(forAttempt: 1, serverHint: nil, jitter: 1) == .seconds(2))
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: 1) == .seconds(4))
    #expect(policy.delay(forAttempt: 3, serverHint: nil, jitter: 1) == .seconds(8))
    #expect(policy.delay(forAttempt: 4, serverHint: nil, jitter: 1) == nil)
  }

  @Test func clampsFullJitterAndCapsServerHint() {
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: -1) == .zero)
    #expect(policy.delay(forAttempt: 2, serverHint: nil, jitter: 2) == .seconds(4))
    #expect(policy.delay(forAttempt: 2, serverHint: .seconds(7), jitter: 0.5) == .seconds(7))
    #expect(policy.delay(forAttempt: 2, serverHint: .seconds(99), jitter: 0.5) == .seconds(10))
  }
}
```

The initializer uses preconditions for programmer errors (`maximumAttempts < 0`, negative delays, or `maximumDelay < baseDelay`). Do not add a throwing validation API solely to unit-test preconditions.

- [x] **Step 2: Sync the new directory and verify the tests fail to compile**

Add `OfflineFirst` to `SUBDIRS` in `scripts/sync-source.sh` and include it in the final success message. Extend the sync test to detect any itemized `OfflineFirst/*.swift` after a real sync.

Run: `./scripts/sync-source.sh`

Run: `./scripts/test-example.sh`

Expected: FAIL because `RetryPolicy` and sync types do not exist yet.

- [x] **Step 3: Implement the value types exactly as specified**

Use the required Swift file headers. `SyncScope.init(rawValue:)` preconditions that the trimmed value is nonempty, because an empty account/store scope would collapse isolation. The enums contain no error strings, payloads, HTTP codes, or vendor objects.

- [x] **Step 4: Implement retry calculation**

```swift
public struct RetryPolicy: Equatable, Sendable {
  public let maximumAttempts: Int
  public let baseDelay: Duration
  public let maximumDelay: Duration

  public init(maximumAttempts: Int, baseDelay: Duration, maximumDelay: Duration) {
    precondition(maximumAttempts >= 0)
    precondition(baseDelay >= .zero)
    precondition(maximumDelay >= baseDelay)
    self.maximumAttempts = maximumAttempts
    self.baseDelay = baseDelay
    self.maximumDelay = maximumDelay
  }

  public func delay(
    forAttempt attempt: Int,
    serverHint: Duration?,
    jitter: Double
  ) -> Duration? {
    guard attempt > 0, attempt <= maximumAttempts else { return nil }
    var exponential = baseDelay
    for _ in 1..<attempt {
      exponential = min(exponential + exponential, maximumDelay)
    }
    let jittered = scale(exponential, by: min(max(jitter, 0), 1))
    return min(max(jittered, serverHint ?? .zero), maximumDelay)
  }
}
```

Implement private `scale(_:by:)` by converting `Duration.components.seconds` and `attoseconds` to a `Double` number of seconds and returning `.seconds(value * factor)`. This helper is the only floating-point conversion and is acceptable for scheduling delays, not business time.

- [x] **Step 5: Sync and run focused tests**

Run: `./scripts/sync-source.sh`

Run: `./scripts/test-example.sh`

Expected: retry tests and existing Example tests PASS.

- [x] **Step 6: Commit**

```bash
git add -- Sources/OfflineFirst Example/App/OfflineFirst Example/Tests/OfflineFirst/RetryPolicyTests.swift scripts/sync-source.sh scripts/test-sync-source.sh
git commit -m "feat(offline): add sync contracts and retry policy"
```

---

### Task 2: Implement the scoped single-flight coordinator

**Files:**

- Create: `Sources/OfflineFirst/SyncCoordinator.swift`
- Create: `Example/Tests/OfflineFirst/SyncCoordinatorTests.swift`

**Interfaces:**

- Consumes: `SyncScope`, `SyncTrigger`, `SyncWorker`, `SyncPassResult`, `SyncOutcome`, and `RetryPolicy` from Task 1.
- Produces: the two `SyncCoordinator` initializers, `request(_:)`, and `cancel()` from the spec.

- [x] **Step 1: Write a controllable worker and failing coordinator tests**

```swift
actor RecordingWorker: SyncWorker {
  private(set) var calls: [(SyncScope, Set<SyncTrigger>)] = []
  private(set) var active = 0
  private(set) var maximumActive = 0
  var results: [SyncPassResult]
  let gate: SuspensionGate?

  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult {
    active += 1
    maximumActive = max(maximumActive, active)
    defer { active -= 1 }
    calls.append((scope, triggers))
    if let gate { await gate.wait() }
    return results.isEmpty ? .noWork : results.removeFirst()
  }
}
```

Define `SuspensionGate` as a small test actor that stores `CheckedContinuation<Void, Never>` values in `wait()` and resumes one in `releaseOne()`. This is the only scheduling test seam; do not use wall-clock sleeps.

Tests must prove:

- 20 concurrent requests never make `maximumActive` exceed 1.
- A trigger received during the active pass appears in exactly one follow-up call.
- `.retry` sleeps with the injected delays and reruns until success.
- A fourth retry with `maximumAttempts: 3` returns `.deferred(reason)` and leaves worker-owned work untouched.
- `cancel()` during worker execution or injected sleep returns `.cancelled`.
- `.blocked` and `.expired` pass through without retry.
- The worker always receives the coordinator's one `SyncScope`.

- [x] **Step 2: Run the focused test and verify failure**

Run: `./scripts/test-example.sh`

Expected: FAIL because `SyncCoordinator` does not exist.

- [x] **Step 3: Implement production and injected initializers**

```swift
public typealias SyncSleeper = @Sendable (Duration) async throws -> Void
public typealias SyncJitter = @Sendable () -> Double

public actor SyncCoordinator<Worker: SyncWorker> {
  private let scope: SyncScope
  private let worker: Worker
  private let retryPolicy: RetryPolicy
  private let sleep: SyncSleeper
  private let jitter: SyncJitter
  private var pendingTriggers: Set<SyncTrigger> = []
  private var activeTask: Task<SyncOutcome, Never>?

  public init(scope: SyncScope, worker: Worker, retryPolicy: RetryPolicy) {
    self.init(
      scope: scope,
      worker: worker,
      retryPolicy: retryPolicy,
      sleep: { try await Task.sleep(for: $0) },
      jitter: { Double.random(in: 0...1) }
    )
  }
}
```

The injected initializer assigns all fields without hidden global state.

- [x] **Step 4: Implement request coalescing and retry loop**

`request(_:)` inserts the trigger, awaits `activeTask` when present, or creates exactly one `Task { await drainAndFinish() }`. Assign `activeTask` before the actor first suspends. `drainAndFinish()` uses `defer { activeTask = nil }`, then snapshots and clears pending triggers before each worker call. This makes the final pending-trigger check and task cleanup one actor-isolated, non-suspending section, so a trigger cannot land between them and be lost. After an awaited worker call it checks cancellation, then:

```swift
switch result {
case .noWork:
  outcome = .noWork
case .completed:
  outcome = .completed
case let .blocked(reason):
  return .blocked(reason)
case .expired:
  return .expired
case let .retry(reason, serverHint):
  retryAttempt += 1
  guard let delay = retryPolicy.delay(
    forAttempt: retryAttempt,
    serverHint: serverHint,
    jitter: jitter()
  ) else {
    return .deferred(reason)
  }
  do { try await sleep(delay) } catch { return .cancelled }
  continue
}
```

After non-retry success, drain any triggers accumulated during the pass as one follow-up set and reset the retry counter. If none remain, return the latest outcome. `cancel()` cancels the task and clears only in-memory pending triggers; it never calls a store reset.

- [x] **Step 5: Sync and run coordinator tests**

Run: `./scripts/sync-source.sh`

Run: `./scripts/test-example.sh`

Expected: all coordinator and retry tests PASS under strict concurrency.

- [x] **Step 6: Commit**

```bash
git add -- Sources/OfflineFirst/SyncCoordinator.swift Example/App/OfflineFirst/SyncCoordinator.swift Example/Tests/OfflineFirst/SyncCoordinatorTests.swift
git commit -m "feat(offline): coordinate single-flight sync"
```

---

### Task 3: Prove durable atomic storage with a SwiftData reference adapter

**Files:**

- Create: `Example/Tests/OfflineFirst/SwiftDataReferenceStore.swift`
- Create: `Example/Tests/OfflineFirst/SwiftDataReferenceStoreTests.swift`

**Interfaces:**

- Produces only test-target types: `ReferenceTodo`, `ReferenceOutbox`, `ReferenceCursor`, and `@MainActor SwiftDataReferenceStore`. None are added to `Sources/OfflineFirst`.

- [x] **Step 1: Write failing on-disk contract tests**

Each test creates a unique `ModelConfiguration(url:)` under a temporary directory, never an in-memory container. Cover these exact assertions:

```swift
@Test @MainActor
func localWriteAndOutboxSurviveReopenTogether() throws {
  let first = try SwiftDataReferenceStore(url: storeURL)
  try first.saveTodoAndEnqueue(id: todoID, title: "local", operationID: operationID, scope: scope)
  let reopened = try SwiftDataReferenceStore(url: storeURL)
  #expect(try reopened.todo(id: todoID)?.title == "local")
  #expect(try reopened.pending(scope: scope).map(\.operationID) == [operationID])
}

@Test @MainActor
func thrownTransactionPersistsNeitherEntityNorOutbox() throws {
  let store = try SwiftDataReferenceStore(url: storeURL)
  #expect(throws: ReferenceStoreError.injectedFailure) {
    try store.saveTodoAndEnqueue(
      id: todoID,
      title: "lost",
      operationID: operationID,
      scope: scope,
      failBeforeCommit: true
    )
  }
  let reopened = try SwiftDataReferenceStore(url: storeURL)
  #expect(try reopened.todo(id: todoID) == nil)
  #expect(try reopened.pending(scope: scope).isEmpty)
}
```

Also test atomic acknowledgment+projection, atomic remote-page+cursor, duplicate operation IDs, per-account queries, tombstone retention, disk save failure propagation, and V1→V2 lightweight migration preserving a pending outbox row.

- [x] **Step 2: Run Example tests and verify failure**

Run: `./scripts/test-example.sh`

Expected: FAIL because the reference adapter does not exist.

- [x] **Step 3: Implement test-only persistent models and store**

`ReferenceTodo` stores stable ID, scope, title, revision, and tombstone. `ReferenceOutbox` stores operation ID, scope, entity ID, versioned command `Data`, optional base revision, sequence, attempt count, and next-attempt date. `ReferenceCursor` stores one cursor per scope. Unique attributes apply to operation ID and the composite keys encoded as stable strings.

Disable autosave and wrap each paired mutation in SwiftData's transaction API:

```swift
try context.transaction {
  upsertTodo(id: id, title: title, scope: scope)
  context.insert(ReferenceOutbox(
    operationID: operationID,
    scope: scope.rawValue,
    entityID: id,
    commandVersion: 1,
    payload: encodedCommand
  ))
  if failBeforeCommit { throw ReferenceStoreError.injectedFailure }
}
```

`apply(page:cursor:scope:)` performs all remote upserts/deletes and cursor replacement inside one transaction. `acknowledge(operationID:serverRevision:)` updates only the matching revision and removes only that exact outbox row, so a later local edit remains pending.

- [x] **Step 4: Add versioned migration fixture**

Define `ReferenceSchemaV1` and `ReferenceSchemaV2` as `VersionedSchema`; V2 adds optional retry metadata without renaming/deleting the outbox model. Define `ReferenceMigrationPlan.schemas` as `[V1.self, V2.self]` and a `.lightweight(fromVersion: V1.self, toVersion: V2.self)` stage. The migration test writes a V1 pending row, closes the container, opens V2 with the plan, and asserts the same operation ID and payload remain.

- [x] **Step 5: Run durable contract tests twice**

Run: `./scripts/test-example.sh`

Expected: PASS.

Run the same command again without deleting the per-test temporary roots until teardown.

Expected: PASS, proving the tests do not depend on first-run global state.

- [x] **Step 6: Commit**

```bash
git add -- Example/Tests/OfflineFirst/SwiftDataReferenceStore.swift Example/Tests/OfflineFirst/SwiftDataReferenceStoreTests.swift
git commit -m "test(offline): prove durable local transactions"
```

---

### Task 4: Add the failure-oriented sync contract harness

**Files:**

- Create: `Example/Tests/OfflineFirst/SyncContractHarness.swift`
- Create: `Example/Tests/OfflineFirst/SyncContractTests.swift`

**Interfaces:**

- Consumes: public Offline-First Core.
- Produces test-only `ReferenceSyncWorker`, `ReferenceLocalStore`, and `IdempotentServer`; production Core gains no payload/storage abstraction.

- [x] **Step 1: Define test-only value contracts**

```swift
struct PendingMutation: Equatable, Sendable {
  let operationID: UUID
  let scope: SyncScope
  let entityID: UUID
  let baseRevision: Int?
  let command: Command
  let sequence: Int
}

enum PushResult: Equatable, Sendable {
  case accepted(operationID: UUID, revision: Int)
  case retryable(RetryReason)
  case rejected
  case conflict(remoteRevision: Int)
}

struct RemotePage: Equatable, Sendable {
  let changes: [RemoteChange]
  let nextCursor: String
}
```

The local store actor exposes only feature-specific operations: `pending(scope:)`, `acknowledge`, `apply(page:)`, `markBlocked`, and read-only snapshots. The server actor records operation IDs and returns the original accepted revision when an ID is replayed.

- [x] **Step 2: Write failing semantic tests**

Add one named test for each requirement:

- server commits then drops the response; retrying the same operation ID creates one side effect;
- a second local edit remains pending after the first edit's late acknowledgment;
- partial batch success removes only accepted operations;
- duplicate remote page replay does not duplicate/change data and cursor advances once;
- injected page-apply failure leaves the previous cursor;
- expired cursor requests full reconciliation without clearing outbox;
- conflict preserves local intent and returns `.blocked(.conflict)`;
- tombstone survives ordinary reads and pull replay;
- auth failure returns `.blocked(.authentication)`;
- account switch/cancel prevents a late result from writing to the new scope;
- migration/storage/background-expiration outcomes remain distinct;
- concurrent coordinator triggers still make one worker pass at a time.

Each test asserts both visible entity state and remaining operation IDs; asserting only the returned enum is insufficient.

- [x] **Step 3: Run tests and verify failure**

Run: `./scripts/test-example.sh`

Expected: FAIL because the harness worker/store/server are not implemented.

- [x] **Step 4: Implement the smallest reference worker**

`ReferenceSyncWorker.run(scope:triggers:)` drains eligible mutations in sequence, pushes each with its stable ID, applies accepted acknowledgments atomically through the store, stops dependent work after conflict/rejection, then pulls and atomically applies one remote page+cursor. It translates only the test server's typed outcomes; no HTTP status or SDK error enters Core.

On cancellation, check `Task.isCancelled` after every awaited server/store operation and verify the scope before applying a late response. Do not retry inside the worker; `.retry` is returned once to the coordinator.

- [x] **Step 5: Run the entire Offline-First contract suite**

Run: `./scripts/test-example.sh`

Expected: all retry, coordinator, durable-store, semantic-contract, and existing tests PASS.

- [x] **Step 6: Commit**

```bash
git add -- Example/Tests/OfflineFirst/SyncContractHarness.swift Example/Tests/OfflineFirst/SyncContractTests.swift
git commit -m "test(offline): cover sync failure contracts"
```

---

### Task 5: Install the same Core for every preset

**Files:**

- Modify: `CLI/registry.json`
- Modify: `CLI/src/types/registry.schema.ts`
- Modify: `CLI/src/services/InitService.ts`
- Modify: `CLI/src/commands/init.ts`
- Modify: `CLI/src/__tests__/types/registry.schema.test.ts`
- Modify: `CLI/src/__tests__/services/InitService.test.ts`
- Modify: `CLI/src/__tests__/commands/init.test.ts`
- Modify: `CLI/src/__tests__/commands/helpers.ts`

**Interfaces:**

- Extends `InitializeProjectInput` with `includeOfflineFirst: boolean`.
- Produces `--offline-first`, `--no-offline-first`, persisted `offlineFirst`, and `OfflineFirst/*.swift` installation.

- [x] **Step 1: Write failing registry and initializer tests**

```ts
expect(registry.offlineFirst.core).toEqual([
  "OfflineFirst/SyncTypes.swift",
  "OfflineFirst/RetryPolicy.swift",
  "OfflineFirst/SyncCoordinator.swift",
]);

it.each(["native", "mvvm", "tca"] as const)("installs identical core for %s", async (preset) => {
  await initializer.initialize({
    cwd: "/project",
    config: {
      componentsPath: "Components",
      themePath: "Theme",
      prefix: "CN",
      preset,
      navigation: false,
      offlineFirst: true,
    },
    includeSdui: false,
    includeNavigationRouter: false,
    includeOfflineFirst: true,
  });
  expect(transaction.apply).toHaveBeenCalledWith(expect.objectContaining({
    files: expect.arrayContaining([
      expect.objectContaining({ destinationPath: "/project/OfflineFirst/SyncCoordinator.swift" }),
    ]),
  }));
});
```

Add command tests for fresh default false, explicit positive/negative flags, interactive prompt, omitted rerun flag preserving true, explicit disable retaining files, and all six preset × enabled/disabled combinations.

- [x] **Step 2: Run focused CLI tests and verify failure**

Run: `npm --prefix CLI test -- src/__tests__/types/registry.schema.test.ts src/__tests__/services/InitService.test.ts src/__tests__/commands/init.test.ts`

Expected: FAIL because the manifest, initializer mapping, and command flags are absent.

- [x] **Step 3: Extend registry schema and exact manifest**

```ts
offlineFirst: z.object({
  core: z.array(z.string()).length(3),
}),
```

Add the three paths to `CLI/registry.json` in the same order as the test. The initializer maps each `OfflineFirst/` source into the sibling `OfflineFirst` directory derived from `dirname(componentsPath)`. Reject a wrong prefix or missing source before transaction apply.

- [x] **Step 4: Add CLI flags and merge semantics**

```ts
.option("--offline-first", "Install the external-system-agnostic sync core")
.option("--no-offline-first", "Disable Offline-First in config without deleting files")
```

Use `rawOptions.offlineFirst ?? existing?.offlineFirst ?? false`; prompt only when neither positive nor negative form was explicit. Pass `includeOfflineFirst: config.offlineFirst` to the initializer. The success output must say that a durable local adapter and external gateway are still required; do not call the generated app production-ready.

- [x] **Step 5: Run focused and full CLI tests**

Run: `npm --prefix CLI test -- src/__tests__/types/registry.schema.test.ts src/__tests__/services/InitService.test.ts src/__tests__/commands/init.test.ts`

Expected: PASS.

Run: `npm --prefix CLI run typecheck`

Expected: PASS.

- [x] **Step 6: Commit**

```bash
git add -- CLI/registry.json CLI/src/types/registry.schema.ts CLI/src/services/InitService.ts CLI/src/commands/init.ts CLI/src/__tests__/types/registry.schema.test.ts CLI/src/__tests__/services/InitService.test.ts CLI/src/__tests__/commands/init.test.ts CLI/src/__tests__/commands/helpers.ts
git commit -m "feat(cli): install optional offline first core"
```

---

### Task 6: Document integration boundaries and verify everything

**Files:**

- Create: `docs/offline-first.md`
- Modify: `Sources/README.md`
- Modify: `CLI/README.md`
- Modify: `README.md`
- Modify only if verification exposes a defect in files already owned by this plan.

**Interfaces:**

- Consumes: all prior tasks and the four Archify diagrams.
- Produces: user integration guidance and final verification evidence; no new runtime API.

- [x] **Step 1: Write the integration guide**

Document:

- the local read and atomic write flows;
- exact `SyncWorker` contract and coordinator construction;
- Native `@State`, MVVM ViewModel, and TCA Effect bridges without sharing presentation state;
- operation ID/server idempotency contract;
- outbox fields, cursor transaction, conflicts, tombstones, account scope, migrations, retry ownership, cancellation, background best effort, sanitized logs, and Keychain boundary;
- SwiftData/GRDB/Core Data/CloudKit/PowerSync/REST/GraphQL as outer adapter choices, not Core dependencies;
- what `--offline-first` installs and what it deliberately cannot configure.

Link `docs/init-option-offline-first.html` and the reviewed spec. Keep code examples aligned with the public signatures; do not invent an additional repository protocol in Shared Core.

- [x] **Step 2: Update READMEs and source map**

Add `OfflineFirst/` to `Sources/README.md`, add both CLI flags and rerun semantics to `CLI/README.md`, and link the guide from the root README. State that copied files are owned by the user and disabling the config does not delete them.

- [x] **Step 3: Run the forbidden-import scan**

Run: `rg -n "^import (SwiftUI|ComposableArchitecture|SwiftData|CoreData)|URLSession|Router" Sources/OfflineFirst`

Expected: no output.

- [x] **Step 4: Run all relevant verification**

Run: `./scripts/test-sync-source.sh`

Expected: PASS.

Run: `./scripts/test-cli.sh`

Expected: PASS.

Run: `./scripts/test-example.sh`

Expected: PASS, including strict-concurrency and durable-store contracts.

Run: `git diff --check`

Expected: no output and exit 0.

- [x] **Step 5: Run the repository suite**

Run: `./scripts/test-all.sh`

Expected: CLI, sync-source, architecture preset fixture, Offline-First, and existing Example tests PASS.

- [x] **Step 6: Commit documentation**

```bash
git add -- docs/offline-first.md Sources/README.md CLI/README.md README.md
git commit -m "docs: explain offline first integration"
```
