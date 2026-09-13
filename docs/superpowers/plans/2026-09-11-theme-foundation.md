# Theme Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reject invalid transported colors and modernize theme environment declaration without changing swiftcn's synchronous rendering architecture.

**Architecture:** Keep `Theme` as the Codable light/dark transport model, `ThemeProvider` as main-actor observable state, and `ResolvedTheme` as the SwiftUI environment value. Validate hexadecimal strings inside `Theme.ColorScheme` decoding and replace the manual environment key with `@Entry`.

**Tech Stack:** Swift 6, SwiftUI, Observation, Swift Testing, iOS 17+, Xcode 16+.

**Spec:** `docs/superpowers/specs/2026-09-11-foundation-hardening-design.md`

## Global Constraints

- Swift 6 with complete strict concurrency.
- iOS 17.0+, macOS 14.0+, Xcode 16+.
- Theme token data remains immutable `struct`, `Sendable`, and synchronously readable.
- `ThemeProvider` remains `@MainActor`; do not introduce another actor.
- No `ColorPair` and no `SwiftcnThemeMode`.
- No third-party dependency.
- Preserve current JSON keys and default fallback behavior for optional token groups.
- Canonical edits happen in `Sources/`, followed by source synchronization.

## File Map

- `Sources/Theme/Core/Theme.swift`: validate every decoded HEX field.
- `Sources/Theme/Provider/ThemeEnvironment.swift`: declare `theme` with `@Entry`.
- `Example/Tests/ThemeTests.swift`: invalid input and environment regressions.
- `CLI/src/commands/init.ts`: print the same root wiring used by the Example app.
- `CLI/src/__tests__/commands/init.test.ts`: setup-guidance regression.
- `README.md` and `Sources/README.md`: document the accepted runtime flow.

---

### Task 1: Validate hexadecimal colors at the JSON boundary

**Files:**
- Modify: `Sources/Theme/Core/Theme.swift:179-213`
- Modify: `Example/Tests/ThemeTests.swift:304-330`

**Interfaces:**
- Produces: private `KeyedDecodingContainer.decodeHex(forKey:) throws -> String`.
- Produces: private `KeyedDecodingContainer.decodeHexIfPresent(forKey:) throws -> String?`.
- Preserves: all public `Theme` and `Theme.ColorScheme` property types and initializers.

- [ ] **Step 1: Add a failing invalid-color test**

Append to `ThemeTests`:

```swift
@Test("Theme rejects an invalid hexadecimal color")
@MainActor
func themeRejectsInvalidHexColor() {
  let validScheme = """
    "foreground": "#000000",
    "card": "#ffffff",
    "cardForeground": "#000000",
    "sheet": "#ffffff",
    "sheetForeground": "#000000",
    "primary": "#000000",
    "primaryForeground": "#ffffff",
    "secondary": "#eeeeee",
    "secondaryForeground": "#000000",
    "muted": "#eeeeee",
    "mutedForeground": "#666666",
    "accent": "#eeeeee",
    "accentForeground": "#000000",
    "destructive": "#ff0000",
    "destructiveForeground": "#ffffff",
    "border": "#dddddd",
    "input": "#dddddd",
    "focus": "#000000",
    "warning": "#ffaa00",
    "warningForeground": "#000000",
    "success": "#00aa00",
    "successForeground": "#ffffff",
    "chart1": "#111111",
    "chart2": "#222222",
    "chart3": "#333333",
    "chart4": "#444444",
    "chart5": "#555555"
    """
  let json = """
    {
      "light": { "background": "not-a-color", \(validScheme) },
      "dark": { "background": "#000000", \(validScheme) }
    }
    """

  #expect(throws: DecodingError.self) {
    try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
  }

  let provider = ThemeProvider()
  let original = provider.currentTheme
  #expect(throws: ThemeError.self) {
    try provider.apply(Data(json.utf8))
  }
  #expect(provider.currentTheme == original)
}
```

This test intentionally reuses only the JSON field fragment inside the test function; production code gains no fixture abstraction.

- [ ] **Step 2: Run the focused suite and verify failure**

Run:

```bash
./scripts/test-example.sh
```

Expected: the invalid hexadecimal theme currently decodes, so the expectation fails.

- [ ] **Step 3: Add exact HEX decoding helpers**

Add below `Theme` in `Theme.swift`:

