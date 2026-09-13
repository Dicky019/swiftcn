# Modular SDUI Contracts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make SDUI core compile without CN components and give every installed component one colocated, validated wire contract.

**Architecture:** Keep a shared main-actor registry, but register only native layout primitives in its initializer. Component `+SDUI` files own their state wrapper, typed prop parsing, and explicit renderer registration; `AnyCodable` provides safe typed scalar access.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, iOS 17+, Xcode 16+, existing TypeScript CLI metadata.

**Spec:** `docs/superpowers/specs/2026-09-11-foundation-hardening-design.md`

## Global Constraints

- Swift 6 with complete strict concurrency.
- iOS 17.0+, macOS 14.0+, Xcode 16+.
- No third-party Swift dependency.
- `swiftcn init --sdui` must compile without any CN component.
- Component wire parsing and state wrappers live in the component's existing `+SDUI` file.
- Canonical edits happen in `Sources/`; synchronize before Xcode verification.
- Missing optional server values may use documented defaults. Present values with
  the wrong scalar type or an unknown enum case throw `invalidProps`; they never
  silently fall back.
- Invalid server values render an error view; they do not silently default when data loss or a runtime trap would result.
- Slider wire defaults are `value = 0`, `min = 0`, and `max = 100`, matching
  `CNSlider`; bounds, values, and steps must be finite, `min < max`, the value
  must be in range, and a provided step must be greater than zero.

## File Map

- `Sources/SDUI/Core/AnyCodable.swift`: typed scalar accessors.
- `Sources/SDUI/Core/SDUIError.swift`: invalid-props error.
- `Sources/SDUI/Rendering/SDUIRegistry.swift`: native-only registry and throwing renderer boundary.
- `Sources/SDUI/Actions/SDUIActionHandler.swift`: main-actor Sendable payload contract.
- `Sources/Components/*+SDUI.swift`: configuration, state wrapper, and registration.
- `Sources/SDUI/Wrappers/*.swift`: delete after moving the three wrappers.
- `Example/App/App.swift`: register the six demo components.
- `Example/Project.swift`: compile `App/SDUI` in a component-free target.
- `Example/Tests/SDUITests.swift`: wire-contract tests.
- `CLI/registry.json`: remove core wrapper files and align slider metadata.
- `CLI/src/commands/add.ts`: print the explicit registration call.
- `CLI/src/__tests__/commands/add.test.ts`: registration-hint regression.
- `CLAUDE.md`, `Sources/README.md`, `CLI/README.md`: describe the modular layout.

---

### Task 1: Add typed AnyCodable scalar access

**Files:**
- Modify: `Sources/SDUI/Core/AnyCodable.swift:21-31`
- Create: `Example/Tests/SDUITests.swift`

**Interfaces:**
- Produces: `AnyCodable.stringValue: String?`.
- Produces: `AnyCodable.boolValue: Bool?`.
- Produces: `AnyCodable.doubleValue: Double?`, converting `.int` with `Double(value)`.

- [ ] **Step 1: Add failing accessor tests**

Create `Example/Tests/SDUITests.swift`:

```swift
//
//  SDUITests.swift
//  Tests
//
//  Created by Dicky Darmawan on 11/09/26.
//

import Testing
@testable import Example

@Suite("SDUI Tests")
struct SDUITests {
  @Test("Integer props convert to Double")
  func integerPropConvertsToDouble() {
    #expect(AnyCodable.int(16).doubleValue == 16)
  }

  @Test("Typed accessors reject another scalar type")
  func typedAccessorsRejectAnotherType() {
    #expect(AnyCodable.bool(true).stringValue == nil)
    #expect(AnyCodable.string("16").doubleValue == nil)
  }
}
```

- [ ] **Step 2: Run the test and verify compilation fails**

Run:

```bash
./scripts/test-example.sh
```

Expected: compilation fails because `doubleValue` and `stringValue` do not exist.

- [ ] **Step 3: Add the typed accessors**

Add to `AnyCodable`:

```swift
public var stringValue: String? {
  guard case .string(let value) = self else { return nil }
  return value
}

public var boolValue: Bool? {
  guard case .bool(let value) = self else { return nil }
  return value
}

public var doubleValue: Double? {
  switch self {
  case .double(let value): value
  case .int(let value): Double(value)
  default: nil
  }
}
```

