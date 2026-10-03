# SwiftUI Navigation Design

## Overview

Add an installable, native SwiftUI navigation template to swiftcn. The template provides a small typed router for SwiftUI and MVVM projects. TCA projects use TCA navigation state directly and do not synchronize it with the router.

The feature preserves swiftcn's copy-paste model:

- `swiftcn add navigation` copies editable source into the user's project.
- The native template adds no package dependency.
- The TCA documentation is opt-in for projects that already use TCA.
- The existing `swiftcn init` command and app bootstrap remain unchanged.

## Goals

- Provide a SwiftUI-friendly typed navigation state for iOS 17+.
- Support programmatic push, pop, pop-to-root, full-path replacement, and trailing-route replacement.
- Give each scene, flow, or tab independent navigation ownership.
- Document production patterns for MVVM, TCA, deep links, and restoration.
- Demonstrate the template in the Example app.
- Keep business decisions outside navigation infrastructure.

## Non-goals

- Build a universal navigation framework.
- Wrap or replace `NavigationStack` and `NavigationSplitView`.
- Add TCA, Swift Navigation, FlowStacks, Navigator, or another dependency.
- Synchronize native router state with TCA `StackState`.
- Implement authentication, authorization, dependency injection, analytics, modal queues, custom transitions, or URL routing for every application.
- Change `swiftcn init` or generate an application bootstrap.

## Architecture

```text
User action / deep link / restored snapshot
                    |
          Application validation
          (auth + business rules)
                    |
             Navigation intent
              /             \
     SwiftUI / MVVM          TCA
      Router<Route>     Reducer-owned state
        [Route]        StackState + @Presents
              \             /
           Native SwiftUI containers
     NavigationStack / sheet / fullScreenCover
```

The application remains the source of navigation policy. The router only stores and mutates a stack of route values. Feature models and reducers decide whether navigation may occur.

### Native SwiftUI and MVVM

The native template defines one generic observable type:

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

`pop()` is a no-op when the path is empty. `replace(with:)` replaces the entire path for operations such as deep links. `replaceLast(_:with:)` replaces only the requested suffix in one observable mutation. A nonpositive count is a no-op. A count larger than the current path replaces the whole path.

For example:

```swift
// Before: [.home, .cart, .shipping, .payment]
router.replaceLast(
  2,
  with: [
    .confirmation(orderID: orderID),
    .receipt(orderID: orderID),
  ]
)
// After: [.home, .cart, .confirmation(orderID: orderID), .receipt(orderID: orderID)]
```

The caller does not reconstruct the retained prefix. The API contains no destination registry, `AnyView`, service locator, middleware, or coordinator hierarchy.

Each application defines its own route enum and destination builder:

```swift
enum OrderRoute: Hashable, Codable {
  case home
  case cart
  case shipping
  case payment
  case confirmation(orderID: String)
  case receipt(orderID: String)
}
```

Routes carry stable identifiers and small presentation parameters. They do not carry views, services, view models, or full domain object graphs.

The view that owns a `NavigationStack` owns its router with `@State`, or receives one from its scene or flow owner. Descendants may obtain it through SwiftUI's environment and create a binding with `@Bindable`.

### Tabs and scenes

Each tab keeps its own router when its history must survive tab changes. A deep link selects the target tab and replaces that tab's path. The design does not use a process-wide singleton because separate scenes need independent state.

### Modal presentation

Sheets, covers, alerts, and other tree-shaped presentations remain application state. An optional destination enum represents mutually exclusive presentations:

```swift
enum OrderDestination: Identifiable {
  case cancelConfirmation
  case support(orderID: Order.ID)
}
```

The generic router does not own this enum. A modal may own another router when it contains an independent drill-down flow.

### Deep links and restoration

Deep-link parsing and restoration are documented recipes, not generic router behavior:

1. Parse the external URL into a typed intent.
2. Validate its scheme, host, path, identifiers, session, tenant, and business prerequisites.
3. Select the correct scene or tab.
4. Replace the appropriate typed path.
5. Fall back safely when an identifier no longer resolves.

