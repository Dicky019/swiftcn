# Integrating Offline-First Core

`swiftcn init --offline-first` copies three files you own into the `OfflineFirst/` directory beside your configured components directory:

- `SyncTypes.swift`: scope, triggers, typed pass results/outcomes, and `SyncWorker`.
- `RetryPolicy.swift`: bounded exponential retry delays with full jitter and server hints.
- `SyncCoordinator.swift`: one actor coordinating one account/store scope.

The same files work with `--preset native`, `mvvm`, and `tca`. The capability defaults to disabled. On rerun, omitting the flag preserves your existing setting; `--no-offline-first` disables the setting and retains copied files and runtime data. For `App/Components`, the destination is `App/OfflineFirst`; for `Components`, it is `OfflineFirst`.

See the [architecture diagram](init-option-offline-first.html) and [reviewed design](superpowers/specs/2026-09-14-init-presets-clean-architecture-design.md#capability-offline-first). These templates provide scheduling contracts. Your application supplies durable storage, a feature worker, and an external gateway before it can sync real data.

## Local reads and writes

Read and observe the local source of truth from your UI. A remote refresh writes reconciled results into that same store. Offline reads and a failed refresh must preserve previously available data.

For each local intent:

1. Validate the command with feature/domain rules.
2. In one durable transaction, update the visible local projection and enqueue a versioned outbox command with a stable operation ID.
3. Report “saved locally” only after that transaction commits.
4. Request `.localMutation` on the scoped coordinator.

Two independent calls that separately save an entity and enqueue work cannot provide this guarantee. If the outbox insertion fails, neither change should remain committed. Disable implicit autosave while making paired mutations, propagate storage errors, and roll back dirty context state after a failed save. A later successful transaction must not accidentally persist the failed one.

“Saved locally” and “accepted by the server” are different feature outcomes. Present them according to your product's needs; `SyncOutcome.completed` describes a worker drain, not an acknowledgment for every entity in your UI.

## Worker and coordinator

The only shared worker boundary is:

```swift
public protocol SyncWorker: Sendable {
  func run(scope: SyncScope, triggers: Set<SyncTrigger>) async -> SyncPassResult
}
```

Implement the worker inside your feature/application layer. It pushes eligible mutations in dependency order, acknowledges accepted operations, pulls remote changes, and reconciles through your application-owned ports. Return one typed result per pass:

| Worker result | Coordinator outcome |
| --- | --- |
| `.noWork` | `.noWork` |
| `.completed` | `.completed` |
| `.retry(reason:serverHint:)` | Retries; `.deferred(reason)` when the budget runs out |
| `.blocked(reason)` | `.blocked(reason)` without retry |
| `.expired` | `.expired` without retry |
| Coordinator cancellation | `.cancelled` after the current awaited operation returns |

Retry reasons are `.transport`, `.timeout`, and `.serverBusy`. Block reasons are `.authentication`, `.conflict`, `.permanentRejection`, `.storage`, and `.migration`. Map backend errors to these categories inside the gateway/worker; HTTP status, SDK errors, payloads, and credentials never enter the Core.

Construct one coordinator per account and store at your composition root. `TodoSyncWorker`, `localAdapter`, and `gateway` below represent application-owned integrations; they are not generated types.

```swift
let worker = TodoSyncWorker(local: localAdapter, gateway: gateway)
let coordinator = SyncCoordinator(
  scope: SyncScope(rawValue: "account-id/store-id"),
  worker: worker,
  retryPolicy: RetryPolicy(
    maximumAttempts: 3,
    baseDelay: .seconds(2),
    maximumDelay: .seconds(30)
  )
)
let outcome = await coordinator.request(.launch)
```

A scope must contain a nonempty, non-whitespace identifier. Use stable, unambiguous account/store identifiers, and keep a coordinator scoped to those identifiers for its entire lifetime.

Concurrent requests share a single drain and its outcome. Triggers arriving during a pass coalesce into a set consumed by a follow-up pass. Failed-pass triggers survive retries, and triggers arriving during retry sleep join the next retry. There is at most one active worker pass. The final pending-trigger check and task cleanup occur together on the coordinator actor.

The coordinator does not own or observe entity state. A worker must leave durable work in its adapter when it returns deferred, blocked, expired, or cancelled. The next lifecycle or user trigger can resume that work; Core has no perpetual background retry daemon.

## Presentation bridges

Presentation state belongs to each presentation style. All three bridges call the same scoped coordinator and continue reading entities from local observation.

### Native SwiftUI

In a feature view with an injected `SyncCoordinator<TodoSyncWorker>`:

```swift
@State private var syncOutcome: SyncOutcome?
let coordinator: SyncCoordinator<TodoSyncWorker>

// Attach these to the view displaying locally observed rows:
.task {
  syncOutcome = await coordinator.request(.launch)
}
.refreshable {
  syncOutcome = await coordinator.request(.manual)
}
```

Send `.foreground` when the scene becomes active. After an atomic local write commits, send `.localMutation`. A connectivity monitor can send `.connectivityHint`, which is a scheduling hint and does not prove backend availability.

### MVVM

A ViewModel owns its presentation outcome and receives the coordinator through composition:

```swift
@MainActor
@Observable
final class SyncViewModel<Worker: SyncWorker> {
  private(set) var outcome: SyncOutcome?
  @ObservationIgnored private let coordinator: SyncCoordinator<Worker>

  init(coordinator: SyncCoordinator<Worker>) {
    self.coordinator = coordinator
  }

  func refresh() async {
    outcome = await coordinator.request(.manual)
  }
}
```

Keep local snapshot observation in your feature ViewModel/repository integration. Requesting sync does not replace locally observed entities with a separate remote result array.

### TCA

Keep `SyncOutcome?` in feature state, inject the coordinator into your feature's dependencies or reducer composition, and map the result back through an action:

```swift
case .refresh:
  return .run { [coordinator] send in
    let outcome = await coordinator.request(.manual)
    await send(.syncFinished(outcome))
  }

case let .syncFinished(outcome):
  state.syncOutcome = outcome
  return .none
```

Here `.refresh`, `.syncFinished`, `state.syncOutcome`, and the injected `coordinator` belong to your feature. Core does not import TCA. Cancelling a presentation effect alone does not cancel the shared coordinator task. Scope teardown must explicitly call `await coordinator.cancel()`; do not let one transient view cancel work shared by other screens.

## Durable outbox and idempotency

A feature's outbox should persist:

| Field | Purpose |
| --- | --- |
| Stable operation ID | Reuse across retries and process restarts |
| Account/store scope and entity ID | Isolate ownership and target |
| Versioned command payload | Decode and migrate queued intent |
| Base revision when available | Detect stale writes and conflicts |
| Sequence/dependencies | Preserve required ordering |
| Attempt count and next-attempt date | Resume feature-owned scheduling across launches |

Do not store tokens, closures, network request objects, or vendor SDK objects in the outbox. Store credentials in Keychain and resolve them at the gateway boundary.

A server can commit a write and lose its response. Replay the same operation ID. The server must durably deduplicate IDs within the correct account scope and return the original acknowledgment. Its retention period must cover the client's possible replay window. A stable client ID alone does not provide exactly-once effects; server deduplication is required.

Acknowledge a specific operation in one transaction with the corresponding local revision/projection update. Delete only that operation's outbox row. A late acknowledgment for an earlier edit must preserve a newer local projection and the newer pending operation. Verify the acknowledgment matches the operation and scope you sent.

## Pull, reconciliation, and deletion

Apply a remote page and advance its cursor in one durable transaction. If applying any change or saving the transaction fails, retain the previous cursor and local data. Page replay must be idempotent, including deletes and revision handling.

An expired cursor requests feature-owned full reconciliation. Keep the existing projection and outbox while fetching a complete snapshot; record that reconciliation is required and install the new checkpoint only when reconciliation commits. Cursor expiration is a backend protocol event; `.expired` represents an expired execution window, such as background expiration. Map these separately in your worker.

Conflict policy belongs to your domain. A safe reference policy blocks conflicting work, retains local intent, and stops dependent commands until resolution. Define whether unrelated work may continue, how rebasing changes base revisions, and how delete-versus-update conflicts resolve. Permanent rejection and authentication waits also retain the command until the feature explicitly resolves it.

Retain tombstones until your sync protocol proves the deletion has been covered. Hide tombstoned rows from ordinary UI reads while keeping them available to reconciliation. Replaying an older remote update must not resurrect a deleted row.

## Scope, cancellation, and lifecycle

On sign-out or account/store replacement:

1. Cancel the old coordinator.
2. Fence the old adapter scope so a late acknowledgment/page cannot commit into the new account.
3. Compose a new worker and coordinator for the new scope.

Check cancellation after every awaited gateway/store operation and before applying responses. Recheck scope within the adapter's atomic commit, because checking before an await leaves a race. Cancelling a request cannot retract a write already accepted by the server; leave its operation pending until safe acknowledgment or replay reconciliation.

`cancel()` cancels the coordinator task and clears pending in-memory triggers. It does not delete local entities or reset the outbox. A worker or injected sleeper that ignores cancellation can delay completion; gateways must provide their own bounded timeouts and cooperate with cancellation. The coordinator waits for the current pass to return, preserving the single-flight guarantee. A fresh request arriving after `cancel()` waits for that retiring flight, then starts or joins a new flight. If that waiting caller is itself cancelled, it returns `.cancelled` without enqueueing its trigger or cancelling other callers' replacement work.

BackgroundTasks integration is best effort and application-owned. Request a pass when granted time, map an expired execution window distinctly, cancel on expiration, and finish the system task according to platform rules. Durable local intent must remain resumable after process termination. Init does not add background entitlements or configure a background scheduler.

## Retry ownership and migrations

`maximumAttempts` counts retries after the initial pass: `3` permits at most four consecutive failed passes in that retry cycle. Retry delays start at attempt `1`, double to `maximumDelay`, and apply full jitter in `0...1`. Server hints act as a minimum delay, capped by `maximumDelay`. Negative hints cannot produce a negative delay; out-of-range jitter is clamped and NaN uses zero. After a successful pass, a coalesced follow-up begins a fresh retry cycle.

Core owns scheduling within the current drain. The worker returns `.retry` once per failed pass instead of independently sleeping/retrying the same request. The adapter may own persistent eligibility timestamps and attempt metadata for future drains; define how those interact with the current budget so retries do not multiply across layers.

Use the injected initializer with `SyncSleeper` and `SyncJitter` for deterministic tests. Production composition uses `Task.sleep` and random jitter. The injected sleeper should throw when cancelled; a thrown sleep ends the drain with `.cancelled`.

Migrate persisted entities, commands, retry metadata, and cursors with the feature's durable schema. Test actual disk reopening and migration with pending outbox data. An undecodable command or a failed migration must not silently erase queued intent. Map a migration failure to `.blocked(.migration)` and disk/save failure to `.blocked(.storage)`.

## Adapter choices and verification

SwiftData, GRDB, and Core Data can implement the local adapter. CloudKit, PowerSync, REST, GraphQL, or another backend SDK can implement the external adapter. Those choices bring their own transaction, auth, conflict, and checkpoint contracts; keep their types outside Core.

Init installs no vendor dependency, endpoint, transport implementation, production in-memory store, conflict resolver, payload schema, Keychain setup, or background configuration. It cannot choose an account model or migrate your application's data.

Repository-only fixtures under `Example/Tests/OfflineFirst/` demonstrate durable SwiftData transactions and lightweight migration plus a deterministic failure harness. They are never copied into user projects. Validate your real adapter for lost responses, late acknowledgments, partial batches, page replay, apply/save failures, expired cursors, conflicts, tombstones, account switches, auth waits, migration failure, and background expiration.

Log sanitized scope identifiers, operation correlation IDs, counts, and outcome categories as needed. Avoid credentials, command payloads, personal data, and raw server responses. Keep logging and credential handling in your application/platform adapters.