Keep `value` for source compatibility, but stop using it inside swiftcn templates.

- [ ] **Step 4: Sync and run the focused Swift suite**

Run:

```bash
./scripts/sync-source.sh
if rg -n '\bCN(Button|Card|Badge|Input|Switch|Slider)\b' Sources/SDUI; then exit 1; fi
./scripts/test-example.sh
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/SDUI/Core/AnyCodable.swift Example/App/SDUI/Core/AnyCodable.swift Example/Tests/SDUITests.swift
git commit -m "fix(sdui): add typed scalar access"
```

---

### Task 2: Make the registry and component contracts modular

**Files:**
- Modify: `Sources/SDUI/Core/SDUIError.swift`
- Modify: `Sources/SDUI/Rendering/SDUIRegistry.swift`
- Modify: `Sources/SDUI/Rendering/SDUIRenderer.swift`
- Modify: `Sources/SDUI/Actions/SDUIActionHandler.swift`
- Modify: `Sources/Components/CNButton+SDUI.swift`
- Modify: `Sources/Components/CNCard+SDUI.swift`
- Modify: `Sources/Components/CNBadge+SDUI.swift`
- Modify: `Sources/Components/CNInput+SDUI.swift`
- Modify: `Sources/Components/CNSwitch+SDUI.swift`
- Modify: `Sources/Components/CNSlider+SDUI.swift`
- Delete: `Sources/SDUI/Wrappers/SDUIInputWrapper.swift`
- Delete: `Sources/SDUI/Wrappers/SDUISwitchWrapper.swift`
- Delete: `Sources/SDUI/Wrappers/SDUISliderWrapper.swift`
- Modify: `Example/App/App.swift`
- Modify: `Example/Tests/SDUITests.swift`

**Interfaces:**
- Produces: throwing `SDUIRegistry.register(_:renderer:)` closures.
- Produces: `registerCNButton()`, `registerCNCard()`, `registerCNBadge()`, `registerCNInput()`, `registerCNSwitch()`, and `registerCNSlider()`.
- Produces: component-local `Configuration.init(node:)`, throwing where required values or ranges are validated.
- Produces: `@MainActor SDUIActionHandler` with `[String: AnyCodable]?` payloads.
- Consumes: typed accessors from Task 1.

- [ ] **Step 1: Add failing contract tests**

Append to `SDUITests.swift`:

```swift
@Test("Core registry contains native layout")
@MainActor
func coreRegistryContainsNativeLayout() {
  #expect(SDUIRegistry.shared.isRegistered("vstack"))
}

@Test("Button registration is explicit")
@MainActor
func buttonRegistrationIsExplicit() {
  SDUIRegistry.shared.registerCNButton()
  #expect(SDUIRegistry.shared.isRegistered("button"))
}

@Test("Switch configuration reads its initial value")
func switchConfigurationReadsInitialValue() throws {
  let node = SDUINode(
    id: "switch",
    type: "switch",
    props: ["label": AnyCodable("Wi-Fi"), "isOn": AnyCodable(true)]
  )

  let configuration = try CNSwitch.Configuration(node: node)
  #expect(configuration.label == "Wi-Fi")
  #expect(configuration.isOn)
}

@Test("Slider accepts integer wire values")
func sliderAcceptsIntegerWireValues() throws {
  let node = SDUINode(
    id: "slider",
    type: "slider",
    props: [
      "value": AnyCodable(25),
      "min": AnyCodable(0),
      "max": AnyCodable(100),
      "showValue": AnyCodable(true)
    ]
  )

  let configuration = try CNSlider.Configuration(node: node)
  #expect(configuration.value == 25)
  #expect(configuration.minValue == 0)
  #expect(configuration.maxValue == 100)
  #expect(configuration.showValue)
}

@Test("Slider rejects an inverted range")
func sliderRejectsInvertedRange() {
  let node = SDUINode(
    id: "slider",
    type: "slider",
    props: ["min": AnyCodable(10), "max": AnyCodable(1)]
  )

  #expect(throws: SDUIError.self) {
    try CNSlider.Configuration(node: node)
  }
}

@Test("Present props with the wrong type are rejected")
func presentPropsWithWrongTypeAreRejected() {
  let node = SDUINode(
    id: "switch",
    type: "switch",
    props: ["label": AnyCodable("Wi-Fi"), "isOn": AnyCodable("true")]
  )

  #expect(throws: SDUIError.self) {
    try CNSwitch.Configuration(node: node)
  }
}

@Test("Unknown enum props are rejected")
func unknownEnumPropsAreRejected() {
  let node = SDUINode(
    id: "button",
    type: "button",
    props: ["label": AnyCodable("Save"), "variant": AnyCodable("unknown")]
  )

  #expect(throws: SDUIError.self) {
    try CNButton.Configuration(node: node)
  }
}

@Test("Slider rejects values outside its range")
func sliderRejectsValuesOutsideItsRange() {
  let node = SDUINode(
    id: "slider",
    type: "slider",
    props: ["value": AnyCodable(101), "min": AnyCodable(0), "max": AnyCodable(100)]
  )

  #expect(throws: SDUIError.self) {
    try CNSlider.Configuration(node: node)
  }
}

@Test("Slider rejects a non-positive step")
func sliderRejectsNonPositiveStep() {
  let node = SDUINode(
    id: "slider",
    type: "slider",
    props: ["step": AnyCodable(0)]
  )

  #expect(throws: SDUIError.self) {
    try CNSlider.Configuration(node: node)
  }
}

@Test("Legacy switch configuration JSON keeps its default state")
func legacySwitchConfigurationKeepsDefaultState() throws {
  let data = Data(#"{"label":"Wi-Fi"}"#.utf8)
  let configuration = try JSONDecoder().decode(CNSwitch.Configuration.self, from: data)
  #expect(!configuration.isOn)
}

@Test("Legacy slider configuration JSON keeps its defaults")
func legacySliderConfigurationKeepsDefaults() throws {
  let data = Data(#"{}"#.utf8)
  let configuration = try JSONDecoder().decode(CNSlider.Configuration.self, from: data)
  #expect(configuration.value == 0)
  #expect(configuration.minValue == 0)
  #expect(configuration.maxValue == 100)
}
```

- [ ] **Step 2: Run the suite and verify compilation fails**

Run:

```bash
./scripts/test-example.sh
```

Expected: explicit registration methods, node initializers, and new configuration fields are absent.

- [ ] **Step 3: Add the invalid-props rendering boundary**

Add to `SDUIError`:

```swift
case invalidProps(component: String, reason: String)

case .invalidProps(let component, let reason):
  return "Invalid \(component) props: \(reason)"
```

Change registry storage and registration:

```swift
private var renderers: [String: @MainActor (SDUINode, SDUIActionHandler?) throws -> AnyView] = [:]

public func register<V: View>(
  _ type: String,
  renderer: @MainActor @escaping (SDUINode, SDUIActionHandler?) throws -> V
) {
  renderers[type] = { node, handler in
    AnyView(try renderer(node, handler))
  }
}
```

Replace `render`:

```swift
public func render(_ node: SDUINode, actionHandler: SDUIActionHandler?) -> AnyView {
  guard let renderer = renderers[node.type] else {
    return AnyView(SDUIUnknownComponent(type: node.type))
  }

  do {
    return try renderer(node, actionHandler)
  } catch {
    return AnyView(
      SDUIInvalidComponent(type: node.type, message: error.localizedDescription)
    )
  }
}
```

Add beside `SDUIUnknownComponent`:

```swift
struct SDUIInvalidComponent: View {
  let type: String
  let message: String

  var body: some View {
    Text("Invalid \(type): \(message)")
      .font(.caption)
      .foregroundStyle(.red)
      .padding(4)
      .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 4))
  }
}
```

- [ ] **Step 4: Leave only native primitives in the core registry**

Rename `registerDefaultComponents()` to `registerCoreComponents()` and keep:

```swift
private func registerCoreComponents() {
  register("vstack") { node, handler in
    VStack(spacing: try Self.optionalDouble(node, key: "spacing") ?? 8) {
      if let children = node.children {
        SDUIRenderer(nodes: children, actionHandler: handler)
      }
    }
  }

  register("hstack") { node, handler in
    HStack(spacing: try Self.optionalDouble(node, key: "spacing") ?? 8) {
      if let children = node.children {
        SDUIRenderer(nodes: children, actionHandler: handler)
      }
    }
  }

  register("text") { node, _ in
    Text(try Self.requiredString(node, key: "content"))
      .font(try Self.font(forWireValue: Self.optionalString(node, key: "style") ?? "body"))
  }

  register("spacer") { _, _ in Spacer() }
  register("divider") { _, _ in Divider() }
}
```

