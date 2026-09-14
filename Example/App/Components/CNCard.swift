//
//  CNCard.swift
//  Sources/Components
//
//  Created by Dicky Darmawan on 05/02/26.
//

import SwiftUI

/// A container with rounded corners, optional shadow, and flexible content.
///
/// Usage:
/// ```swift
/// CNCard {
///     Text("Card content")
/// }
///
/// CNCard(title: "Notifications", description: "Manage your alerts.") {
///     Text("Card body")
/// }
///
/// CNCard(variant: .outlined) {
///     VStack { ... }
/// }
/// ```
public struct CNCard<Content: View>: View {

  // MARK: - Variants

  public enum Variant: String, Codable, CaseIterable, Sendable {
    case elevated   // Shadow + background
    case outlined   // Border + background
    case filled     // Just background
  }

  // MARK: - Sizing

  public enum Size: String, Codable, CaseIterable, Sendable {
    case `default`
    case sm
  }

  // MARK: - Properties

  private let variant: Variant
  private let size: Size
  private let title: String?
  private let description: String?
  private let hasFooterDivider: Bool
  private let action: AnyView?
  private let footer: AnyView?
  private let content: Content
  private let isCustomHeader: Bool

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.theme) private var theme

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
  ) {
    self.variant = variant
    self.size = size
    self.title = title
    self.description = description
    self.hasFooterDivider = hasFooterDivider
    self.action = Action.self == EmptyView.self ? nil : AnyView(action())
    self.footer = Footer.self == EmptyView.self ? nil : AnyView(footer())
    self.content = content()
    self.isCustomHeader = false
  }

  /// Initializer with action slot and content
  public init<Action: View>(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder action: () -> Action,
    @ViewBuilder content: () -> Content
  ) {
    self.variant = variant
    self.size = size
    self.title = title
    self.description = description
    self.hasFooterDivider = hasFooterDivider
    self.action = Action.self == EmptyView.self ? nil : AnyView(action())
    self.footer = nil
    self.content = content()
    self.isCustomHeader = false
  }

  /// Initializer with footer slot and content
  public init<Footer: View>(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder footer: () -> Footer,
    @ViewBuilder content: () -> Content
  ) {
    self.variant = variant
    self.size = size
    self.title = title
    self.description = description
    self.hasFooterDivider = hasFooterDivider
    self.action = nil
    self.footer = Footer.self == EmptyView.self ? nil : AnyView(footer())
    self.content = content()
    self.isCustomHeader = false
  }

  /// Custom header overload for arbitrary header content with footer
  public init<Header: View, Footer: View>(
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder header: () -> Header,
    @ViewBuilder footer: () -> Footer,
    @ViewBuilder content: () -> Content
  ) {
    self.variant = variant
    self.size = size
    self.title = nil
    self.description = nil
    self.hasFooterDivider = hasFooterDivider
    self.action = Header.self == EmptyView.self ? nil : AnyView(header())
    self.footer = Footer.self == EmptyView.self ? nil : AnyView(footer())
    self.content = content()
    self.isCustomHeader = true
  }

  /// Custom header overload for arbitrary header content without footer
  public init<Header: View>(
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder header: () -> Header,
    @ViewBuilder content: () -> Content
  ) {
    self.variant = variant
    self.size = size
    self.title = nil
    self.description = nil
    self.hasFooterDivider = hasFooterDivider
    self.action = Header.self == EmptyView.self ? nil : AnyView(header())
    self.footer = nil
    self.content = content()
    self.isCustomHeader = true
  }

  /// Initializer with optional title, description, and content (standard / backwards-compatible)
  public init(
    title: String? = nil,
    description: String? = nil,
    variant: Variant = .elevated,
    size: Size = .default,
    hasFooterDivider: Bool = false,
    @ViewBuilder content: () -> Content
  ) {
    self.variant = variant
    self.size = size
    self.title = title
    self.description = description
    self.hasFooterDivider = hasFooterDivider
    self.action = nil
    self.footer = nil
    self.content = content()
    self.isCustomHeader = false
  }

  // MARK: - Body

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if hasHeader {
        headerView
          .padding(.horizontal, horizontalInset)
          .padding(.top, headerTopPadding)
          .padding(.bottom, headerBottomGap)
      }

      content
        .padding(.horizontal, horizontalInset)
        .padding(.top, contentTopPadding)
        .padding(.bottom, contentBottomPadding)

      if let footer {
        if hasFooterDivider {
          Divider()
            .overlay(theme.border)
          footer
            .padding(footerDividerInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.muted.opacity(CardTokens.footerDividerBackgroundOpacity))
        } else {
          footer
            .padding(.horizontal, horizontalInset)
            .padding(.top, contentVerticalPadding / 2)
            .padding(.bottom, footerBottomPadding)
        }
      }
    }
    .foregroundStyle(theme.cardForeground)
    .background(backgroundView)
    .clipShape(shape)
    .overlay {
      if hasBorder {
        shape.stroke(theme.border, lineWidth: theme.borderWidth.regular)
          .allowsHitTesting(false)
      }
    }
    .shadow(
      color: shadowColor,
      radius: shadowRadius,
      y: shadowY
    )
  }

  // MARK: - Subviews

  @ViewBuilder
  private var headerView: some View {
    if isCustomHeader {
      if let action {
        action
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    } else {
      HStack(alignment: .top, spacing: theme.spacing.sm) {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          if let title {
            Text(title)
              .font(titleFont)
              .foregroundStyle(theme.cardForeground)
          }
          if let description {
            Text(description)
              .font(descriptionFont)
              .foregroundStyle(theme.textMuted)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let action {
          action
        }
      }
    }
  }

  // MARK: - Computed Properties

  private var hasHeader: Bool {
    title != nil || description != nil || action != nil
  }

  private var horizontalInset: CGFloat {
    size == .sm ? theme.spacing.md : theme.spacing.lg
  }

  private var headerTopPadding: CGFloat {
    size == .sm ? theme.spacing.md : theme.spacing.lg
  }

  private var headerBottomGap: CGFloat {
    size == .sm ? CardTokens.headerBottomGapSm : CardTokens.headerBottomGapDefault
  }

  private var contentVerticalPadding: CGFloat {
    size == .sm ? theme.spacing.sm : (theme.spacing.sm + theme.spacing.xs)
  }

  private var footerBottomPadding: CGFloat {
    size == .sm ? theme.spacing.md : theme.spacing.lg
  }

  private var footerDividerInset: CGFloat {
    size == .sm ? (theme.spacing.sm + theme.spacing.xs) : theme.spacing.md
  }

  private var contentTopPadding: CGFloat {
    hasHeader ? 0 : headerTopPadding
  }

  private var contentBottomPadding: CGFloat {
    footer != nil ? contentVerticalPadding : footerBottomPadding
  }

  private var titleFont: Font {
    size == .sm ? .subheadline.weight(.semibold) : .headline.weight(.semibold)
  }

  private var descriptionFont: Font {
    size == .sm ? .caption : .subheadline
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.radius.lg)
  }

  @ViewBuilder
  private var backgroundView: some View {
    switch variant {
    case .elevated:
      if colorScheme == .dark {
        theme.card
          .overlay(Color.white.opacity(CardTokens.darkElevationOverlayOpacity))
      } else {
        theme.card
      }
    case .outlined:
      theme.card
    case .filled:
      theme.muted
    }
  }

  private var hasBorder: Bool {
    switch variant {
    case .elevated, .outlined:
      true
    case .filled:
      false
    }
  }

  private var shadowColor: Color {
    switch variant {
    case .elevated:
      if colorScheme == .dark {
        .black.opacity(CardTokens.darkShadowOpacity)
      } else {
        .black.opacity(theme.shadows.md.opacity)
      }
    case .outlined, .filled:
      .clear
    }
  }

  private var shadowRadius: CGFloat {
    switch variant {
    case .elevated:
      colorScheme == .dark ? theme.shadows.lg.radius : theme.shadows.md.radius
    case .outlined, .filled:
      0
    }
  }

  private var shadowY: CGFloat {
    switch variant {
    case .elevated:
      colorScheme == .dark ? theme.shadows.lg.y : theme.shadows.md.y
    case .outlined, .filled:
      0
    }
  }
}

