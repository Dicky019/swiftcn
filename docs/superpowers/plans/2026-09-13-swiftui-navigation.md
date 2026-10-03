# SwiftUI Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dependency-free, typed `Router<Route>` template with predictable stack replacement, expose it through `swiftcn add navigation`, migrate the Example app, and document native MVVM and direct TCA usage.

**Architecture:** `Router<Route>` is a small `@MainActor @Observable` owner of a SwiftUI `[Route]` path. MVVM apps use it directly with `NavigationStack`; TCA apps keep navigation in `StackState` and `@Presents` without wrapping TCA in `Router`. `Sources/` remains canonical and is synced into the Example app.

**Tech Stack:** Swift 6, SwiftUI and Observation (iOS 17+), Swift Testing, TypeScript, Commander.js, Zod, Vitest, Tuist.

**Spec:** `docs/superpowers/specs/2026-09-13-swiftui-navigation-design.md`

## Global Constraints

- Keep the public name `Router`. Do not introduce `CNRouter`.
- Use native `NavigationStack` and `[Route]`. Do not add a navigation dependency.
- Keep the public surface to `path`, `init(path:)`, `push`, `pop`, `popToRoot`, `replace(with:)`, and `replaceLast(_:with:)`.
- `replaceLast` must mutate `path` once, treat nonpositive counts as a no-op, and replace the whole path when the count exceeds its size.
- Keep route values lightweight and `Hashable`; screens must load mutable business data by identifier.
- Do not add an MVVM adapter for TCA. Document `StackState`, `StackAction`, `@Presents`, and scoped stores directly.
- Preserve unrelated staged changes in `.gitignore`, `AGENTS.md`, and `CLAUDE.md`.
- Use two-space indentation and the repository Swift file header.
- Keep navigation in `Sources/Navigation/` and install it beside, never inside, the configured components directory.
- Run `./scripts/sync-source.sh` after changing `Sources/`.

## File Map

### Create

- `Sources/Navigation/Router.swift` — canonical optional navigation template.
- `Example/App/Navigation/Router.swift` — generated copy created by the sync script.
- `Example/Tests/RouterTests.swift` — focused behavior tests.
- `CLI/src/__tests__/types/registry.schema.test.ts` — validates the real registry entry.
- `docs/navigation.md` — MVVM, state-heavy, enterprise, and TCA navigation guide.

### Modify

- `Example/App/Navigation/MainTabView.swift` — own `Router<ComponentRoute>`.
- `Example/App/Features/Components/Views/ComponentsCoordinatorView.swift` — bind `NavigationStack` to `router.path`.
- `Example/App/Features/Components/Views/ComponentGalleryView.swift` — push typed routes and update preview injection.
- `scripts/sync-source.sh` — sync only `Router.swift` into the app-owned Example navigation directory.
- `CLI/registry.json` — register the navigation template.
- `CLI/src/commands/add.ts` — install navigation beside the configured components directory.
- `CLI/src/__tests__/commands/add.test.ts` — verify the navigation destination.
- `CLI/src/__tests__/commands/helpers.ts` — provide the navigation registry fixture.
- `CLI/src/commands/list.ts` — replace the inaccurate all-components-SDUI hint.
- `CLI/src/__tests__/commands/list.test.ts` — cover the corrected hint.
- `README.md`, `Sources/README.md`, `CLI/README.md`, `Example/README.md` — expose and explain navigation.

### Delete

- `Example/App/Navigation/AppRouter.swift` — superseded by the canonical `Router`.
- `Example/App/Navigation/AppRoute.swift` — unused wrapper route.

---

## Task 1: Add the typed Router and migrate the Example app

**Files:**

- Create: `Sources/Navigation/Router.swift`
- Create through sync: `Example/App/Navigation/Router.swift`
- Create: `Example/Tests/RouterTests.swift`
- Modify: `scripts/sync-source.sh:29-44`
- Modify: `Example/App/Navigation/MainTabView.swift:19`
- Modify: `Example/App/Features/Components/Views/ComponentsCoordinatorView.swift:11-19`
- Modify: `Example/App/Features/Components/Views/ComponentGalleryView.swift:11-54`
- Delete: `Example/App/Navigation/AppRouter.swift`
- Delete: `Example/App/Navigation/AppRoute.swift`

