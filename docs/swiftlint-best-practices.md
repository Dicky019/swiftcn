# SwiftLint Best Practices & Architecture Guide for swiftcn

**Document Version:** 1.0.0  
**Target Platform:** Swift 6.0+, iOS 17.0+, macOS 14.0+, Xcode 16+  
**Configuration File:** `.swiftlint.yml` (Root)  
**Target Architecture:** Modular Copy-Paste SwiftUI Components (shadcn/ui model), Tuist Project Generation, Observation Framework (`@Observable`), Strict Concurrency (`-strict-concurrency=complete`).

---

## 1. Executive Summary

### 1.1 Project Architecture
`swiftcn` is a modular, design-token-driven SwiftUI component library inspired by the architecture of [shadcn/ui](https://ui.shadcn.com). Unlike monolithic binary UI frameworks, `swiftcn` operates on four foundational pillars:
1. **Copy-Paste, Not Framework Dependency**: Canonical templates in `Sources/` are distributed into consuming applications via the `swiftcn` CLI tool. Consuming developers own the source code in their own repositories.
2. **Swift 6 Strict Concurrency**: All code is engineered for Swift 6 data race safety with `-strict-concurrency=complete`, utilizing explicit actor isolation (`@MainActor`), `Sendable` types, and structured concurrency.
3. **Observation Framework (`@Observable`)**: State management standardizes on the modern iOS 17+ / macOS 14+ Observation framework, eliminating legacy Combine `@Published` and `ObservableObject` overhead in favor of fine-grained dependency tracking and unified `@State` ownership.
4. **Tuist-Driven Project Structure**: The project pairs canonical source templates in `Sources/` with a fully featured demo and integration test app in `Example/`, configured via Tuist (`Example/Project.swift`).

### 1.2 SwiftLint Philosophy for swiftcn
A standard, uncalibrated SwiftLint configuration introduces severe friction when applied to modern declarative SwiftUI and copy-paste component architecture. Default rules routinely flag valid SwiftUI idioms—such as multiple trailing closures in `Button`, large declarative `body` builders, short design token names (`xs`, `sm`, `md`), and optional booleans in JSON wire models.

Our production `.swiftlint.yml` adheres to the following core philosophy:
- **Maximum Safety Where Compilers Are Permissive**: Catch silent runtime traps that the Swift compiler permits (e.g. unhandled throwing async `Task` initializers, unowned reference cycles, bare `fatalError()`).
- **Zero False-Positive Friction in Declarative SwiftUI**: Calibrate metrics and disable rules that misinterpret declarative view hierarchies, property wrappers, or token names.
- **Syntactic Cleanliness & Consistency**: Enforce modern Swift 5.7+ / Swift 6 idioms (`shorthand_optional_binding`, `first_where`, `toggle_bool`, `prefer_self_in_static_references`, uniform modifier order).
- **Binary & Security Hygiene**: Ban raw standard output logging (`print`, `_printChanges`) via custom regex rules in favor of Apple's unified `OSLog`, enforce `#fileID` over `#file` to prevent host path leakage, and discourage unchecked concurrency escapes (`@unchecked Sendable`).

---

## 2. Comparative Analysis of Industry Standards

To establish industry-proven conventions, we benchmarked our configuration against four authoritative Swift style guides and tooling standards:
1. **Airbnb Swift Style Guide & Tooling** (`airbnb/swift`): Pioneer of hybrid linting/formatting, strict bans on stdout logging, `#file`, and `@unchecked Sendable`.
2. **Point-Free Conventions** (`pointfreeco`: *TCA*, *swift-dependencies*, *isowords*): Industry vanguard of typed functional architecture, Apple `swift-format`, ubiquitous multiple trailing closures, and implicit `self`.
3. **Ray Wenderlich / Kodeco Swift Style Guide** (`kodecocodes/swift-style-guide`): Widely adopted commercial baseline emphasizing early-exit `guard`, `private` over `fileprivate`, and explicit SwiftUI closure exceptions.
4. **Official Apple Swift API Design Guidelines & Standard Toolchain** (`swift-format`, Swift 6): The ultimate language baseline prioritizing clarity at the point of use, standard shorthands, and compiler data race safety.

### 2.1 Industry Comparison Matrix

| Dimension | Airbnb (`airbnb/swift`) | Point-Free (`pointfreeco`) | Ray Wenderlich / Kodeco | Apple Guidelines / `swift-format` | swiftcn Production Standard |
|---|---|---|---|---|---|
| **Primary Tooling** | `SwiftFormat` + `SwiftLint` (`only_rules`) | Apple `swift-format` CLI | `SwiftLint` (`com.raywenderlich`) | Xcode native `swift-format` | Curated `SwiftLint` (Opt-in + Custom Regex) |
| **Trailing Closures** | Preserves labeled arguments | Ubiquitous multiple trailing closures | Single trailing closure preferred | Preferred when clear; native SwiftUI | Disables `multiple_closures_with_trailing_closure` |
| **`self` Policy** | Implicit `self` (`--self remove`) | Strict implicit `self` (SE-0269) | Implicit `self` where valid | Implicit `self` standard | Implicit `self` via `redundant_self_in_closure` |
| **Access Control (ACL)** | Declaration-level; omit `internal` | Minimal ACL boilerplate | `private` over `fileprivate` | Declaration-level; no extension ACL | Declaration-level; `internal` implicit |
| **Modifier Order** | ACL first (`public override`) | ACL first | ACL first | Language precedence | ACL first: `[acl, setterACL, override, final, ...]` |
| **View Body Limits** | Relaxed / Formatter handled | Not constrained by linter | Permitted overrides in UI | No arbitrary line limits | Relaxed: `warning: 160, error: 250` |
| **Design Token Identifiers** | Excludes short names | Short identifiers permitted | Standard 3-char minimum | Contextual clarity | Excludes `xs`, `sm`, `md`, `lg`, `xl`, `id`, `x`, `y` |
| **Concurrency Enforcement** | Custom rule: bans `@unchecked Sendable` | Strict `Sendable`, actors, `withLock` | Golden path error checks | Swift 6 `-strict-concurrency=complete` | Opt-in `unhandled_throwing_task`, custom rules |
| **Logging Policy** | Strictly bans `print()` | Structured dependencies | `print` in tutorials only | `OSLog` (Logger) | Custom rule: bans `print` in favor of `OSLog` |

### 2.2 Deep-Dive: Key Architectural Trade-Offs

#### 1. Trailing Closure Handling in SwiftUI
- **Conflict**: Legacy SwiftLint configurations include `multiple_closures_with_trailing_closure`, which flags calls where closure arguments are passed inside parentheses alongside a trailing closure:
  ```swift
  // Flagged by default SwiftLint:
  Button(action: { submit() }) {
      Text("Submit")
  }
  ```
- **Modern Consensus**: Swift 5.3 introduced labeled multiple trailing closures (`Button { submit() } label: { Text("Submit") }`), making multiple closures a first-class language feature. Point-Free, Apple, and modern commercial codebases use this syntax ubiquitously.
- **swiftcn Decision**: `multiple_closures_with_trailing_closure` is **explicitly disabled**. Furthermore, `trailing_closure` is **kept disabled** because forcing trailing closure syntax on every single multi-closure method creates ambiguity and breaks clean method signatures.

#### 2. Declaration Modifier Ordering
- **Conflict**: SwiftLint's default modifier order is `[override, acl, setterACL, dynamic, ...]`, which enforces `override public func render()`.
- **Modern Consensus**: Airbnb, Apple, and the broader Swift community place access control (`public`, `private`) at the beginning of the declaration because visibility to external callers is the most critical attribute when scanning code: `public override func render()`.
- **swiftcn Decision**: Configured `modifier_order` with `preferred_modifier_order: [acl, setterACL, override, final, dynamic, mutators, lazy, required, convenience, typeMethods, owned]`.

#### 3. Access Control on Extensions
- **Conflict**: The opt-in rule `extension_access_modifier` forces developers to declare access modifiers on extension headers (e.g. `private extension CNButton`).
- **Modern Consensus**: Apple's official `swift-format` specifically includes `"NoAccessLevelOnExtensionDeclaration": true`. Placing access modifiers on extensions silently breaks protocol conformances (Swift prohibits access modifiers on extensions that implement protocols) and obscures the visibility of individual members.
- **swiftcn Decision**: `extension_access_modifier` is **not enabled**. Access control is declared directly on individual members.

---

## 3. Rule Inventory & Detailed Rationale

The `.swiftlint.yml` configuration enables 33 curated opt-in rules, organized into four operational categories. Below is the comprehensive inventory detailing the exact defect prevented, autocorrect support, and technical rationale.

### 3.1 Safety & Concurrency Rules

| Rule Identifier | Kind | Autocorrect | Defect / Anti-Pattern Prevented | Rationale & Code Example |
|---|---|---|---|---|
| `unhandled_throwing_task` | Lint | No | Silent error loss in asynchronous tasks | In Swift, `Task { try await fetch() }` infers `Task<Void, any Error>`. Because the task handle is discarded, any thrown error is swallowed silently into void without logging or alert. This rule mandates error handling inside a `do-catch` or `try?`. |
| `fatal_error_message` | Idiomatic | No | Uninformative crash logs in production | Prevents bare `fatalError()`. Every crash must provide an informative message describing the invariant failure (e.g., `fatalError("Unreachable SDUI node type: \(node.type)")`). |
| `implicitly_unwrapped_optional` | Lint | No | Null-pointer dereference crashes (`nil`) | Forbids `var user: User!` outside `@IBOutlet` (which does not exist in SwiftUI). Enforces safe unwrapping via `if let`, `guard let`, or default fallbacks. |
| `async_without_await` | Lint | Yes | Unnecessary thread hopping & async overhead | Flags functions marked `async` that never invoke an `await` suspension point. Prevents adding artificial context switching and confusing API callers into thinking operations are non-blocking. |
| `self_in_property_initialization` | Lint | No | Accessing uninitialized memory during initialization | Catches cases where a property initializer refers to `self` before `super.init()` or complete property initialization has occurred. |
| `unowned_variable_capture` | Idiomatic | No | Unrecoverable memory safety panics | Discourages `[unowned self]` in closures. If the captured object is deallocated before the closure runs, `unowned` triggers an immediate SIGTRAP crash. Developers are directed toward `[weak self]` or value capture. |
| `redundant_sendable` | Lint | Yes | Redundant compiler annotations in Swift 6 | In Swift 6, types isolated to `@MainActor` or global actors are implicitly `Sendable`. Explicitly adding `: Sendable` creates clutter and compiler warnings. Autocorrects by stripping `: Sendable`. |

#### Example: `unhandled_throwing_task`
```swift
// ❌ Non-Compliant (Error is silently swallowed!):
Task {
    try await themeProvider.loadRemoteTheme(from: url)
}

// ✅ Compliant (Structured error handling with OSLog diagnostics):
Task {
    do {
        try await themeProvider.loadRemoteTheme(from: url)
    } catch {
        logger.error("Failed to load remote theme: \(error.localizedDescription)")
    }
}
```

---

### 3.2 Modern Swift 5.7+ / Swift 6 Idioms

| Rule Identifier | Kind | Autocorrect | Defect / Anti-Pattern Prevented | Rationale & Code Example |
|---|---|---|---|---|
| `shorthand_optional_binding` | Idiomatic | Yes | Verbose boilerplate in optional unwrapping | Enforces Swift 5.7+ shorthand: `if let theme {` instead of `if let theme = theme {`. Reduces syntactic noise across view hierarchies. |
| `first_where` | Performance | No | Inefficient $O(N)$ full-array scans and allocations | Replaces `items.filter { $0.id == id }.first` ($O(N)$ allocation + scan) with `items.first(where: { $0.id == id })` ($O(1)$ short-circuiting traversal). |
| `last_where` | Performance | No | Inefficient $O(N)$ allocations for terminal matching | Replaces `items.filter { $0.id == id }.last` with `items.last(where: { $0.id == id })`. |
| `contains_over_filter_count` | Performance | No | $O(N)$ memory allocation to check presence | Replaces `items.filter { $0.isActive }.count > 0` with `items.contains(where: { $0.isActive })`. Short-circuits on first match. |
| `contains_over_filter_is_empty` | Performance | No | Intermediate array allocation for emptiness check | Replaces `!items.filter { $0.matches }.isEmpty` with `items.contains(where: { $0.matches })`. |
| `contains_over_first_not_nil` | Performance | No | Inefficient matching syntax | Replaces `items.first(where: { $0.id == target }) != nil` with `items.contains(where: { $0.id == target })`. |
| `contains_over_range_nil_comparison` | Performance | No | Clunky range index checks for string containment | Replaces `text.range(of: substr) != nil` with `text.contains(substr)`. |
| `empty_count` | Performance | Yes | $O(N)$ traversal to test collection emptiness | Enforces `collection.isEmpty` over `collection.count == 0`. On non-RandomAccessCollections (e.g. lazy sequences or filters), `count` is $O(N)$ while `isEmpty` is $O(1)$. |
| `empty_string` | Idiomatic | Yes | Inexpressive string emptiness comparison | Enforces `string.isEmpty` over `string == ""`. |
| `toggle_bool` | Idiomatic | Yes | Clunky manual negation assignments | Replaces `isExpanded = !isExpanded` with `isExpanded.toggle()`. Standard idiom for `@State` toggles. |
| `array_init` | Idiomatic | Yes | Redundant map transformation to instantiate arrays | Prefers `Array(sequence)` over `sequence.map { $0 }`. |
| `reduce_into` | Performance | No | Quadratic copying in accumulator loops | In `reduce`, returning a new copy of a collection on every iteration causes $O(N^2)$ memory copying. `reduce(into:)` mutates in place ($O(N)$). |
| `prefer_zero_over_explicit_init` | Style | Yes | Verbose geometry initialization | Prefers `.zero` over `CGPoint(x: 0, y: 0)`, `CGSize(width: 0, height: 0)`, or `CGRect(x: 0, y: 0, width: 0, height: 0)`. |
| `prefer_self_in_static_references` | Style | Yes | Fragile hardcoded type names | Enforces `Self.defaultPadding` over `CNButton.defaultPadding` inside `CNButton`. Crucial for copy-paste components: renaming the struct automatically retains working static references. |
| `redundant_type_annotation` | Idiomatic | Yes | Redundant typing when RHS is unambiguous | Replaces `let radius: CGFloat = 8.0` or `var label: String = ""` with clean type inference where obvious. |
| `unneeded_parentheses_in_closure_argument` | Style | Yes | Parenthetical noise in closure parameters | Replaces `{ (item) in }` with `{ item in }`. |
| `untyped_error_in_catch` | Idiomatic | Yes | Redundant error casts in catch blocks | Prevents `catch let error as NSError`. In modern Swift, `catch` automatically binds `error: any Error`. |

#### Example: `prefer_self_in_static_references`
```swift
// ❌ Non-Compliant (If developer renames CNButton to PrimaryButton, this breaks):
public struct CNButton: View {
    public static let defaultSize: Size = .md
    
    public init() {
        self.size = CNButton.defaultSize
    }
}

// ✅ Compliant (Self-referential, copy-paste resilient):
public struct CNButton: View {
    public static let defaultSize: Size = .md
    
    public init() {
        self.size = Self.defaultSize
    }
}
```

---

### 3.3 Style, Layout & Formatting Rules

| Rule Identifier | Kind | Autocorrect | Defect / Anti-Pattern Prevented | Rationale & Code Example |
|---|---|---|---|---|
| `closure_spacing` | Style | Yes | Inconsistent inner brace spacing | Enforces `{ item in ... }` with uniform single-space padding, preventing cramped `{item in...}`. |
| `closure_end_indentation` | Style | Yes | Misaligned closing closure braces | Matches the indentation of the closing brace `}` with the line that opened the closure. |
| `collection_alignment` | Style | Yes | Ragged multi-line arrays and dictionaries | Vertically aligns elements in multi-line array and dictionary literals for immediate visual scanning. |
| `literal_expression_end_indentation` | Style | Yes | Misaligned collection brackets | Ensures the closing bracket `]` or `}` aligns with the start of the collection literal. |
| `modifier_order` | Style | Yes | Inconsistent keyword ordering on declarations | Standardizes ordering: `public final class` or `private static let`, eliminating random modifier churn across contributors. |
| `multiline_parameters` | Style | Yes | Chaotic function signature line breaks | Mandates that when parameter lists break across lines, each parameter sits on its own line. |
| `vertical_parameter_alignment_on_call` | Style | Yes | Ragged multiline function arguments | Vertically aligns arguments in multiline method and initializer invocations. |
| `sorted_imports` | Style | Yes | Disorganized and duplicate header imports | Enforces alphabetical ordering of imports (e.g. `import Foundation`, `import OSLog`, `import SwiftUI`), eliminating git merge conflicts. |

---

### 3.4 SwiftUI Ergonomics Rules

| Rule Identifier | Kind | Autocorrect | Defect / Anti-Pattern Prevented | Rationale & Code Example |
|---|---|---|---|---|
| `private_swiftui_state` | Lint | Yes | External exposure of internal SwiftUI state | `@State` and `@StateObject` properties represent internal view-managed storage. Exposing them as `internal` or `public` allows parent views to pass values that SwiftUI's runtime overrides. Enforces `private` or `fileprivate`. |

```swift
// ❌ Non-Compliant (Memberwise init exposes @State to parent views):
struct CounterView: View {
    @State var count: Int = 0
}

// ✅ Compliant (Encapsulated state lifecycle):
struct CounterView: View {
    @State private var count: Int = 0
}
```

---

## 4. SwiftUI Ergonomics & False Positive Prevention

Declarative SwiftUI code utilizes deeply nested view trees, computed properties for layout, token switch statements, and DSL closures. Leaving standard SwiftLint metrics at their default values creates constant false-positive friction. Below is the complete rationale for all disabled and relaxed rules.

### 4.1 Disabled Rules

#### 1. `multiple_closures_with_trailing_closure`
- **SwiftLint Default**: Enabled.
- **Why Disabled**: SwiftUI's primary interaction and layout primitives rely fundamentally on multiple trailing closures:
  ```swift
  // Standard SwiftUI Button:
  Button {
      action()
  } label: {
      Text("Submit")
  }
  ```
  If an action closure is passed inside parentheses `Button(action: { ... }) { ... }`, the default rule emits a violation. Disabling this rule prevents spurious warnings across every button, section, and sheet in the codebase.

#### 2. `trailing_closure`
- **SwiftLint Default**: Opt-in (Disabled).
- **Why Kept Disabled**: This rule forces trailing closure syntax unconditionally whenever the final argument of a method is a closure. In SwiftUI, forcing trailing closures on methods with multiple closure parameters or methods where parameter labels provide crucial context (e.g. `.sheet(isPresented:content:)` vs `.sheet(isPresented:) { ... }`) leads to unreadable, ambiguous syntax.

#### 3. Obsolete UIKit & Interface Builder Rules
- **Rules Disabled**: `strong_iboutlet`, `prohibited_interface_builder`, `valid_ibinspectable`, `ibinspectable_in_extension`, `private_outlet`, `private_action`.
- **Why Disabled**: `swiftcn` is a pure SwiftUI library targeting iOS 17+ and macOS 14+. Storyboards, XIBs, and Interface Builder macros (`@IBOutlet`, `@IBAction`, `@IBInspectable`) do not exist in this architecture. Keeping these rules active wastes AST analysis cycles.

#### 4. `todo`
- **SwiftLint Default**: Enabled (Warning).
- **Why Disabled**: In a copy-paste component library with active roadmap expansion and template placeholders, developers routinely leave `// TODO:` markers for optional user extensions. Blocking builds or generating CI noise on planned roadmap tasks creates counterproductive friction.

#### 5. `discouraged_optional_boolean`
- **SwiftLint Default**: Opt-in (Disabled).
- **Why Kept Disabled**: The rule flags `Bool?` under the premise that optional booleans create confusing tri-state logic. However, in Server-Driven UI (SDUI) wire payloads and dynamic JSON models (such as `CNButton.Configuration.isLoading: Bool?` and `AnyCodable`), `nil` carries the precise semantic meaning: *"the key was omitted by the server; use the client default"*. Enabling this rule would break SDUI deserialization.

---

### 4.2 Calibrated Metric Thresholds

```
┌────────────────────────────────────────────────────────────────────────────────────────────┐
│                             SWIFTLINT METRIC CALIBRATION                                  │
├──────────────────────────┬──────────────────────────┬──────────────────────────────────────┤
│ Metric Rule              │ Default Thresholds       │ swiftcn Calibrated Thresholds        │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ function_body_length     │ warning: 50, error: 100  │ warning: 160, error: 250             │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ type_body_length         │ warning: 250, error: 350 │ warning: 400, error: 600             │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ file_length              │ warning: 400, error: 1000│ warning: 600, error: 1200            │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ cyclomatic_complexity    │ warning: 10, error: 20   │ warning: 15, error: 25 (ignores case)│
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ large_tuple              │ warning: 2, error: 3     │ warning: 4, error: 6                 │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ line_length              │ warning: 120, error: 200 │ warning: 140, error: 250 (ignores *) │
├──────────────────────────┼──────────────────────────┼──────────────────────────────────────┤
│ nesting (type_level)     │ warning: 1, error: 2     │ warning: 3, error: 4                 │
└──────────────────────────┴──────────────────────────┴──────────────────────────────────────┘
```

#### Detailed Justifications:
1. **`function_body_length` (160 / 250)**: SwiftUI's computed `var body: some View` describes an entire layout hierarchy. In declarative showcase galleries (such as `ButtonShowcase` at 114 lines and `CardShowcase` at 150 lines) and composite screens (such as `SDUIPlaygroundView` at 94 lines), cohesive views demonstrate multiple variants, sizes, and states. Raising the warning threshold to 160 and error to 250 avoids forcing developers to break view trees into artificial, single-use subviews prematurely, while keeping showcases fully linted for safety and style rules.
2. **`type_body_length` (400 / 600)**: A self-contained copy-paste component file bundles its primary struct, `Size` and `Variant` enums, accessibility extensions, styling token resolvers, and multiple `#Preview` blocks. For example, `CNButton.swift` is 250 lines out of the box. A 400-line warning threshold preserves component co-location without triggering warnings.
3. **`file_length` (600 / 1200)**: Prevents artificial file splitting for composite component showcases or components with rich SDUI configurations. Configured with `ignore_comment_only_lines: true`.
4. **`cyclomatic_complexity` (15 / 25)**: View styling properties routinely use exhaustive `switch` statements over component variants and sizes:
   ```swift
   private var backgroundColor: Color {
       switch variant {
       case .default: theme.primary
       case .destructive: theme.destructive
       case .secondary: theme.secondary
       case .outline: theme.background
       case .ghost, .link: .clear
       }
   }
   ```
   With `ignores_case_statements: true`, standard variant mapping does not penalize complexity scores.
5. **`large_tuple` (4 / 6)**: SwiftUI and CoreGraphics frequently pass coordinate pairs, layout offsets, and RGB/HSB color token triplets (e.g. `(CGFloat, CGFloat, CGFloat)`). The default warning threshold of 2 flags every 3-element tuple; raising it to 4 accommodates graphic primitives.
6. **`line_length` (140 / 250)**: Chained modifiers (`.accessibilityLabel(...)`, `.presentationDetents(...)`), string interpolations, and descriptive `#Preview` macro names can legitimately extend lines. Configured with `ignores_urls: true`, `ignores_comments: true`, and `ignores_interpolated_strings: true`. Additionally, static embedded data fixtures (such as `Example/App/Features/SDUI/Models`) that contain large multiline raw JSON mock templates (exceeding 200 characters without interpolation) are explicitly excluded in `.swiftlint.yml` because SwiftLint's `line_length` rule lacks an `ignores_strings` option.
7. **`nesting` (type_level: 3 / 4)**: Modern SwiftUI relies on namespacing sub-types inside parent components: `CNButton.Size`, `CNButton.Variant`, and `CNButton.Configuration`. Allowing 3 nesting levels supports clean modular namespacing.

---

### 4.3 Design Token Identifier Exemptions (`identifier_name`)

Default SwiftLint enforces a minimum identifier length of 3 characters (`min_length: 3`). In a design token library like `swiftcn`, this immediately causes fatal lint errors:
- **Design Token Sizes**: `ThemeSpacing` and `ThemeRadius` use standard T-shirt sizing: `xs`, `sm`, `md`, `lg`, `xl`.
- **Component Variants**: `CNButton.Size` defines `case sm`, `case md`, `case lg`.
- **SwiftUI & Layout Primitives**: Standard identifiers include `id` (required by `Identifiable`), `x`, `y`, `z` (geometry and 3D rotation), `i`, `j`, `k` (loop indices), and `to`, `up`, `at` (navigation and timing).

**Configured Exclusions**:
```yaml
identifier_name:
  min_length:
    warning: 1
    error: 1
  max_length:
    warning: 60
    error: 80
  excluded:
    - xs
    - sm
    - md
    - lg
    - xl
    - id
    - x
    - y
    - z
    - i
    - j
    - k
    - to
    - up
    - at
```

---

## 5. Custom Regex Rules Deep-Dive

To enforce safety guarantees that standard rules cannot capture, four custom regex rules are configured in `.swiftlint.yml`.

### 5.1 Banning Raw Standard Out Logging (`no_direct_standard_out_logs`)
- **Severity**: `warning`
- **Pattern**: `'(?<![\.\w])(?:print|debugPrint|dump|_printChanges)\s*\(|Swift\.(?:print|debugPrint|dump)\s*\('`
- **Match Kinds**: `[identifier]`
- **Rationale**: In production libraries, raw `print(...)`, `debugPrint(...)`, `dump(...)`, and SwiftUI's internal debugging hook `_printChanges()` write synchronously to stdout, bypassing system log retention, leaking sensitive data, and degrading UI frame rates. `swiftcn` standardizes on Apple's unified `OSLog` framework (`Logger(subsystem:category:)`). The regex utilizes negative lookbehind `(?<![\.\w])` to guarantee that valid member method invocations (e.g. `printer.print(doc:)`, `document.print()`, `customLogger.dump()`) and method declarations do not trigger false positives, while still catching direct global calls and `Swift.print(...)`. Restricting matches to `identifier` ensures comments referencing `print` in documentation do not trigger false positives.

```swift
// ❌ Non-Compliant:
print("Theme updated to \(newTheme.name)")
Self._printChanges()

// ✅ Compliant:
import OSLog
private let logger = Logger(subsystem: "com.swiftcn.theme", category: "ThemeProvider")
logger.notice("Theme updated to \(newTheme.name, privacy: .public)")
```

---

### 5.2 Discouraging `@unchecked Sendable` (`no_unchecked_sendable`)
- **Severity**: `warning`
- **Pattern**: `'@unchecked\s+Sendable'`
- **Match Kinds**: `[attribute.builtin, typeidentifier]`
- **Rationale**: In Swift 6, `@unchecked Sendable` is an escape hatch that silences compiler data race checks without guaranteeing thread safety. While occasionally necessary for legacy C pointers or locks, its usage in modern SwiftUI code must be discouraged and explicitly justified.

```swift
// ❌ Non-Compliant (Silences compiler without thread safety proof):
public final class CacheManager: @unchecked Sendable {
    private var cache: [String: Any] = [:]
}

// ✅ Compliant (Actor isolation guarantees thread safety):
public actor CacheManager {
    private var cache: [String: Any] = [:]
}
```

---

### 5.3 Preventing Direct `@State` Assignment in View Initializers (`no_direct_state_assignment_in_init`)
- **Severity**: `error`
- **Pattern**: `'(?s)@State(?:\s*\([^)]*\))?\s+(?:(?:private|fileprivate)\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)\b(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*?init\s*\([^{}]*\)\s*\{(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*?(?:\{[^{}]*){0,2}\bself\.\1\s*='`
- **Rationale**: Assigning `self.property = value` inside a SwiftUI `init()` when `property` is annotated with `@State` bypasses SwiftUI's internal storage lifecycle. The assigned value will be overwritten or lost during subsequent view updates. Backing storage must be initialized using `self._property = State(initialValue: ...)`.
- **Structural Boundaries & ReDoS Mitigation**:
  - **Scope Isolation**: Bounded by Level-2 balanced brace matching `(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*?` between `@State` and `init()` to accommodate helper methods or properties preceding `init()` while preventing match leakage across distinct type declarations in the same file.
  - **Zero-Backtracking ReDoS Safety**: Earlier iterations using unanchored, overlapping brace alternatives within `init()` suffered from catastrophic backtracking ($O(30^N)$ time complexity) when evaluating nested control-flow blocks lacking an assignment, causing ICU/NSRegularExpression engines to hang on $N \ge 5$ nested blocks. The remediated pattern decouples fully balanced closed blocks `(?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*?` from up to 2 open conditional scopes `(?:\{[^{}]*){0,2}`, providing strictly linear $O(N)$ execution (<0.0001s across benchmark tests up to $N=100$) and eliminating false negatives after closed `if` statements or inside `else` branches.
  - **Formal Language Limits**: Arbitrarily nested delimiters form a context-free grammar (Chomsky Type 2); regular expressions (Chomsky Type 3) provide a deterministic, ReDoS-safe syntactic guardrail for common structures, while deeply nested structures (≥3 levels) or assignments omitting the explicit `self.` qualifier fail open safely and are deferred to compiler/AST diagnostics.

```swift
// ❌ Non-Compliant (Bypasses State storage lifecycle):
struct CNInput: View {
    @State private var text: String
    
    init(defaultText: String) {
        self.text = defaultText // Silent SwiftUI lifecycle bug!
    }
}

// ✅ Compliant (Initializes backing storage):
struct CNInput: View {
    @State private var text: String
    
    init(defaultText: String) {
        self._text = State(initialValue: defaultText)
    }
}
```

---

### 5.4 Enforcing `#fileID` Over `#file` (`no_file_literal`)
- **Severity**: `warning`
- **Pattern**: `'(#file\b)'`
- **Match Kinds**: `[keyword]`
- **Rationale**: In Swift 5.3+, `#file` was redefined to evaluate to the full, absolute machine path (e.g. `/Users/runner/work/swiftcn/...`). Embedding absolute host paths into compiled binaries leaks developer usernames, directory structures, and CI paths while bloating binary size. `#fileID` provides a compact, portable `ModuleName/FileName.swift` string.

```swift
// ❌ Non-Compliant (Leaks host filesystem paths into binary):
logger.error("Assertion failed at \(#file):\(#line)")

// ✅ Compliant (Portable and compact):
logger.error("Assertion failed at \(#fileID):\(#line)")
```

---

## 6. Swift 6 Strict Concurrency Guide

### 6.1 Compiler vs. SwiftLint Synergy
Swift 6 introduces mathematically verifiable compile-time data race safety under `-strict-concurrency=complete`:
- **Compiler Authority**: Actor isolation, region-based isolation (SE-0414), and `Sendable` boundary crossings are strictly enforced by `swiftc`.
- **SwiftLint Guardrails**: SwiftLint provides syntactic guardrails that catch semantic pitfalls before compile time:
  1. `unhandled_throwing_task`: Guards against discarded `Task` instances that swallow exceptions.
  2. `redundant_sendable`: Cleans up explicit `: Sendable` conformances that are redundant on actor-isolated types.
  3. `async_without_await`: Prevents dead `async` qualifiers that force unnecessary suspension points.

### 6.2 Modern State Management with `@Observable`
In iOS 17+ / Swift 5.9+, the Observation framework fundamentally alters how state flows through SwiftUI:
```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        OBSERVATION FRAMEWORK STATE PATTERNS                            │
├──────────────────────────┬─────────────────────────────┬───────────────────────────────┤
│ Concept                  │ Legacy SwiftUI (iOS 13–16)  │ Modern SwiftUI (iOS 17+)      │
├──────────────────────────┼─────────────────────────────┼───────────────────────────────┤
│ State Model Definition   │ class Model: ObservableObject│ @Observable class Model       │
│ Property Tracking        │ @Published var name: String │ var name: String (implicit)   │
│ View Ownership           │ @StateObject private var m  │ @State private var m = Model()│
│ View Injection           │ .environmentObject(m)       │ .environment(m)               │
│ View Consumption         │ @EnvironmentObject var m    │ @Environment(Model.self) var m│
│ Passing to Subview       │ @ObservedObject var m: Model│ let m: Model                  │
│ Re-render Invalidation   │ Coarse: Any property change │ Fine: Only accessed properties│
└──────────────────────────┴─────────────────────────────┴───────────────────────────────┘
```

#### Impact on SwiftLint:
- **`@State` for Reference Types**: Because modern SwiftUI uses `@State` to instantiate reference-type `@Observable` models, the `private_swiftui_state` rule is critical. Declaring `@State private var themeProvider = ThemeProvider()` ensures that parent views cannot inject replacement instances, preserving clean lifecycle boundaries.
- **Absence of `@Published`**: `@Observable` macro expansion eliminates the need for property wrappers on model properties. Rules designed for Combine subjects (like `private_subject`) are unnecessary in `swiftcn`.

---

## 7. Integration, Tooling & Workflows

### 7.1 Running SwiftLint Locally

#### Basic Linting
To run SwiftLint from the repository root:
```bash
swiftlint lint --config .swiftlint.yml
```

#### Strict Linting (Treat Warnings as Errors in CI)
```bash
swiftlint lint --config .swiftlint.yml --strict
```

#### Automated Fixing (Autocorrection)
SwiftLint can automatically correct formatting, sorted imports, closure spacing, and shorthand bindings:
```bash
swiftlint --fix --config .swiftlint.yml
```

---

### 7.2 Tuist Integration (`Example/Project.swift`)

To run SwiftLint automatically during project builds in Tuist, configure a target script in `Example/Project.swift`:

```swift
import ProjectDescription

let project = Project(
    name: "Example",
    targets: [
        .target(
            name: "Example",
            destinations: .iOS,
            product: .app,
            bundleId: "com.swiftcn.example",
            infoPlist: .default,
            sources: ["App/**"],
            resources: ["App/Features/Theme/Resources/**"],
            scripts: [
                .pre(
                    script: """
                    if which swiftlint >/dev/null; then
                        swiftlint lint --config ../.swiftlint.yml
                    else
                        echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
                    fi
                    """,
                    name: "Run SwiftLint",
                    basedOnDependencyAnalysis: false
                )
            ]
        )
    ]
)
```

---

### 7.3 Xcode Build Phase Run Script

If building via generated Xcode workspaces (`Example/Example.xcworkspace`), add a Run Script build phase with Homebrew PATH resolution:

```bash
# Resolve Homebrew path on both Apple Silicon (/opt/homebrew) and Intel (/usr/local)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if which swiftlint >/dev/null; then
    swiftlint lint --config "${SRCROOT}/../.swiftlint.yml"
else
    echo "warning: SwiftLint not installed. Install via: brew install swiftlint"
fi
```

---

### 7.4 GitHub Actions CI Workflow

Create `.github/workflows/lint.yml` to validate code quality on every pull request:

```yaml
name: SwiftLint Quality Gate

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  swiftlint:
    name: SwiftLint Analysis
    runs-on: macos-14

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install SwiftLint
        run: |
          brew install swiftlint

      - name: Verify SwiftLint Version
        run: |
          swiftlint version

      - name: Execute SwiftLint Quality Gate
        run: |
          swiftlint lint --config .swiftlint.yml --strict --reporter github-actions-logging
```

---

### 7.5 Codebase Migration & Remediation Playbook

When adopting this production configuration across existing codebases or integrating `swiftcn` components into external projects, teams frequently encounter common friction points. Below is the standard remediation playbook:

#### 1. Import Alphabetization (`sorted_imports`)
- **Diagnostic**: `Imports should be sorted (sorted_imports)`
- **Remediation**: Alphabetize imports by module name. SwiftLint compares module symbols case-insensitively.
  ```swift
  // ❌ Non-Compliant:
  import SwiftUI
  import OSLog

  // ✅ Compliant:
  import OSLog
  import SwiftUI
  ```
- **Test Files**: For tests importing `@testable import Target`, order alphabetically by symbol name (`Example` < `SwiftUI` < `Testing`) or separate testable imports with an empty newline to create distinct import groups.
- **Autocorrect**: Can be resolved automatically across the codebase via `swiftlint --fix`.

#### 2. Swift 6 Concurrency Redundancies (`redundant_sendable`)
- **Diagnostic**: `Redundant Sendable conformance (redundant_sendable)`
- **Remediation**: In Swift 6 (`-strict-concurrency=complete`), classes isolated to `@MainActor` (or any global actor) implicitly conform to `Sendable`. Explicitly writing `: Sendable` is redundant.
  ```swift
  // ❌ Non-Compliant:
  @Observable @MainActor
  public final class ThemeProvider: Sendable { ... }

  // ✅ Compliant (Clean, Swift 6 idiomatic):
  @Observable @MainActor
  public final class ThemeProvider { ... }
  ```

#### 3. Static Self-References (`prefer_self_in_static_references`)
- **Diagnostic**: `Use Self instead of type name in static references (prefer_self_in_static_references)`
- **Remediation**: Inside a type's own declaration, refer to static properties and methods via `Self` rather than repeating the concrete type name. This makes components copy-paste resilient when renamed by consumers.
  ```swift
  // ❌ Non-Compliant:
  public static let `default` = ResolvedTheme.resolve(theme: .default, isDark: false)

  // ✅ Compliant (Copy-paste safe):
  public static let `default` = Self.resolve(theme: .default, isDark: false)
  ```

#### 4. Declarative SwiftUI Showcases & Galleries (`function_body_length`)
- **Diagnostic**: `Function body should span 160 lines or less (function_body_length)`
- **Remediation**: In declarative SwiftUI, component showcases (`ButtonShowcase`, `CardShowcase`) demonstrate variants, sizes, and states in a cohesive gallery. Rather than artificially fragmenting cohesive view hierarchies, configure `function_body_length: warning: 160, error: 250`.

#### 5. Embedded Mock Data Strings (`line_length`)
- **Diagnostic**: `Line should be 140 characters or less (line_length)`
- **Remediation**: SwiftLint's `line_length` lacks an `ignores_strings` flag for multiline raw JSON mock strings. Add mock fixture folders (e.g. `Example/App/Features/SDUI/Models`) to `excluded:` in `.swiftlint.yml`.

---

## 8. Summary of Excluded Paths

The following paths are explicitly excluded from SwiftLint analysis in `.swiftlint.yml`:

```yaml
excluded:
  # Swift Package Manager build cache
  - .build
  # Xcode DerivedData and Tuist build directories
  - Derived
  - derivedData
  - build
  - .swiftpm
  # Tuist generated source artifacts & bundles
  - Example/Derived
  # Generated Xcode projects & workspaces
  - Example/Example.xcodeproj
  - Example/Example.xcworkspace
  - Example/Project.swift
  # Test mock data & fixtures
  - Example/Tests/Fixtures
  - Example/App/Features/SDUI/Models
  # Non-Swift tooling and documentation
  - CLI
  - scripts
  - docs
  # Agent metadata and version control
  - .agents
  - .git
  - .superpowers
  - .maestro
  - .serena
```

---

## 9. Conclusion
This configuration and guide provide a complete, industry-aligned SwiftLint setup for `swiftcn`. By disabling obsolete UIKit checks and SwiftUI trailing closure friction while introducing rigorous concurrency safeguards and modern Swift 5.7+ / Swift 6 idioms, the configuration protects code safety and design integrity while maintaining an ergonomic, productive developer experience.