// MARK: - CardTokens

private enum CardTokens {
  static let headerBottomGapSm: CGFloat = 6
  static let headerBottomGapDefault: CGFloat = 10
  static let darkElevationOverlayOpacity: Double = 0.06
  static let darkShadowOpacity: Double = 0.4
  static let footerDividerBackgroundOpacity: Double = 0.5
}

// MARK: - Previews

#Preview("CNCard Variants") {
  VStack(spacing: 20) {
    CNCard(variant: .elevated) {
      Text("Elevated Card")
    }

    CNCard(variant: .outlined) {
      Text("Outlined Card")
    }

    CNCard(variant: .filled) {
      Text("Filled Card")
    }
  }
  .padding()
}

#Preview("CNCard Slots") {
  VStack(spacing: 20) {
    CNCard(
      title: "Project Alpha",
      description: "Deployment status and active services.",
      variant: .elevated,
      action: {
        Button("Action") {}
      },
      footer: {
        Text("Footer info")
      }
    ) {
      Text("Main content goes here.")
    }

    CNCard(
      title: "Scheduled Reports",
      description: "Weekly snapshots delivered to your inbox.",
      variant: .outlined,
      size: .sm,
      hasFooterDivider: true,
      footer: {
        Button("Configure") {}
      }
    ) {
      Text("Compact card with divider footer.")
    }
  }
  .padding()
}