**Interfaces:**

```swift
@MainActor
@Observable
public final class Router<Route: Hashable> {
  public var path: [Route]

  public init(path: [Route] = [])
  public func push(_ route: Route)
  public func pop()
  public func popToRoot()
  public func replace(with routes: [Route])
  public func replaceLast(_ count: Int, with routes: [Route])
}
```

- [ ] **Step 1: Add the failing Router behavior tests**

Create `Example/Tests/RouterTests.swift`:

```swift
//
//  RouterTests.swift
//  Example/Tests
//
//  Created by Dicky Darmawan on 13/09/26.
//

import Testing
@testable import Example

@Suite("Router Tests")
@MainActor
struct RouterTests {
  enum Route: Hashable {
    case home
    case cart
    case shipping
    case payment
    case confirmation
    case receipt
  }

  @Test("push appends a route")
  func pushAppendsRoute() {
    let router = Router<Route>(path: [.home])

    router.push(.cart)

    #expect(router.path == [.home, .cart])
  }

  @Test("pop removes the last route")
  func popRemovesLastRoute() {
    let router = Router<Route>(path: [.home, .cart])

    router.pop()

    #expect(router.path == [.home])
  }

  @Test("pop on an empty path is a no-op")
  func popOnEmptyPathIsNoOp() {
    let router = Router<Route>()

    router.pop()

    #expect(router.path.isEmpty)
  }

  @Test("popToRoot clears the path")
  func popToRootClearsPath() {
    let router = Router<Route>(path: [.home, .cart, .shipping])

    router.popToRoot()

    #expect(router.path.isEmpty)
  }

  @Test("replace installs an entire path")
  func replaceInstallsEntirePath() {
    let router = Router<Route>(path: [.home, .cart])

    router.replace(with: [.confirmation, .receipt])

    #expect(router.path == [.confirmation, .receipt])
  }

  @Test("replaceLast preserves the prefix and replaces the suffix")
  func replaceLastPreservesPrefix() {
    let router = Router<Route>(
      path: [.home, .cart, .shipping, .payment]
    )

    router.replaceLast(2, with: [.confirmation, .receipt])

    #expect(router.path == [.home, .cart, .confirmation, .receipt])
  }

  @Test("replaceLast replaces the whole path when count is oversized")
  func replaceLastWithOversizedCountReplacesWholePath() {
    let router = Router<Route>(path: [.home, .cart])

    router.replaceLast(99, with: [.receipt])

    #expect(router.path == [.receipt])
  }

  @Test("replaceLast ignores nonpositive counts")
  func replaceLastIgnoresNonpositiveCounts() {
    let router = Router<Route>(path: [.home, .cart])

    router.replaceLast(0, with: [.shipping])
    router.replaceLast(-1, with: [.payment])

    #expect(router.path == [.home, .cart])
  }
}
```

- [ ] **Step 2: Run the test and verify the expected failure**

Run:

```bash
./scripts/test-example.sh
```

Expected: compilation fails because `Router` is not yet in scope. If it fails for an unrelated reason, stop and diagnose that failure before continuing.

- [ ] **Step 3: Implement the minimum Router**

Create `Sources/Navigation/Router.swift`:

```swift
//
//  Router.swift
//  Sources/Navigation
//
//  Created by Dicky Darmawan on 13/09/26.
//

import Observation

@MainActor
@Observable
public final class Router<Route: Hashable> {
  public var path: [Route]

  public init(path: [Route] = []) {
    self.path = path
  }

  public func push(_ route: Route) {
    path.append(route)
  }

  public func pop() {
    guard !path.isEmpty else { return }
    path.removeLast()
  }

  public func popToRoot() {
    path.removeAll()
  }

  public func replace(with routes: [Route]) {
    path = routes
  }

  public func replaceLast(_ count: Int, with routes: [Route]) {
    guard count > 0 else { return }
    let retainedCount = Swift.max(0, path.count - count)
    path = Array(path.prefix(retainedCount)) + routes
  }
}
```