Implement the three small core parsing helpers beside `font`: an absent
optional value uses its default, while a present value of the wrong type
throws `SDUIError.invalidProps`. `font(forWireValue:)` also throws for an
unknown style rather than mapping it to `.body`.

Remove every CN component reference from `SDUIRegistry.swift`.

Replace the `SDUIRenderer` preview tree with native core nodes so the
standalone SDUI preview stays useful:

```swift
let nodes: [SDUINode] = [
  SDUINode(
    id: "1",
    type: "vstack",
    props: ["spacing": AnyCodable(16)],
    children: [
      SDUINode(
        id: "2",
        type: "text",
        props: [
          "content": AnyCodable("Hello SDUI!"),
          "style": AnyCodable("title")
        ]
      ),
      SDUINode(
        id: "3",
        type: "text",
        props: ["content": AnyCodable("Core renders without CN components.")]
      )
    ]
  )
]
```

- [ ] **Step 5: Make action handling main-actor and Sendable**

Replace the protocol signatures:

```swift
@MainActor
public protocol SDUIActionHandler: AnyObject {
  func handleAction(id: String, payload: [String: AnyCodable]?)
  func handleNavigation(route: String, params: [String: AnyCodable]?)
}
```

Use this complete default implementation:

```swift
@MainActor
public final class DefaultSDUIActionHandler: SDUIActionHandler {
  public init() {}

  public func handleAction(
    id: String,
    payload: [String: AnyCodable]?
  ) {
    print("[SDUI] Action: \(id), payload: \(payload ?? [:])")
  }

  public func handleNavigation(
    route: String,
    params: [String: AnyCodable]?
  ) {
    print("[SDUI] Navigate: \(route), params: \(params ?? [:])")
  }
}
```

- [ ] **Step 6: Colocate Button, Card, and Badge parsing**

Add to `CNButton+SDUI.swift`:

```swift
extension CNButton.Configuration {
  init(node: SDUINode) throws {
    guard let label = node.props["label"]?.stringValue else {
      throw SDUIError.invalidProps(component: "button", reason: "label is required")
    }
    let size = try node.props["size"].map { prop in
      guard let raw = prop.stringValue, let value = CNButton.Size(rawValue: raw) else {
        throw SDUIError.invalidProps(component: "button", reason: "size is invalid")
      }
      return value
    } ?? .md
    let variant = try node.props["variant"].map { prop in
      guard let raw = prop.stringValue, let value = CNButton.Variant(rawValue: raw) else {
        throw SDUIError.invalidProps(component: "button", reason: "variant is invalid")
      }
      return value
    } ?? .default
    guard node.props["actionId"] == nil || node.props["actionId"]?.stringValue != nil else {
      throw SDUIError.invalidProps(component: "button", reason: "actionId must be a string")
    }
    self.init(label: label, size: size, variant: variant, actionId: node.props["actionId"]?.stringValue)
  }
}

extension SDUIRegistry {
  public func registerCNButton() {
    register("button") { node, handler in
      let configuration = try CNButton.Configuration(node: node)
      return CNButton(configuration: configuration) {
        if let actionId = configuration.actionId {
          handler?.handleAction(id: actionId, payload: nil)
        }
      }
    }
  }
}
```

Inside `CNCard.Configuration`, add:

```swift
init(node: SDUINode) {
  self.init(
    variant: node.props["variant"]?.stringValue.flatMap(Variant.init(rawValue:)) ?? .elevated
  )
}
```

Then add:

```swift
extension CNCard {
  public init(configuration: Configuration, @ViewBuilder content: () -> Content) {
    self.init(variant: configuration.variant, content: content)
  }
}

extension SDUIRegistry {
  public func registerCNCard() {
    register("card") { node, handler -> CNCard<SDUIRenderer> in
      let configuration = CNCard<SDUIRenderer>.Configuration(node: node)
      return CNCard(configuration: configuration) {
        SDUIRenderer(nodes: node.children ?? [], actionHandler: handler)
      }
    }
  }
}
```

Add to `CNBadge+SDUI.swift`:

```swift
extension CNBadge.Configuration {
  init(node: SDUINode) throws {
    guard let label = node.props["label"]?.stringValue else {
      throw SDUIError.invalidProps(component: "badge", reason: "label is required")
    }
    self.init(
      label: label,
      variant: node.props["variant"]?.stringValue.flatMap(CNBadge.Variant.init(rawValue:)) ?? .default
    )
  }
}

extension SDUIRegistry {
  public func registerCNBadge() {
    register("badge") { node, _ in
      CNBadge(configuration: try CNBadge.Configuration(node: node))
    }
  }
}
```

- [ ] **Step 7: Move Input and Switch wrappers into their component files**

Move this final wrapper into `CNInput+SDUI.swift`:

```swift
private struct SDUIInputWrapper: View {
  let placeholder: String
  let label: String?
  let isError: Bool
  let errorMessage: String?
  let inputId: String?
  var actionHandler: SDUIActionHandler?

  @State private var text = ""

  var body: some View {
    CNInput(
      placeholder,
      text: $text,
      label: label,
      isError: isError,
      errorMessage: errorMessage
    )
    .onChange(of: text) { _, newValue in
      if let inputId {
        actionHandler?.handleAction(
          id: inputId,
          payload: ["value": AnyCodable(newValue)]
        )
      }
    }
  }
}
```

Add:

```swift
extension CNInput.Configuration {
  init(node: SDUINode) throws {
    guard let placeholder = node.props["placeholder"]?.stringValue else {
      throw SDUIError.invalidProps(component: "input", reason: "placeholder is required")
    }
    self.init(
      placeholder: placeholder,
      label: node.props["label"]?.stringValue,
      isError: node.props["isError"]?.boolValue ?? false,
      errorMessage: node.props["errorMessage"]?.stringValue,
      inputId: node.props["inputId"]?.stringValue
    )
  }
}

extension SDUIRegistry {
  public func registerCNInput() {
    register("input") { node, handler in
      let configuration = try CNInput.Configuration(node: node)
      return SDUIInputWrapper(
        placeholder: configuration.placeholder,
        label: configuration.label,
        isError: configuration.isError,
        errorMessage: configuration.errorMessage,
        inputId: configuration.inputId,
        actionHandler: handler
      )
    }
  }
}
```

Add `isOn` and replace the initializer in `CNSwitch.Configuration`:

```swift
public let isOn: Bool

public init(label: String, isOn: Bool = false, switchId: String? = nil) {
  self.label = label
  self.isOn = isOn
  self.switchId = switchId
}
```

Because `Configuration` remains `Codable`, add a custom `init(from:)` that
uses `decodeIfPresent(Bool.self, forKey: .isOn) ?? false`. This preserves
decoding of configurations written before `isOn` existed.

Move this final wrapper into `CNSwitch+SDUI.swift`:

```swift
private struct SDUISwitchWrapper: View {
  let label: String
  let initialValue: Bool
  let switchId: String?
  var actionHandler: SDUIActionHandler?

  @State private var isOn: Bool

  init(
    label: String,
    initialValue: Bool,
    switchId: String?,
    actionHandler: SDUIActionHandler?
  ) {
    self.label = label
    self.initialValue = initialValue
    self.switchId = switchId
    self.actionHandler = actionHandler
    self._isOn = State(initialValue: initialValue)
  }

  var body: some View {
    CNSwitch(label, isOn: $isOn)
      .onChange(of: isOn) { _, newValue in
        if let switchId {
          actionHandler?.handleAction(
            id: switchId,
            payload: ["value": AnyCodable(newValue)]
          )
        }
      }
  }
}
```

Then add:

```swift
extension CNSwitch.Configuration {
  init(node: SDUINode) throws {
    guard let label = node.props["label"]?.stringValue else {
      throw SDUIError.invalidProps(component: "switch", reason: "label is required")
    }
    self.init(
      label: label,
      isOn: node.props["isOn"]?.boolValue ?? false,
      switchId: node.props["switchId"]?.stringValue
    )
  }
}

extension SDUIRegistry {
  public func registerCNSwitch() {
    register("switch") { node, handler in
      let configuration = try CNSwitch.Configuration(node: node)
      return SDUISwitchWrapper(
        label: configuration.label,
        initialValue: configuration.isOn,
        switchId: configuration.switchId,
        actionHandler: handler
      )
    }
  }
}
```

