# swiftcn CNCard Style and Structure Alignment Design

**Date:** 2026-09-12

## Goal

Align `CNCard` style, structure, and composition with the canonical [shadcn/ui Card](https://ui.shadcn.com/docs/components/base/card) component. Support integrated slot parameters (`title`, `description`, `action`, `footer`, `content`), responsive size options (`.default` and `.sm`), optional bordered footer (`hasFooterDivider`), while maintaining 100% backwards compatibility with existing simple card usage and preserving dark mode surface lightness differentiation.

## Context

`swiftcn` is a template-based component library mirroring shadcn/ui principles in SwiftUI. In previous iterations, `CNCard` functioned as a simple container with uniform outer padding.

In shadcn/ui, a Card is composed of distinct sections:
- **CardHeader**: Contains `CardTitle`, `CardDescription`, and an optional `CardAction` slot on the trailing side.
- **CardContent**: The primary body of the card.
- **CardFooter**: Action/footer bar at the bottom, supporting either flush seamless placement or bordered separation (`border-t bg-muted/50`).
- **Size**: Supports `.default` and `.sm` (compact spacing and typography).

Based on user requirements and brainstorming alignment, `CNCard` adopts an **Integrated Slots Architecture** (Approach 1), providing an ergonomic single-container API with optional slot closures and convenience initializers.

## Requirements

### Platform & Architecture Requirements
- Swift 6 language mode with strict concurrency.
- iOS 17.0+ / macOS 14.0+.
- Native SwiftUI and Apple frameworks only (no third-party dependencies).
- Canonical files in `Sources/Components/` synced to `Example/App/Components/` via `./scripts/sync-source.sh`.
- Header comment format preserved on all Swift files.

### Functional Requirements
1. **Sizing (`CNCard.Size`)**:
   - `.default`: Standard spacing (24pt padding, headline title, subheadline description).
   - `.sm`: Compact spacing (16pt padding, subheadline semibold title, caption description).
2. **Slots Hierarchy**:
   - **Header Area**: Conditionally rendered if `title`, `description`, or `action` is present. Arranged with Title and Description on the leading side and Action slot on the trailing side (`HStack(alignment: .top)`).
   - **Content Area**: Houses the caller's main `@ViewBuilder content`.
   - **Footer Area**: Conditionally rendered if `footer` is present.
3. **Footer Styling (`hasFooterDivider: Bool`)**:
   - `false` (default): Seamless flush footer flowing directly below content.
   - `true`: Bordered divider (`theme.border`), full bleed inside card shape, with subtle container tint (`theme.muted.opacity(0.5)`), matching shadcn's scheduled reports pattern.
4. **Dark Mode & Variants (`CNCard.Variant`)**:
   - `.elevated`: Surface lightness `#18181b` (`theme.card.overlay(Color.white.opacity(0.06))`) in dark mode + subtle border + shadow.
   - `.outlined`: Flat `#09090b` surface + `#27272a` border.
   - `.filled`: Solid `#27272a` (`theme.muted`) fill without border.
5. **Backwards Compatibility**:
   - `CNCard(variant: ...) { content }` remains fully valid and functional.
6. **SDUI Integration**:
   - `CNCard.Configuration` updated to include `size`, `title`, and `description` with backward-compatible defaults.

## API Specification

```swift
public struct CNCard<Content: View>: View {

  // MARK: - Enums
  public enum Variant: String, Codable, CaseIterable, Sendable {
    case elevated
    case outlined
    case filled
  }

  public enum Size: String, Codable, CaseIterable, Sendable {
    case `default`
    case sm
  }

  // MARK: - Initializers

  /// Full slot-based initializer with string title & description
  public init<Action: View, Footer: View>(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder action: () -> Action,
    @ViewBuilder footer: () -> Footer,
    @ViewBuilder content: () -> Content
  )

  /// Initializer with action slot and content
  public init<Action: View>(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder action: () -> Action,
    @ViewBuilder content: () -> Content
  )

  /// Initializer with footer slot and content
  public init<Footer: View>(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder footer: () -> Footer,
    @ViewBuilder content: () -> Content
  )

  /// Custom header overload for arbitrary header content with footer
  public init<Header: View, Footer: View>(
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder header: () -> Header,
    @ViewBuilder footer: () -> Footer,
    @ViewBuilder content: () -> Content
  )

  /// Custom header overload for arbitrary header content without footer
  public init<Header: View>(
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder header: () -> Header,
    @ViewBuilder content: () -> Content
  )

  /// Convenience / backwards-compatible initializer
  public init(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder content: () -> Content
  )
}
```

> **Note on AnyView**: `CNCard` maintains a single generic parameter `Content` so simple cards avoid `AnyView` overhead entirely. Type erasure (`AnyView?`) is used strictly and internally for heterogeneous auxiliary slots (`action` and `footer`), defaulting to `nil` when omitted.

## Styling & Layout Metrics

| Metric | `.default` | `.sm` |
| :--- | :--- | :--- |
| **Horizontal Inset** | `theme.spacing.lg` (24pt) | `theme.spacing.md` (16pt) |
| **Header Top Inset** | `theme.spacing.lg` (24pt) | `theme.spacing.md` (16pt) |
| **Header Bottom Gap** | 10pt (`CardTokens.headerBottomGapDefault`) | 6pt (`CardTokens.headerBottomGapSm`) |
| **Content Vertical Padding** | 12pt (`theme.spacing.sm + theme.spacing.xs`) | 8pt (`theme.spacing.sm`) |
| **Footer Bottom Inset (Flush)**| `theme.spacing.lg` (24pt) | `theme.spacing.md` (16pt) |
| **Footer Inset (Divider Mode)**| 16pt (`theme.spacing.md`) | 12pt (`theme.spacing.sm + theme.spacing.xs`) |
| **Title Typography** | `.headline.weight(.semibold)` | `.subheadline.weight(.semibold)` |
| **Description Typography** | `.subheadline` | `.caption` |
| **Corner Radius** | `theme.radius.lg` | `theme.radius.lg` |

## SDUI Contract

```swift
extension CNCard {
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

## Verification Plan

1. **Unit Tests**:
   - Test `CNCard.Configuration` JSON encoding/decoding and fallback behavior in `ComponentTests.swift`.
   - Run `./scripts/test-example.sh` and verify all pass.
2. **CLI Test Suite**:
   - Run `./scripts/test-cli.sh` to confirm 106 CLI tests pass.
3. **Synchronized Sources**:
   - Run `./scripts/sync-source.sh` to ensure `Sources/` and `Example/App/` are byte-for-byte identical.
4. **Visual & Simulator Verification**:
   - Update `CardShowcase.swift` to demonstrate:
     - Full-featured Card (Title, Description, Action, Content, Footer)
     - Bordered Footer Card (`hasFooterDivider: true`)
     - Small Card (`size: .sm`)
     - Variant comparisons (.elevated, .outlined, .filled)
   - Capture simulator screenshots in Dark Mode and Light Mode to verify visual fidelity.