The final assignment in `replaceLast` is deliberate: observers see the replacement as one path mutation.

- [ ] **Step 4: Add the dedicated Navigation sync rule**

In `scripts/sync-source.sh`, keep the existing `--delete` loop for `Components`, `Theme`, and `SDUI`. Immediately after that loop, add:

```bash
NAVIGATION_SOURCE="$SRC/Navigation/Router.swift"
NAVIGATION_DESTINATION="$DEST/Navigation/Router.swift"

if [ -f "$NAVIGATION_SOURCE" ]; then
    rsync -a --checksum --itemize-changes $DRY_RUN "$NAVIGATION_SOURCE" "$NAVIGATION_DESTINATION"
else
    echo "Warning: $NAVIGATION_SOURCE not found, skipping"
fi
```

Change the non-dry-run summary to:

```bash
echo "Synced Sources/{Components,Theme,SDUI} and Sources/Navigation/Router.swift → Example/App/"
```

Do not add `Navigation` to `SUBDIRS`: that would let `rsync --delete` remove `MainTabView.swift`, `ComponentRoute.swift`, and other app-owned files from `Example/App/Navigation/`.

- [ ] **Step 5: Sync the canonical template into the Example app**

Run:

```bash
./scripts/sync-source.sh
```

Expected: `Example/App/Navigation/Router.swift` is created and the existing app-owned navigation files remain present.

- [ ] **Step 6: Verify the synced file**

Run:

```bash
cmp -s Sources/Navigation/Router.swift Example/App/Navigation/Router.swift
```

Expected: exit status 0 with no output.

- [ ] **Step 7: Migrate the Example app to Router**

In `Example/App/Navigation/MainTabView.swift`, replace:

```swift
@State private var router = AppRouter()
```

with:

```swift
@State private var router = Router<ComponentRoute>()
```

In `Example/App/Features/Components/Views/ComponentsCoordinatorView.swift`, use:

```swift
@Environment(Router<ComponentRoute>.self) private var router

var body: some View {
  @Bindable var router = router

  NavigationStack(path: $router.path) {
    ComponentGalleryView()
      .navigationDestination(for: ComponentRoute.self) { route in
        switch route {
        case .detail(let component):
          ComponentDetailView(component: component)
        }
      }
  }
}
```

In `Example/App/Features/Components/Views/ComponentGalleryView.swift`:

- Replace `@Environment(AppRouter.self)` with `@Environment(Router<ComponentRoute>.self)`.
- Replace `router.navigate(to: .detail(component))` with `router.push(.detail(component))`.
- Replace the preview's `.environment(AppRouter())` with `.environment(Router<ComponentRoute>())`.

Delete `Example/App/Navigation/AppRouter.swift` and `Example/App/Navigation/AppRoute.swift`. Do not alter `ComponentRoute.swift`.

- [ ] **Step 8: Run the focused Example test suite**

Run:

```bash
./scripts/test-example.sh
```

Expected: all Example tests pass, including all eight Router tests.

- [ ] **Step 9: Verify the sync is clean**

Run:

```bash
./scripts/sync-source.sh --dry-run
git diff --check
```

Expected: the sync reports no pending source copies and `git diff --check` prints nothing.

- [ ] **Step 10: Commit only Task 1 files**

Run:

```bash
git add -- Sources/Navigation/Router.swift Example/App/Navigation/Router.swift Example/Tests/RouterTests.swift scripts/sync-source.sh Example/App/Navigation/MainTabView.swift Example/App/Features/Components/Views/ComponentsCoordinatorView.swift Example/App/Features/Components/Views/ComponentGalleryView.swift
git add -u -- Example/App/Navigation/AppRouter.swift Example/App/Navigation/AppRoute.swift
git diff --cached --check
git commit -m "feat(navigation): add typed router"
```