- [ ] **Step 8: Move and complete the Slider wrapper**

Add the stored property and replace the initializer in `CNSlider.Configuration`:

```swift
public let value: Double

public init(
  label: String? = nil,
  value: Double = 0.5,
  minValue: Double = 0,
  maxValue: Double = 1,
  step: Double? = nil,
  showValue: Bool = false,
  sliderId: String? = nil
) {
  self.label = label
  self.value = value
  self.minValue = minValue
  self.maxValue = maxValue
  self.step = step
  self.showValue = showValue
  self.sliderId = sliderId
}
```

Add:

```swift
extension CNSlider.Configuration {
  init(node: SDUINode) throws {
    let minValue = node.props["min"]?.doubleValue ?? 0
    let maxValue = node.props["max"]?.doubleValue ?? 100
    let value = node.props["value"]?.doubleValue ?? 0
    let step = node.props["step"]?.doubleValue

    // Before these checks, reject every present numeric prop whose
    // `doubleValue` is nil so wrong scalar types cannot become defaults.
    guard minValue.isFinite, maxValue.isFinite, value.isFinite,
          minValue < maxValue else {
      throw SDUIError.invalidProps(component: "slider", reason: "range is invalid")
    }
    guard (minValue...maxValue).contains(value) else {
      throw SDUIError.invalidProps(component: "slider", reason: "value is outside the range")
    }
    guard step == nil || (step!.isFinite && step! > 0) else {
      throw SDUIError.invalidProps(component: "slider", reason: "step must be greater than zero")
    }
    self.init(
      label: node.props["label"]?.stringValue,
      value: value,
      minValue: minValue,
      maxValue: maxValue,
      step: step,
      showValue: node.props["showValue"]?.boolValue ?? false,
      sliderId: node.props["sliderId"]?.stringValue
    )
  }
}
```

Apply the same absent-versus-invalid rule to `label`, `showValue`, and
`sliderId`. Add a custom `init(from:)` so configurations encoded before the
new `value` property decode it as `0` and keep the existing `0...100` range.

Move this final wrapper into `CNSlider+SDUI.swift`:

```swift
private struct SDUISliderWrapper: View {
  let label: String
  let initialValue: Double
  let range: ClosedRange<Double>
  let step: Double?
  let showValue: Bool
  let sliderId: String?
  var actionHandler: SDUIActionHandler?

  @State private var value: Double

  init(
    label: String,
    initialValue: Double,
    range: ClosedRange<Double>,
    step: Double?,
    showValue: Bool,
    sliderId: String?,
    actionHandler: SDUIActionHandler?
  ) {
    self.label = label
    self.initialValue = initialValue
    self.range = range
    self.step = step
    self.showValue = showValue
    self.sliderId = sliderId
    self.actionHandler = actionHandler
    self._value = State(initialValue: initialValue)
  }

  var body: some View {
    Group {
      if let step {
        CNSlider(
          label,
          value: $value,
          in: range,
          step: step,
          showValue: showValue
        )
      } else {
        CNSlider(
          label,
          value: $value,
          in: range,
          showValue: showValue
        )
      }
    }
    .onChange(of: value) { _, newValue in
      if let sliderId {
        actionHandler?.handleAction(
          id: sliderId,
          payload: ["value": AnyCodable(newValue)]
        )
      }
    }
  }
}
```

Add:

```swift
extension SDUIRegistry {
  public func registerCNSlider() {
    register("slider") { node, handler in
      let configuration = try CNSlider.Configuration(node: node)
      return SDUISliderWrapper(
        label: configuration.label ?? "",
        initialValue: configuration.value,
        range: configuration.minValue...configuration.maxValue,
        step: configuration.step,
        showValue: configuration.showValue,
        sliderId: configuration.sliderId,
        actionHandler: handler
      )
    }
  }
}
```

- [ ] **Step 9: Delete the old wrapper files and register the demo components**

Delete the three files under `Sources/SDUI/Wrappers/`.

Add to `ExampleApp`:

```swift
@MainActor
init() {
  let registry = SDUIRegistry.shared
  registry.registerCNButton()
  registry.registerCNCard()
  registry.registerCNBadge()
  registry.registerCNInput()
  registry.registerCNSwitch()
  registry.registerCNSlider()
}
```

