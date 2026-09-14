# CNCard Style and Structure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `CNCard` style, structure, and composition with shadcn/ui Card by implementing slot-based architecture (`title`, `description`, `action`, `footer`, `content`), responsive sizing (`.default` and `.sm`), and optional bordered footer (`hasFooterDivider`), while maintaining 100% backwards compatibility and dark mode surface lightness.

**Architecture:** Refactor `CNCard` into an Integrated Slots container with dedicated layout sections (Header with Title, Description, and trailing Action; Content; and Footer with optional border-t divider and muted background). Expand `CNCard.Configuration` for SDUI serialization with fallback decoding, and update showcase and tests.

**Tech Stack:** Swift 6, SwiftUI, iOS 17+, Tuist, Vitest (CLI tests).

**Spec:** [docs/superpowers/specs/2026-09-12-card-style-and-structure-design.md](file:///Users/diki/Dev/my/swiftcn/docs/superpowers/specs/2026-09-12-card-style-and-structure-design.md)

## Global Constraints

- Swift 6 language mode with complete strict concurrency checking.
- iOS 17.0 or newer.
- Apple platform frameworks only; zero third-party Swift dependencies.
- Existing public `CNCard` component name unchanged.
- Canonical edits in `Sources/`, synchronized to `Example/App/` via `./scripts/sync-source.sh`.
- Header format preserved on all Swift files:
  ```swift
  //
  //  <FileName>.swift
  //  <RelativePath>
  //
  //  Created by Dicky Darmawan on <dd/mm/yy>.
  //
  ```

---

### Task 1: SDUI Configuration Contract & Serialization Tests

**Files:**
- Modify: `Sources/Components/CNCard+SDUI.swift`
- Test: `Example/Tests/ComponentTests.swift`

**Interfaces:**
- Consumes: `CNCard.Variant` from `CNCard.swift`.
- Produces: `CNCard.Size` enum, `CNCard.Configuration` with `variant: Variant`, `size: Size`, `title: String?`, `description: String?`, and backward-compatible JSON decoding.

- [ ] **Step 1: Write the failing test for CNCard.Configuration serialization and backwards compatibility**

Add tests to `Example/Tests/ComponentTests.swift`:
```swift
func testCardConfigurationSerialization() throws {
  let config = CNCard<AnyView>.Configuration(
    variant: .elevated,
    size: .sm,
    title: "Project Alpha",
    description: "Deployment status"
  )

  let data = try JSONEncoder().encode(config)
  let decoded = try JSONDecoder().decode(CNCard<AnyView>.Configuration.self, from: data)

  XCTAssertEqual(decoded.variant, .elevated)
  XCTAssertEqual(decoded.size, .sm)
  XCTAssertEqual(decoded.title, "Project Alpha")
  XCTAssertEqual(decoded.description, "Deployment status")
}

func testCardConfigurationBackwardsCompatibility() throws {
  // Simulates legacy JSON with only variant
  let legacyJSON = """
  { "variant": "outlined" }
  """.data(using: .utf8)!

  let decoded = try JSONDecoder().decode(CNCard<AnyView>.Configuration.self, from: legacyJSON)
  XCTAssertEqual(decoded.variant, .outlined)
  XCTAssertEqual(decoded.size, .default)
  XCTAssertNil(decoded.title)
  XCTAssertNil(decoded.description)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test-example.sh`
Expected: Compile failure (`size`, `title`, `description` not found).

- [ ] **Step 3: Update CNCard+SDUI.swift with Size enum & Configuration**

In `Sources/Components/CNCard+SDUI.swift`:
```swift
//
//  CNCard+SDUI.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

// MARK: - SDUI Configuration

extension CNCard {
  /// Configuration for SDUI rendering
  public struct Configuration: Codable, Sendable, Hashable {
    public let variant: Variant
    public let size: Size
    public let title: String?
    public let description: String?

    public init(
      variant: Variant = .elevated,
      size: Size = .default,
      title: String? = nil,
      description: String? = nil
    ) {
      self.variant = variant
      self.size = size
      self.title = title
      self.description = description
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.variant = try container.decodeIfPresent(Variant.self, forKey: .variant) ?? .elevated
      self.size = try container.decodeIfPresent(Size.self, forKey: .size) ?? .default
      self.title = try container.decodeIfPresent(String.self, forKey: .title)
      self.description = try container.decodeIfPresent(String.self, forKey: .description)
    }
  }
}
```
*Note: Ensure `CNCard.Size` is declared or available in `CNCard.swift` before compilation.*

- [ ] **Step 4: Run `./scripts/sync-source.sh` and `./scripts/test-example.sh`**

Run: `./scripts/sync-source.sh && ./scripts/test-example.sh`
Expected: Tests pass.

- [ ] **Step 5: Commit changes**

```bash
git add Sources/Components/CNCard+SDUI.swift Example/App/Components/CNCard+SDUI.swift Example/Tests/ComponentTests.swift
git commit -m "feat(card): update CNCard.Configuration with size, slots, and backward-compatible decoding"
```

---

### Task 2: Refactor CNCard with Integrated Slots & Sizing

**Files:**
- Modify: `Sources/Components/CNCard.swift`
- Sync: `Example/App/Components/CNCard.swift` via `./scripts/sync-source.sh`

**Interfaces:**
- Consumes: `theme.card`, `theme.cardForeground`, `theme.textMuted`, `theme.border`, `theme.spacing`, `theme.radius`, `theme.shadows`.
- Produces: `CNCard<Content>` with:
  - `Size`: `.default`, `.sm`
  - Slot properties: `title: String?`, `description: String?`, `@ViewBuilder action: () -> Action`, `@ViewBuilder footer: () -> Footer`, `@ViewBuilder content: () -> Content`
  - Overload for arbitrary header view
  - Backwards-compatible content-only initializer

- [ ] **Step 1: Write minimal code structure in `Sources/Components/CNCard.swift`**

Implement:
1. `public enum Size: String, Codable, CaseIterable, Sendable { case default, sm }`
2. Generic parameters: `public struct CNCard<Content: View>: View` (Note on AnyView: Single generic parameter `Content` is preserved on `CNCard`. `AnyView?` is used strictly internally for heterogeneous auxiliary slots `action` and `footer`, defaulting to `nil` when omitted).
3. Properties: `variant`, `size`, `title`, `description`, `hasFooterDivider`, `action: AnyView?`, `footer: AnyView?`, `content: Content`, `isCustomHeader: Bool`
4. Computed spacing metrics:
   - Inset horizontal: `size == .sm ? theme.spacing.md : theme.spacing.lg` (16pt vs 24pt)
   - Header top padding: `size == .sm ? theme.spacing.md : theme.spacing.lg` (16pt vs 24pt)
   - Header bottom gap: `size == .sm ? CardTokens.headerBottomGapSm : CardTokens.headerBottomGapDefault` (6pt vs 10pt)
   - Content vertical padding: `size == .sm ? theme.spacing.sm : (theme.spacing.sm + theme.spacing.xs)` (8pt vs 12pt)
   - Footer padding: `hasFooterDivider ? (size == .sm ? (theme.spacing.sm + theme.spacing.xs) : theme.spacing.md) : (size == .sm ? theme.spacing.md : theme.spacing.lg)`
   - Title font: `size == .sm ? .subheadline.weight(.semibold) : .headline.weight(.semibold)`
   - Description font: `size == .sm ? .caption : .subheadline`
5. Layout body:
   ```swift
   VStack(alignment: .leading, spacing: 0) {
     if hasHeader {
       headerView
         .padding(.horizontal, horizontalInset)
         .padding(.top, headerTopPadding)
         .padding(.bottom, contentVerticalPadding / 2)
     }

     content
       .padding(.horizontal, horizontalInset)
       .padding(.vertical, contentVerticalPadding)

     if hasFooter {
       if hasFooterDivider {
         Divider()
           .overlay(theme.border)
         footerView
           .padding(footerDividerInset)
           .frame(maxWidth: .infinity, alignment: .leading)
           .background(theme.muted.opacity(0.5))
       } else {
         footerView
           .padding(.horizontal, horizontalInset)
           .padding(.top, contentVerticalPadding / 2)
           .padding(.bottom, footerBottomPadding)
       }
     }
   }
   ```
6. Background, shape, border, and dark mode surface lightness preservation (`theme.card.overlay(Color.white.opacity(0.06))` for `.elevated`).
7. Initializers:
   - String title/description + action + footer + content
   - Custom header overload
   - Simple backwards-compatible init: `init(variant: Variant = .elevated, size: Size = .default, @ViewBuilder content: () -> Content)`

- [ ] **Step 2: Sync and verify compilation**

Run:
```bash
./scripts/sync-source.sh
touch Example/App/Components/*.swift
./scripts/test-example.sh
```
Expected: Build passes with 0 errors.

- [ ] **Step 3: Commit changes**

```bash
git add Sources/Components/CNCard.swift Example/App/Components/CNCard.swift
git commit -m "feat(card): implement integrated slots, sizing, and footer divider in CNCard"
```

---

### Task 3: Showcase Implementation in Example App

**Files:**
- Modify: `Example/App/Features/Components/Components/Showcases/CardShowcase.swift`

**Interfaces:**
- Consumes: `CNCard`, `CNButton`, `CNBadge` (if applicable), `theme`.
- Produces: Interactive visual showcase with all shadcn Card variations.

- [ ] **Step 1: Update `CardShowcase.swift`**

Add the 4 visual sections:
1. **Full Featured Card**:
   - `CNCard(title: "Create project", description: "Deploy your new project in one-click.", variant: .elevated, action: { CNButton("Draft", variant: .ghost, size: .sm) { } }, footer: { HStack { CNButton("Cancel", variant: .outline, size: .sm) { }; Spacer(); CNButton("Deploy", size: .sm) { } } }) { ... }`
2. **Scheduled Reports (with Footer Divider)**:
   - `CNCard(title: "Scheduled reports", description: "Weekly snapshots. No more manual exports.", variant: .elevated, size: .sm, hasFooterDivider: true, footer: { CNButton("Set up scheduled reports", size: .sm) { }.frame(maxWidth: .infinity) }) { ... }`
3. **Small Card (`size: .sm`)**:
   - Demonstrating compact typography and padding.
4. **Variant Comparison (.elevated, .outlined, .filled)**:
   - Showing the three surface variations side by side to ensure dark mode elevation contrast is maintained.

- [ ] **Step 2: Run test-example to verify compilation**

Run: `./scripts/test-example.sh`
Expected: Build succeeds with 0 errors, 0 warnings.

- [ ] **Step 3: Commit changes**

```bash
git add Example/App/Features/Components/Components/Showcases/CardShowcase.swift
git commit -m "feat(card): update CardShowcase with full-featured, scheduled reports, and size demos"
```

---

### Task 4: Verification, Test Automation & Visual Confirmation

**Files:**
- None modified (verification task)

- [ ] **Step 1: Run complete CLI test suite**

Run: `./scripts/test-cli.sh`
Expected: 106 tests pass.

- [ ] **Step 2: Run complete Example unit test suite**

Run: `./scripts/test-example.sh`
Expected: All unit tests pass with 0 errors.

- [ ] **Step 3: Build & install Example app on Simulator**

Run:
```bash
tuist generate
xcodebuild -workspace Example/Example.xcworkspace -scheme Example -destination 'platform=iOS Simulator,id=076A4BC1-2B08-4527-A38E-9B9424AD876F' build
xcrun simctl install booted Example/build/... (or derivedData)
xcrun simctl launch booted com.swiftcn.Example
```

- [ ] **Step 4: Capture simulator screenshot in Dark Mode and Light Mode**

Run:
```bash
xcrun simctl ui booted appearance dark
xcrun simctl io booted screenshot <artifactDir>/card_shadcn_dark.png
xcrun simctl ui booted appearance light
xcrun simctl io booted screenshot <artifactDir>/card_shadcn_light.png
```
Verify visual fidelity of Header, Title, Description, Action, Content, Footer, and Divider.

- [ ] **Step 5: Update walkthrough artifact and present review to user**