---

## Task 2: Register navigation in the CLI

**Files:**

- Create: `CLI/src/__tests__/types/registry.schema.test.ts`
- Modify: `CLI/registry.json:139-158`
- Modify: `CLI/src/__tests__/commands/helpers.ts:35-65`
- Modify: `CLI/src/__tests__/commands/add.test.ts:1-75`
- Modify: `CLI/src/commands/add.ts:86-95`
- Modify: `CLI/src/__tests__/commands/list.test.ts:157-174`
- Modify: `CLI/src/commands/list.ts:158`

**Interfaces:**

```text
npx swiftcn@latest add navigation
```

The registry key is `navigation` and installs only `Navigation/Router.swift`. The command derives a sibling destination from `componentsPath`: `Components` becomes `Navigation`, and `App/Components` or `App/UI` becomes `App/Navigation`.

- [ ] **Step 1: Add a failing test for the real registry**

Create `CLI/src/__tests__/types/registry.schema.test.ts`:

```typescript
import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";
import { registrySchema } from "../../types/registry.schema.js";

describe("registry.json", () => {
  it("registers the navigation template", async () => {
    const raw = await readFile(
      new URL("../../../registry.json", import.meta.url),
      "utf8"
    );
    const registry = registrySchema.parse(JSON.parse(raw));

    expect(registry.components.navigation).toEqual({
      name: "Router",
      description: "A typed navigation router for SwiftUI",
      files: ["Navigation/Router.swift"],
    });
  });
});
```

- [ ] **Step 2: Run the registry test and verify the expected failure**

Run:

```bash
npm --prefix CLI test -- src/__tests__/types/registry.schema.test.ts
```

Expected: the assertion fails because `registry.components.navigation` is undefined.

- [ ] **Step 3: Add the navigation registry entry**

Add this sibling entry in `CLI/registry.json`:

```json
"navigation": {
  "name": "Router",
  "description": "A typed navigation router for SwiftUI",
  "files": [
    "Navigation/Router.swift"
  ]
}
```

Do not add `sdui_files` or `dependencies`.

- [ ] **Step 4: Run the registry test**

Run:

```bash
npm --prefix CLI test -- src/__tests__/types/registry.schema.test.ts
```

Expected: the test passes.

- [ ] **Step 5: Add the navigation command fixture**

In `CLI/src/__tests__/commands/helpers.ts`, add:

```typescript
export const sampleNavigation: ComponentWithId = {
  id: "navigation",
  name: "Router",
  description: "A typed navigation router for SwiftUI",
  files: ["Navigation/Router.swift"],
};
```

- [ ] **Step 6: Add the failing navigation destination test**

In `CLI/src/__tests__/commands/add.test.ts`:

- Add `import path from "node:path";`.
- Add `sampleNavigation` to the import from `./helpers.js`.
- Add this test inside `describe("add <component>")`:

```typescript
it("installs navigation beside the configured components directory", async () => {
  const config = {
    ...sampleConfig,
    componentsPath: "App/UI",
  };
  const container = await runAdd(["navigation"], {
    config: {
      load: vi.fn().mockResolvedValue(config),
      write: vi.fn(),
      exists: vi.fn().mockResolvedValue(true),
    },
    registry: {
      load: vi.fn().mockResolvedValue({}),
      getComponent: vi.fn().mockResolvedValue(sampleNavigation),
      listComponents: vi.fn().mockResolvedValue(sampleComponents),
      getThemeFiles: vi.fn().mockResolvedValue([]),
      getSduiFiles: vi.fn().mockResolvedValue([]),
    },
    fetcher: {
      fetchComponents: vi.fn().mockResolvedValue({
        added: [path.join(process.cwd(), "App/Navigation/Router.swift")],
        skipped: [],
      }),
      fetchTheme: vi.fn(),
      fetchSdui: vi.fn(),
    },
  });

  expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
    sampleNavigation.files,
    path.join(process.cwd(), "App/Navigation"),
    { force: undefined }
  );
});
```