Add an `SDUICoreCompile` framework target to `Example/Project.swift` whose
only buildable folder is `App/SDUI/`, and include it in the Example scheme's
build action. This is the executable proof that core SDUI has no component
dependency; the grep below remains a fast structural check.

- [ ] **Step 10: Sync and run Swift verification**

Run:

```bash
./scripts/sync-source.sh
./scripts/test-example.sh
```

Expected: PASS. `Sources/SDUI` contains no CN symbol reference and no `Wrappers` Swift file.

- [ ] **Step 11: Commit**

```bash
git add Sources/Components Sources/SDUI Example/App Example/Tests/SDUITests.swift
git commit -m "refactor(sdui): colocate component contracts"
```

---

### Task 3: Align CLI metadata and registration guidance

**Files:**
- Modify: `CLI/registry.json`
- Modify: `CLI/src/commands/add.ts:118-145`
- Test: `CLI/src/__tests__/commands/add.test.ts`
- Modify: `CLI/README.md`
- Modify: `Sources/README.md`
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: one-time hint `SDUIRegistry.shared.register<ComponentName>()`.
- Produces: an empty `sdui.wrappers` registry list and slider metadata containing `showValue`.

- [ ] **Step 1: Add a failing registration-hint test**

Add to `add.test.ts`:

```ts
it("prints the component registration call when SDUI is installed", async () => {
  const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});

  await runAdd(["button"], {
    config: {
      load: vi.fn().mockResolvedValue(sampleConfigWithSdui),
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
    fetcher: {
      fetchComponents: vi.fn().mockResolvedValue(addedWithSduiResult),
      fetchTheme: vi.fn(),
      fetchSdui: vi.fn(),
    },
  });

  expect(logSpy.mock.calls.flat().join("\n")).toContain(
    "SDUIRegistry.shared.registerCNButton()"
  );
});

it("does not print registration when SDUI installation is disabled", async () => {
  const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});

  await runAdd(["button", "--no-sdui"], {
    config: {
      load: vi.fn().mockResolvedValue(sampleConfigWithSdui),
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
    fetcher: {
      fetchComponents: vi.fn().mockResolvedValue(addedWithSduiResult),
      fetchTheme: vi.fn(),
      fetchSdui: vi.fn(),
    },
  });

  expect(logSpy.mock.calls.flat().join("\n")).not.toContain(
    "SDUIRegistry.shared.registerCNButton()"
  );
});
```

- [ ] **Step 2: Run the CLI test and verify failure**

Run:

```bash
cd CLI && npm test -- src/__tests__/commands/add.test.ts
```

Expected: the registration call is absent.

- [ ] **Step 3: Align registry metadata**

Set:

```json
"wrappers": []
```

Add `showValue` to the slider props:

```json
"sduiProps": [
  "label",
  "value",
  "min",
  "max",
  "step",
  "showValue",
  "sliderId"
]
```

- [ ] **Step 4: Print and document explicit registration**

Compute the installation decision once so fetching and messaging cannot
drift:

```ts
const installsSdui = Boolean(
  config.sduiPath && component.sdui_files?.length && options.sdui !== false
);
```

Use `installsSdui` both when appending `sdui_files` and in the add command
success output:

```ts
if (installsSdui) {
  ui.hint(`Register once: SDUIRegistry.shared.register${component.name}()`);
}
```

Update the three architecture documents to remove the deleted wrapper
directory and add this exact guidance:

```swift
let registry = SDUIRegistry.shared
registry.registerCNButton()
registry.registerCNSlider()
```

```markdown
SDUI core installs independently. Each `CNComponent+SDUI.swift` file owns
that component's state wrapper, wire-property parsing, and explicit registry
method. Call each installed component's registration method once during app
startup.
```

- [ ] **Step 5: Run all verification**

Run:

```bash
cd CLI && npm run typecheck && npm test
cd .. && ./scripts/sync-source.sh --dry-run
./scripts/test-example.sh
git diff --check
```

Expected: CLI checks PASS, sync reports no changes, Example tests PASS, and `git diff --check` prints nothing.

- [ ] **Step 6: Commit**

```bash
git add CLI/registry.json CLI/src/commands/add.ts CLI/src/__tests__/commands/add.test.ts CLI/README.md Sources/README.md CLAUDE.md
git commit -m "docs(sdui): expose modular registration"
```
