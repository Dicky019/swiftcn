# Architecture presets

`swiftcn init` configures an existing SwiftUI application. It copies foundations you select and records the preset; you own every copied file. It does not generate features, edit your app entry point or package/project manifests, or install TCA. Copy and adapt only the recipe code your feature needs.

```sh
npx swiftcn@latest init --preset native --navigation
npx swiftcn@latest init --preset mvvm --navigation --offline-first
npx swiftcn@latest init --preset tca --navigation
```

Fresh `init -y` uses Native with Navigation and Offline-First disabled. Rerunning init preserves existing values unless you supply a flag. `--no-navigation` and `--no-offline-first` explicitly disable configuration without deleting your owned source. Changing preset does not migrate existing features.

All three presets depend inward: Presentation → Application → Domain. Domain contains pure Swift values and invariants. Application owns use cases and the ports they require; Infrastructure implements those ports. Your composition root chooses concrete adapters. Create a layer only when it has real code; this score example needs no Infrastructure layer.

## Native

[NativeScoreView.swift](../Fixtures/ArchitecturePresets/Sources/NativePreset/NativeScoreView.swift) owns `@State private var score = Score()` and directly applies `IncrementScore().execute(score)`. There is no ViewModel. The root owns `@State Router<NativeRoute>`, binds its path to `NavigationStack`, and supplies the router through the SwiftUI environment. The view pushes a route containing the stable score integer. A real entity feature should carry its stable ID and load current data at the destination.

Use Native for simple local UI state. Move to MVVM when asynchronous work needs a separate lifecycle and orchestration owner.

## MVVM

[ScoreViewModel.swift](../Fixtures/ArchitecturePresets/Sources/MVVMPreset/ScoreViewModel.swift) is `@MainActor @Observable`. It owns score state and exposes intent methods. [MVVMScoreView.swift](../Fixtures/ArchitecturePresets/Sources/MVVMPreset/MVVMScoreView.swift) renders that state and forwards button taps.

`detailsTapped()` emits `.showDetails(score: Int)`, an `Equatable, Sendable` outcome with a snapshot value. The view does not mutate navigation. The root observes the outcome, consumes it once, and forwards it to [ScoreFlow.swift](../Fixtures/ArchitecturePresets/Sources/MVVMPreset/ScoreFlow.swift). That flow validates the value and is the sole owner mutating `Router<ScoreRoute>`. Each tab needs its own router. Validate every route before replacing a restored or deep-linked path.

Both Native and MVVM compile against the canonical [Router template](../Sources/Navigation/Router.swift), referenced by a fixture symlink. There is no separate preset router implementation.

## TCA

[ScoreFeature.swift](../Fixtures/ArchitecturePresets/Sources/TCAPreset/ScoreFeature.swift) owns the domain value in reducer state. The view sends actions through a store, and the reducer invokes the same inward-only use case.

[AppFeature.swift](../Fixtures/ArchitecturePresets/Sources/TCAPreset/AppFeature.swift) owns `StackState<Path.State>` and `@Presents var destination: Destination.State?`. `StackActionOf<Path>` and `PresentationAction<Destination.Action>` route child actions. The reducer appends and clears the stack and creates modal state; presentation dismissal clears that state. [TCAAppView.swift](../Fixtures/ArchitecturePresets/Sources/TCAPreset/TCAAppView.swift) binds `NavigationStack(path: $store.scope(\.path, action: \.path))` and a scoped sheet to this state. No TCA fixture imports or instantiates Router.

Install the `ComposableArchitecture` package product in your app yourself. These recipes require **Swift 6.1+**, **iOS 17+**, and exactly **TCA 1.26.1**. The version and toolchain requirements were checked against the [official pinned package manifest](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.1/Package.swift); navigation follows its [pinned case study](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.1/Examples/CaseStudies/SwiftUICaseStudies/04-NavigationStack.swift). Init does not modify your package or project manifest.

## Offline-First is independent

`--offline-first` copies the same pure Swift sync contracts, retry policy, and scoped coordinator for every preset. Your feature supplies the worker and persistent adapters. Local data is the source of truth; a write commits the local projection and durable outbox together. The shipped core does not provide storage, endpoints, background entitlements, or a production adapter. Navigation remains owned by the presentation flow, never by the sync worker.

## Compile and behavior checks

```sh
./scripts/test-architecture-presets.sh
./scripts/test-architecture-presets.sh 'platform=iOS Simulator,name=iPhone 18 Pro'
```

The script generates a repository-only Tuist host, compiles all recipe views with Swift 6 strict concurrency, and runs Apple Swift Testing on the selected **iOS simulator**. It fails when prerequisites or the destination are missing; it never falls back to a macOS package build or skips TCA. The unattended test harness enables macros from the pinned TCA package and its dependencies. You need Xcode with Swift 6.1+, an iOS 17+ simulator, Tuist, ripgrep, and network access for initial package resolution. Pass the same simulator destination to `./scripts/test-all.sh` to run repository verification together.

The package separates Domain, Application, Native, MVVM, and TCA modules. Tests cover the domain invariant, direct use-case result, MVVM state and typed outcome consumption/validation, reducer state, stack child actions/pop, and modal child actions/dismissal. Import gates reject presentation/persistence/network/router dependencies in inner layers and reject Router in TCA. Build products, dependency checkouts, generated projects, and resolution files stay ignored.

## Architecture diagrams

- [Native Clean Architecture](init-preset-native.html)
- [MVVM Clean Architecture](init-preset-mvvm.html)
- [TCA Clean Architecture](init-preset-tca.html)
- [Offline-First capability](init-option-offline-first.html)