- [ ] **Step 7: Run the add test and verify the expected failure**

Run:

```bash
npm --prefix CLI test -- src/__tests__/commands/add.test.ts
```

Expected: the new assertion fails because the command still passes `App/UI` as the destination.

- [ ] **Step 8: Derive the optional navigation destination**

In `CLI/src/commands/add.ts`, replace:

```typescript
const destDir = path.join(cwd, config.componentsPath);
```

with:

```typescript
const installPath =
  componentName.toLowerCase() === "navigation"
    ? path.join(path.dirname(config.componentsPath), "Navigation")
    : config.componentsPath;
const destDir = path.join(cwd, installPath);
```

Do not add `navigationPath` to `swiftcn.json` and do not modify `swiftcn init`. The optional directory is created by the existing file-copy flow only when navigation is installed.

In `printAddHelp()`, replace the configured-component-directory wording with:

```typescript
ui.line("Add a component or optional feature to your project.");
ui.line("Copies its source files into the appropriate directory.");
```

Also change the command description to `Add a component or optional feature to your project`. Keep the existing `swiftcn add <component>` command syntax for backward compatibility.

- [ ] **Step 9: Run the add test**

Run:

```bash
npm --prefix CLI test -- src/__tests__/commands/add.test.ts
```

Expected: all add-command tests pass.

- [ ] **Step 10: Change the list hint test first**

In `CLI/src/__tests__/commands/list.test.ts`, rename the compact-list hint test to `shows the registry details hint` and use these assertions:

```typescript
expect(output).toContain(
  "Use --verbose to see variants, sizes, and SDUI support."
);
expect(output).not.toContain("All components are SDUI-compatible.");
```

- [ ] **Step 11: Run the list test and verify the expected failure**

Run:

```bash
npm --prefix CLI test -- src/__tests__/commands/list.test.ts
```

Expected: the new hint assertion fails while the old all-components-SDUI hint is still rendered.

- [ ] **Step 12: Correct the compact-list hint**

In `CLI/src/commands/list.ts`, replace the old hint with:

```typescript
ui.hint("Use --verbose to see variants, sizes, and SDUI support.");
```

This keeps the output truthful now that `navigation` intentionally has no SDUI extension.

- [ ] **Step 13: Run CLI tests and type checking**

Run:

```bash
npm --prefix CLI test -- src/__tests__/commands/list.test.ts
npm --prefix CLI test -- src/__tests__/commands/add.test.ts
./scripts/test-cli.sh
npm --prefix CLI run build
```

Expected: the focused test, complete CLI test suite, and TypeScript build all pass.

- [ ] **Step 14: Commit only Task 2 files**

Run:

```bash
git add -- CLI/registry.json CLI/src/commands/add.ts CLI/src/commands/list.ts CLI/src/__tests__/commands/helpers.ts CLI/src/__tests__/commands/add.test.ts CLI/src/__tests__/commands/list.test.ts CLI/src/__tests__/types/registry.schema.test.ts
git diff --cached --check
git commit -m "feat(cli): register navigation template"
```

---

## Task 3: Document MVVM, state-heavy, enterprise, and TCA usage

**Files:**

- Create: `docs/navigation.md`
- Modify: `README.md:31-79`
- Modify: `Sources/README.md:1-44`
- Modify: `CLI/README.md:15-42`
- Modify: `Example/README.md:42-65`

**Documentation contract:**

- Installation command is `npx swiftcn@latest add navigation`.
- MVVM examples use `Router<Route>` and native `NavigationStack`.
- TCA examples use TCA navigation state directly, never `Router`.
- `replaceLast` documents all three edge cases and the two-screen replacement example.
- Deep links and restoration validate external input before assigning a path.
- Each tab owns its own router/path.

- [ ] **Step 1: Write the navigation guide**

Create `docs/navigation.md` with these sections in this order:

1. `# Navigation`
2. `## Install`
3. `## Native SwiftUI and MVVM`
4. `## Router operations`
5. `## Replace the last screens`
6. `## Tabs`
7. `## Sheets and full-screen covers`
8. `## Deep links and state restoration`
9. `## The Composable Architecture`
10. `## Common mistakes`

Use this complete native example:

```swift
import SwiftUI

enum AppRoute: Hashable {
  case product(id: Int)
  case cart
  case shipping
  case payment
  case confirmation(orderID: Int)
  case receipt(orderID: Int)
}

struct AppRootView: View {
  @State private var router = Router<AppRoute>()

  var body: some View {
    @Bindable var router = router

    NavigationStack(path: $router.path) {
      List(1...3, id: \.self) { productID in
        NavigationLink(
          "Product \(productID)",
          value: AppRoute.product(id: productID)
        )
      }
      .navigationTitle("Products")
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .product(let id):
          Text("Product \(id)")
        case .cart:
          Text("Cart")
        case .shipping:
          Text("Shipping")
        case .payment:
          Text("Payment")
        case .confirmation(let orderID):
          Text("Order \(orderID) confirmed")
        case .receipt(let orderID):
          Text("Receipt \(orderID)")
        }
      }
    }
    .environment(router)
  }
}
```

Explain immediately below it:

- The root owns the router with `@State`.
- Descendants read it with `@Environment(Router<AppRoute>.self)`.
- Views send navigation intent through `push` and the root maps routes to destinations.
- Route payloads carry stable identifiers, not mutable feature models.
- View models may decide the desired navigation outcome, but they must not construct SwiftUI views.

List the operations exactly:

```swift
router.push(.cart)
router.pop()
router.popToRoot()
router.replace(with: [.cart, .shipping])
router.replaceLast(
  2,
  with: [.confirmation(orderID: 42), .receipt(orderID: 42)]
)
```

For `replaceLast`, document this transition:

```text
[product, cart, shipping, payment]
                  ↓ replaceLast(2, with: [confirmation, receipt])
[product, cart, confirmation, receipt]
```

State the edge cases explicitly:

- `count <= 0` leaves the path unchanged.
- `count >= path.count` replaces the whole path.
- An empty replacement removes the requested suffix.

For tabs, use this exact example:

```swift
enum AppTab: String, Codable {
  case catalog
  case orders
}

enum CatalogRoute: Hashable {
  case product(id: Int)
}

enum OrdersRoute: Codable, Hashable {
  case order(id: Int)
  case receipt(id: Int)
}

struct AppTabsView: View {
  @State private var selectedTab = AppTab.catalog
  @State private var catalogRouter = Router<CatalogRoute>()
  @State private var ordersRouter = Router<OrdersRoute>()

  var body: some View {
    @Bindable var catalogRouter = catalogRouter
    @Bindable var ordersRouter = ordersRouter

    TabView(selection: $selectedTab) {
      NavigationStack(path: $catalogRouter.path) {
        Button("Open product 1") {
          catalogRouter.push(.product(id: 1))
        }
        .navigationDestination(for: CatalogRoute.self) { route in
          switch route {
          case .product(let id):
            Text("Product \(id)")
          }
        }
      }
      .tabItem { Label("Catalog", systemImage: "square.grid.2x2") }
      .tag(AppTab.catalog)

      NavigationStack(path: $ordersRouter.path) {
        Button("Open order 42") {
          ordersRouter.push(.order(id: 42))
        }
        .navigationDestination(for: OrdersRoute.self) { route in
          switch route {
          case .order(let id):
            Text("Order \(id)")
          case .receipt(let id):
            Text("Receipt \(id)")
          }
        }
      }
      .tabItem { Label("Orders", systemImage: "shippingbox") }
      .tag(AppTab.orders)
    }
  }
}
```

State that switching tabs preserves each independent stack, a deep link selects the target tab before replacing that tab's path, and a single global path must not multiplex unrelated tabs.

For modal presentation, use this complete `Identifiable` enum and `sheet(item:)` example:

```swift
enum AppSheet: Identifiable {
  case support(orderID: Int)

  var id: Int {
    switch self {
    case .support(let orderID):
      orderID
    }
  }
}

struct OrderActionsView: View {
  @State private var sheet: AppSheet?

  var body: some View {
    Button("Contact support") {
      sheet = .support(orderID: 42)
    }
    .sheet(item: $sheet) { sheet in
      switch sheet {
      case .support(let orderID):
        Text("Support for order \(orderID)")
      }
    }
  }
}
```

Explain that modal state remains separate from the push path because sheets and stack entries have different lifecycles.

For deep links and restoration, document this application order:

1. Parse the URL or decoded snapshot into typed identifiers.
2. Reject unknown routes, malformed identifiers, unsupported snapshot versions, and routes the current user is not authorized to open.
3. Load or verify required business data.
4. Apply one validated path with `router.replace(with:)`.

Use the `AppTab` and `OrdersRoute` definitions from the tabs example in this restoration model:

```swift
struct NavigationSnapshot: Codable {
  let version: Int
  let selectedTab: AppTab
  let ordersPath: [OrdersRoute]
}
```

State that snapshots are versioned, untrusted input and must not contain credentials, mutable domain models, or authorization decisions.

For TCA, include this complete stack and modal-state recipe:

```swift
import ComposableArchitecture
import SwiftUI

@Reducer
struct OrderDetailFeature {
  @ObservableState
  struct State: Equatable {
    let orderID: Int
  }

  enum Action {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

@Reducer
struct ReceiptFeature {
  @ObservableState
  struct State: Equatable {
    let orderID: Int
  }

  enum Action {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

@Reducer
struct SupportFeature {
  @ObservableState
  struct State: Equatable {}

  enum Action {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

@Reducer
struct OrdersFeature {
  @Reducer
  enum Path {
    case detail(OrderDetailFeature)
    case receipt(ReceiptFeature)
  }

  @ObservableState
  struct State: Equatable {
    var path = StackState<Path.State>()
    @Presents var support: SupportFeature.State?
  }

  enum Action {
    case openOrder(id: Int)
    case path(StackActionOf<Path>)
    case support(PresentationAction<SupportFeature.Action>)
    case supportTapped
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .openOrder(let id):
        state.path.append(.detail(OrderDetailFeature.State(orderID: id)))
        return .none

      case .supportTapped:
        state.support = SupportFeature.State()
        return .none

      case .path, .support:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
    .ifLet(\.$support, action: \.support) {
      SupportFeature()
    }
  }
}

struct OrdersView: View {
  @Bindable var store: StoreOf<OrdersFeature>

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      VStack {
        Button("Open order 42") {
          store.send(.openOrder(id: 42))
        }
        Button("Contact support") {
          store.send(.supportTapped)
        }
      }
    } destination: { store in
      switch store.case {
      case .detail(let store):
        Text("Order \(store.orderID)")
      case .receipt(let store):
        Text("Receipt \(store.orderID)")
      }
    }
    .sheet(
      item: $store.scope(state: \.support, action: \.support)
    ) { _ in
      Text("Support")
    }
  }
}
```

State:

- Do not install or inject `Router` into a TCA feature.
- Model push navigation with `StackState<Path.State>` and `StackActionOf<Path>`.
- Compose child reducers with `.forEach(\.path, action: \.path)`.
- Model sheets/covers with `@Presents` and compose them with `.ifLet`.
- Bind the view with scoped stores and TCA's current SwiftUI navigation APIs.
- The recipe targets TCA 1.26.2. Its default manifest declares Swift tools 6.4, and its versioned fallback manifest declares Swift tools 6.1.
- swiftcn does not compile the TCA recipe because the Example app intentionally has no TCA dependency. Host apps must pin their TCA version and compile the recipe with a supported toolchain.

