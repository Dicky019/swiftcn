# Navigation

`Router` is a small, native SwiftUI navigation state type for apps that use MVVM or another architecture without a navigation framework. It stores a typed path; your app still uses `NavigationStack` and `navigationDestination`.

## Install

Copy the optional template into your project:

```bash
npx swiftcn@latest add navigation
```

This installs `Navigation/Router.swift` beside your configured components directory. It adds no package dependency and does not change `swiftcn.json`.

## Native SwiftUI and MVVM

Define routes as small, hashable values and let the root own the navigation state:

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

The root owns the router with `@State`. Descendants read it with `@Environment(Router<AppRoute>.self)`, send navigation intent through `push`, and the root maps routes to destinations. Put stable identifiers in route payloads, not mutable feature models. View models may decide the desired navigation outcome, but they must not construct SwiftUI views.

## Router operations

Use the router only for stack operations:

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

One owner should mutate a path. Descendants can receive the router from the SwiftUI environment rather than taking a separate binding to the same path.

## Replace the last screens

`replaceLast` retains the prefix and substitutes a suffix. For a checkout transition:

```text
[product, cart, shipping, payment]
                  ↓ replaceLast(2, with: [confirmation, receipt])
[product, cart, confirmation, receipt]
```

- `count <= 0` leaves the path unchanged.
- `count >= path.count` replaces the whole path.
- An empty replacement removes the requested suffix.

## Tabs

Give each tab its own path. This keeps back stacks independent and makes a target tab explicit when handling a deep link.

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

Switching tabs preserves each independent stack. A deep link selects the target tab before replacing that tab's path. Do not multiplex unrelated tabs through one global path.

## Sheets and full-screen covers

Keep modal state separate from the push path: sheets and stack entries have different lifecycles. Use the same pattern with `fullScreenCover(item:)` when a full-screen presentation is appropriate.

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

## Deep links and state restoration

Treat URLs and restored snapshots as untrusted input. Apply navigation only after this order:

1. Parse the URL or decoded snapshot into typed identifiers.
2. Reject unknown routes, malformed identifiers, unsupported snapshot versions, and routes the current user is not authorized to open.
3. Load or verify required business data.
4. Apply one validated path with `router.replace(with:)`.

For example, use the `AppTab` and `OrdersRoute` definitions from the tabs example in a versioned restoration model:

```swift
struct NavigationSnapshot: Codable {
  let version: Int
  let selectedTab: AppTab
  let ordersPath: [OrdersRoute]
}
```

Snapshots are versioned, untrusted input. They must not contain credentials, mutable domain models, or authorization decisions. For a tab deep link or restored state, validate first, select the target tab, then replace that tab's router path.

## The Composable Architecture

TCA already owns navigation state and reducer composition. Use its stack and presentation state directly; do not install or inject `Router` into a TCA feature.

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

Model push navigation with `StackState<Path.State>` and `StackActionOf<Path>`, then compose child reducers with `.forEach(\.path, action: \.path)`. Model sheets and covers with `@Presents` and compose them with `.ifLet`. Bind SwiftUI with scoped stores and TCA's current navigation APIs.

This recipe targets TCA 1.26.2. Its default manifest declares Swift tools 6.4, and its versioned fallback manifest declares Swift tools 6.1. swiftcn does not compile this recipe because the Example app intentionally has no TCA dependency. Host apps must pin their TCA version and compile the recipe with a supported toolchain.

For more patterns, see Point-Free's [1.26.2 stack case study](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Examples/CaseStudies/SwiftUICaseStudies/04-NavigationStack.swift), [stack navigation guide](https://github.com/pointfreeco/swift-composable-architecture/blob/1.26.2/Sources/ComposableArchitecture/Documentation.docc/Articles/StackBasedNavigation.md), and [tree navigation guide](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Sources/ComposableArchitecture/Documentation.docc/Articles/TreeBasedNavigation.md).

## Common mistakes

- One global router for every tab.
- Storing views, view models, closures, or mutable business objects in route values.
- Letting multiple layers own and mutate the same path.
- Applying deep-link or restored paths before validation.
- Wrapping TCA navigation in an MVVM router.
- Rebuilding a complete path just to replace the last screens instead of using `replaceLast`.