Restoration stores a versioned `Codable` snapshot containing selected tabs, route cases, and stable identifiers. It does not serialize feature models or sensitive data. Migration and invalid-data handling belong to the application because they depend on its domain.

### TCA

TCA projects use the same product concepts but a different state owner:

- `@Reducer enum Path` defines stack destinations.
- `StackState<Path.State>` stores active feature state.
- `StackActionOf<Path>` and `.forEach(\.path, action: \.path)` integrate child reducers.
- `@Presents` and `PresentationAction` model sheets, covers, alerts, and other tree-shaped destinations.
- Parent reducers handle child delegate actions and apply business rules before mutating navigation state.

The documentation must use the modern `NavigationStack(path:root:destination:)` integration. It must not use obsolete `NavigationStackStore`, `ReducerProtocol`, or `@PresentationState` examples. `Router<Route>` is not instantiated in the TCA recipe.

## Repository integration

### Canonical template

Add `Sources/Navigation/Router.swift`. Navigation is an optional nonvisual feature, so it has its own top-level template directory instead of living under `Components/`.

Add a `navigation` entry to `CLI/registry.json` whose only source file is `Navigation/Router.swift`. The existing add command then supports:

```bash
swiftcn add navigation
```

The CLI installs it into a `Navigation` directory beside the configured components directory. For example, `App/Components` produces `App/Navigation/Router.swift`. This is derived only when `swiftcn add navigation` runs, so `swiftcn init` needs no new prompt or configuration field.

The source-sync script copies only `Sources/Navigation/Router.swift` into `Example/App/Navigation/Router.swift` without `--delete` because that Example directory also contains app-owned route and tab files.

The non-verbose `swiftcn list` hint must no longer claim that every registry item supports SDUI, because navigation has no SDUI representation.

### Example app

Use `Router<ComponentRoute>` as the source of truth for the Components flow:

- `MainTabView` owns the router.
- `ComponentsCoordinatorView` binds `NavigationStack` to `router.path`.
- `ComponentGalleryView` calls `router.push(...)`.
- `Router.swift` lives in `Example/App/Navigation/`, not `Example/App/Components/`.
- Remove the replaced `AppRouter.swift`.
- Remove the unused `AppRoute.swift`.

Other demo flows remain unchanged. This avoids an unrelated repository-wide navigation refactor.

### Documentation

Add a focused navigation guide covering:

- Installation and native quick start.
- MVVM ownership and feature-to-parent outcomes.
- Per-tab paths.
- Modal enum state.
- Deep-link validation and versioned restoration.
- A modern TCA recipe and toolchain compatibility note.
- Common mistakes and the boundary between navigation and business logic.

Update the root and Sources READMEs to list the navigation template and link to the guide.

## Data flow

### MVVM business flow

1. A view sends a user intent to its feature model.
2. The feature model runs validation or an asynchronous use case.
3. The feature reports a typed success or delegate outcome.
4. The flow owner pushes or replaces a route.
5. `NavigationStack` renders the destination for that route.

The router never performs the use case itself.

### TCA business flow

1. A view sends a feature action to its store.
2. The reducer runs validation or an effect.
3. The reducer receives the effect result.
4. The owning reducer mutates `StackState` or presentation state.
5. Scoped SwiftUI navigation renders the corresponding child store.

## Error handling

- Popping an empty native path is safe and does nothing.
- Replacing a nonpositive trailing count is safe and does nothing.
- Replacing more trailing routes than exist replaces the entire path.
- Invalid deep links do not partially mutate navigation state.
- Restoration decoding failures fall back to a known root state.
- Missing or unauthorized identifiers are rejected before path replacement.
- TCA effect failures remain feature actions and do not implicitly navigate.

The empty-pop and trailing-replacement behavior belong to `Router`. The remaining policies are documented for application implementations.

## Testing

### Router tests

Add focused Swift Testing coverage for:

- Push appends a route.
- Pop removes the last route.
- Pop on an empty path is a no-op.
- Pop-to-root clears the path.
- Replace atomically installs a multi-step path.
- Replace-last preserves the prefix and replaces the requested suffix.
- Replace-last with an oversized count replaces the entire path.
- Replace-last with a nonpositive count is a no-op.

### Example and CLI verification

- Compile and run the existing Example tests after switching to the typed path.
- Verify the real registry accepts the navigation entry.
- Run CLI tests to ensure existing component and SDUI behavior remains unchanged.
- Run `./scripts/test-all.sh` before completion.

The TCA recipe is not compiled in this repository because the Example target intentionally has no package dependency. The guide must identify the tested TCA API version and compiler requirement rather than promise compatibility with every Swift 6 toolchain.

## Alternatives considered

### One router for MVVM and TCA

Rejected because it duplicates TCA navigation state and requires synchronization in both directions.

### `NavigationPath` as the default

Rejected because a route enum already provides one homogeneous type. A typed array is easier to inspect, compare, encode, and test. `NavigationPath` remains appropriate when an application genuinely needs an open heterogeneous path.

### Third-party navigation dependency

Rejected as the default because it conflicts with swiftcn's dependency-free copy-paste philosophy. Navigator, FlowStacks, Swift Navigation, and TCACoordinators remain valid application-level choices when their additional behavior is explicitly needed.

### Full coordinator framework

Rejected because destination factories, protocol hierarchies, middleware, and global route registries are not required for the accepted use cases.

## Acceptance criteria

- `swiftcn add navigation` copies `Sources/Navigation/Router.swift` into a `Navigation` directory beside the configured components directory.
- `Router` uses typed `[Route]` state and compiles under the project's iOS 17+/Swift 6 settings.
- Empty pop is safe.
- `replaceLast(_:with:)` replaces a path suffix without requiring the caller to rebuild its prefix.
- The Example Components flow uses `Router<ComponentRoute>` and preserves back navigation.
- No runtime dependency is added.
- No TCA state is mirrored into `Router`.
- Documentation provides distinct, current MVVM and TCA paths.
- Focused tests and the full repository test script pass.

## Sources

- Apple, [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack).
- Apple, [The SwiftUI cookbook for navigation](https://developer.apple.com/videos/play/wwdc2022/10054/), WWDC22.
- Apple, [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/), WWDC23.
- Apple, [NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath).
- Apple, [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview).
- Point-Free, [TCA NavigationStack case study, 1.26.2](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Examples/CaseStudies/SwiftUICaseStudies/04-NavigationStack.swift).
- Point-Free, [TCA stack-based navigation, 1.26.2](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Sources/ComposableArchitecture/Documentation.docc/Articles/StackBasedNavigation.md).
- Point-Free, [TCA tree-based navigation](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/TreeBasedNavigation.md).
- Majid Jabrayilov, [Mastering NavigationStack in SwiftUI: Navigator Pattern](https://swiftwithmajid.com/2022/06/15/mastering-navigationstack-in-swiftui-navigator-pattern/), 15 June 2022.
- Majid Jabrayilov, [Mastering NavigationStack in SwiftUI: Deep Linking](https://swiftwithmajid.com/2022/06/21/mastering-navigationstack-in-swiftui-deep-linking/), 21 June 2022.
- Donny Wals, [Programmatic navigation in SwiftUI](https://www.donnywals.com/programmatic-navigation-in-swiftui-with-navigationpath-and-navigationdestination/), 22 May 2024.
- AzamSharp, [Navigation Patterns in SwiftUI](https://azamsharp.com/2024/07/29/navigation-patterns-in-swiftui.html), 29 July 2024.
- GitHub, [Navigator](https://github.com/hmlongco/Navigator), [FlowStacks](https://github.com/johnpatrickmorgan/FlowStacks), and [TCACoordinators](https://github.com/johnpatrickmorgan/TCACoordinators), reviewed 13 September 2026.