Link to the official Point-Free [1.26.2 stack case study](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Examples/CaseStudies/SwiftUICaseStudies/04-NavigationStack.swift), [stack navigation guide](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Sources/ComposableArchitecture/Documentation.docc/Articles/StackBasedNavigation.md), and [tree navigation guide](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/TreeBasedNavigation.md). Do not copy deprecated `NavigationStackStore`, `ReducerProtocol`, or `@PresentationState` examples.

End with these common mistakes:

- One global router for every tab.
- Storing views, view models, closures, or mutable business objects in route values.
- Letting multiple layers own and mutate the same path.
- Applying deep-link or restored paths before validation.
- Wrapping TCA navigation in an MVVM router.
- Rebuilding a complete path just to replace the last screens instead of using `replaceLast`.

- [ ] **Step 2: Update the repository READMEs**

Update `README.md`:

- Add `npx swiftcn@latest add navigation` beside the existing add examples.
- Add `Router — Typed SwiftUI navigation state` to the component/template overview.
- Add a link to `docs/navigation.md`.
- Describe it as native SwiftUI navigation, not a framework dependency.

Update `Sources/README.md`:

- Add `Navigation/Router.swift` as its own optional template directory.
- State that navigation is a nonvisual feature copied only by `swiftcn add navigation`.
- Keep `Sources/` identified as canonical.

Update `CLI/README.md`:

- Add `npx swiftcn@latest add navigation` to usage examples.
- Add `navigation` to the available registry keys.
- State that it installs into `Navigation/` beside `componentsPath` without changing `swiftcn.json`.
- Describe `add` as installing components or optional features instead of claiming every item goes to the configured components directory.

Update `Example/README.md`:

- State that `App/Navigation/Router.swift` is synced from `Sources/Navigation/Router.swift`.
- Describe `App/Navigation/` as app-owned route enums and tab composition.
- Remove any statement that implies `AppRouter` still exists.

- [ ] **Step 3: Scan documentation and source for stale APIs**

Run:

```bash
rg -n "CNRouter|NavigationStackStore|ReducerProtocol|@PresentationState|All components are SDUI-compatible|AppRouter" README.md Sources/README.md CLI/README.md Example/README.md docs/navigation.md CLI/src/commands/list.ts Example/App
```

Expected: no matches. Any intentional historical reference must be removed or rewritten rather than allowlisted.

- [ ] **Step 4: Run final verification**

Run:

```bash
./scripts/sync-source.sh --dry-run
./scripts/test-all.sh
git diff --check
git status --short
```

Expected:

- The dry run reports no unsynced canonical templates.
- All CLI and Example tests pass.
- `git diff --check` prints nothing.
- `git status --short` shows only the intended navigation work plus the user's pre-existing `.gitignore`, `AGENTS.md`, and `CLAUDE.md` changes.

- [ ] **Step 5: Review the implementation against the spec**

Check every acceptance item:

- `Router` has no `CN` prefix and no dependency.
- All public methods and edge cases match the spec.
- The Example app compiles without `AppRouter` or `AppRoute`.
- `swiftcn add navigation` resolves to `Navigation/Router.swift` and installs it beside `componentsPath`.
- Compact CLI output no longer claims universal SDUI support.
- MVVM, tabs, modals, deep links, restoration, and direct TCA usage are documented.
- The TCA guide identifies version 1.26.2 and its Swift 6.4/6.1 manifests.
- No placeholder, `TODO`, `FIXME`, undefined sample type, or speculative abstraction remains.

- [ ] **Step 6: Commit only Task 3 files**

Run:

```bash
git add -- docs/navigation.md README.md Sources/README.md CLI/README.md Example/README.md
git diff --cached --check
git commit -m "docs(navigation): add architecture guide"
```

---

## Completion Criteria

- All three task commits exist and contain only their scoped files.
- `./scripts/test-all.sh` passes from the repository root.
- `./scripts/sync-source.sh --dry-run` reports no pending copies.
- The implementation is native-first: one small `Router` for MVVM, direct TCA state for TCA, and no added package.
- The final handoff reports commands run and any pre-existing unrelated worktree changes left untouched.