```swift
private extension KeyedDecodingContainer {
  func decodeHex(forKey key: Key) throws -> String {
    let value = try decode(String.self, forKey: key)
    guard value.isSupportedHexColor else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: self,
        debugDescription: "Expected #RRGGBB, RRGGBB, #AARRGGBB, or AARRGGBB"
      )
    }
    return value
  }

  func decodeHexIfPresent(forKey key: Key) throws -> String? {
    guard let value = try decodeIfPresent(String.self, forKey: key) else {
      return nil
    }
    guard value.isSupportedHexColor else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: self,
        debugDescription: "Expected #RRGGBB, RRGGBB, #AARRGGBB, or AARRGGBB"
      )
    }
    return value
  }
}

private extension String {
  var isSupportedHexColor: Bool {
    let digits = hasPrefix("#") ? dropFirst() : self[...]
    return (digits.count == 6 || digits.count == 8)
      && UInt64(digits, radix: 16) != nil
  }
}
```

- [ ] **Step 4: Decode every color field through the helpers**

Replace `Theme.ColorScheme.init(from:)` assignments:

```swift
background = try container.decodeHex(forKey: .background)
foreground = try container.decodeHex(forKey: .foreground)
card = try container.decodeHex(forKey: .card)
cardForeground = try container.decodeHex(forKey: .cardForeground)
sheet = try container.decodeHex(forKey: .sheet)
sheetForeground = try container.decodeHex(forKey: .sheetForeground)
primary = try container.decodeHex(forKey: .primary)
primaryForeground = try container.decodeHex(forKey: .primaryForeground)
secondary = try container.decodeHex(forKey: .secondary)
secondaryForeground = try container.decodeHex(forKey: .secondaryForeground)
muted = try container.decodeHex(forKey: .muted)
mutedForeground = try container.decodeHex(forKey: .mutedForeground)
accent = try container.decodeHex(forKey: .accent)
accentForeground = try container.decodeHex(forKey: .accentForeground)
destructive = try container.decodeHex(forKey: .destructive)
destructiveForeground = try container.decodeHex(forKey: .destructiveForeground)
border = try container.decodeHex(forKey: .border)
input = try container.decodeHex(forKey: .input)
focus = try container.decodeHex(forKey: .focus)
warning = try container.decodeHex(forKey: .warning)
warningForeground = try container.decodeHex(forKey: .warningForeground)
success = try container.decodeHex(forKey: .success)
successForeground = try container.decodeHex(forKey: .successForeground)
chart1 = try container.decodeHex(forKey: .chart1)
chart2 = try container.decodeHex(forKey: .chart2)
chart3 = try container.decodeHex(forKey: .chart3)
chart4 = try container.decodeHex(forKey: .chart4)
chart5 = try container.decodeHex(forKey: .chart5)
text = try container.decodeHexIfPresent(forKey: .text) ?? foreground
textSecondary = try container.decodeHexIfPresent(forKey: .textSecondary) ?? mutedForeground
textMuted = try container.decodeHexIfPresent(forKey: .textMuted) ?? mutedForeground
```

- [ ] **Step 5: Sync and run theme tests**

Run:

```bash
./scripts/sync-source.sh
./scripts/test-example.sh
```

Expected: PASS, including existing text fallbacks.

- [ ] **Step 6: Commit**

```bash
git add Sources/Theme/Core/Theme.swift Example/App/Theme/Core/Theme.swift Example/Tests/ThemeTests.swift
git commit -m "fix(theme): validate decoded hex colors"
```

---

### Task 2: Replace the manual environment key with @Entry

**Files:**
- Modify: `Sources/Theme/Provider/ThemeEnvironment.swift:10-22`
- Modify: `Example/Tests/ThemeTests.swift`

**Interfaces:**
- Preserves: writable `EnvironmentValues.theme: ResolvedTheme`.
- Produces: `@Entry public var theme: ResolvedTheme = .default`.

- [ ] **Step 1: Add and run an environment regression**

Append to `ThemeTests`:

```swift
@Test("Theme environment has the default resolved theme")
@MainActor
func themeEnvironmentHasDefault() {
  let values = EnvironmentValues()
  #expect(values.theme.radius.md == ThemeRadius.default.md)
  #expect(values.theme.spacing.md == ThemeSpacing.default.md)
}
```

Run:

```bash
./scripts/test-example.sh
```

Expected: PASS before the behavior-preserving refactor.

- [ ] **Step 2: Replace EnvironmentKey boilerplate**

Delete `ThemeKey` and the manual getter/setter. Keep:

```swift
extension EnvironmentValues {
  /// Access the resolved theme from the environment.
  @Entry public var theme: ResolvedTheme = .default
}
```

Do not alter `withThemeTracking`, `ThemeProvider`, `ResolvedTheme`, or any component's `@Environment(\.theme)` property.

- [ ] **Step 3: Sync and verify**

Run:

```bash
./scripts/sync-source.sh
./scripts/test-example.sh
```

Expected: PASS under Swift 6 complete strict concurrency.

- [ ] **Step 4: Commit**

```bash
git add Sources/Theme/Provider/ThemeEnvironment.swift Example/App/Theme/Provider/ThemeEnvironment.swift Example/Tests/ThemeTests.swift
git commit -m "refactor(theme): declare environment with Entry"
```

---

### Task 3: Let the theme modifier track system appearance itself

**Files:**
- Modify: `Sources/Theme/Provider/ThemeEnvironment.swift:24-37`
- Modify: `Example/App/App.swift`
- Modify: `CLI/src/commands/init.ts:199-219`
- Test: `CLI/src/__tests__/commands/init.test.ts`
- Modify: `README.md`
- Modify: `Sources/README.md`

**Interfaces:**
- Replaces: `View.withThemeTracking(_:systemColorScheme:)`.
- Produces: `View.withThemeTracking(_ themeProvider: ThemeProvider) -> some View`.
- Produces: setup output that tracks system appearance without a wrapper view.

- [ ] **Step 1: Add a failing setup-output test**

Add to `init.test.ts`:

```ts
it("prints the self-tracking theme setup", async () => {
  const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});
  await runInit(["-y"]);

  const output = logSpy.mock.calls.flat().join("\n");
  expect(output).toContain(".environment(themeProvider)");
  expect(output).toContain(".withThemeTracking(themeProvider)");
  expect(output).not.toContain("themeProvider.resolvedTheme");
});
```

- [ ] **Step 2: Run the test and verify failure**

Run:

```bash
cd CLI && npm test -- src/__tests__/commands/init.test.ts
```

Expected: output contains direct resolved-theme and preferred-color-scheme
modifiers instead of the self-tracking API.

- [ ] **Step 3: Move color-scheme observation into the view modifier**

Replace the existing view extension implementation with:

```swift
private struct ThemeTrackingModifier: ViewModifier {
  let themeProvider: ThemeProvider

  @Environment(\.colorScheme) private var systemColorScheme

  func body(content: Content) -> some View {
    content
      .environment(\.theme, themeProvider.resolvedTheme)
      .preferredColorScheme(themeProvider.resolvedColorScheme)
      .onChange(of: systemColorScheme, initial: true) { _, newScheme in
        themeProvider.updateSystemColorScheme(newScheme)
      }
  }
}

extension View {
  /// Apply theme values and track system appearance.
  public func withThemeTracking(_ themeProvider: ThemeProvider) -> some View {
    modifier(ThemeTrackingModifier(themeProvider: themeProvider))
  }
}
```

Simplify `ExampleApp.body` and delete `ContentWrapper`:

```swift
var body: some Scene {
  WindowGroup {
    MainTabView()
      .environment(themeProvider)
      .withThemeTracking(themeProvider)
  }
}
```

- [ ] **Step 4: Replace the generated setup hint and documentation**

Print from `init.ts`:

```ts
ui.line("  @State private var themeProvider = ThemeProvider()");
ui.break();
ui.line("  ContentView()");
ui.line("      .environment(themeProvider)");
ui.line("      .withThemeTracking(themeProvider)");
```

Use the same snippet in both READMEs, followed by:

```markdown
`Theme` is the Codable transport value, `ThemeProvider` owns main-actor UI state,
and components synchronously read `ResolvedTheme` from `@Environment(\.theme)`.
```

Do not document `ColorPair`, fold geometry, or another runtime configuration object.

- [ ] **Step 5: Run complete verification**

Run:

```bash
cd CLI && npm run typecheck && npm test
cd .. && ./scripts/sync-source.sh --dry-run
./scripts/test-example.sh
git diff --check
```

Expected: CLI checks PASS, source copies are synchronized, Example tests PASS, and `git diff --check` prints nothing.

- [ ] **Step 6: Commit**

```bash
git add Sources/Theme/Provider/ThemeEnvironment.swift Example/App/Theme/Provider/ThemeEnvironment.swift Example/App/App.swift CLI/src/commands/init.ts CLI/src/__tests__/commands/init.test.ts README.md Sources/README.md
git commit -m "refactor(theme): internalize system tracking"
```
