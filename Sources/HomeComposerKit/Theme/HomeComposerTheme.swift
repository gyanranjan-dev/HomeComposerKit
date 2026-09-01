import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Visual theme for HomeComposerKit built-in section renderers.
///
/// Host applications can supply a custom theme to adjust spacing, typography,
/// corner radii, and semantic colors without replacing section views.
public struct HomeComposerTheme: Sendable {
    public let backgroundColor: Color
    public let cardBackgroundColor: Color
    public let placeholderBackgroundColor: Color

    public let spacing: HomeSpacing
    public let cornerRadius: HomeCornerRadius
    public let typography: HomeTypography

    /// Vertical spacing between top-level page sections.
    public let sectionSpacing: CGFloat

    /// Horizontal inset applied to page and section content.
    public let horizontalContentPadding: CGFloat

    /// Spacing between elements inside cards and compact stacks.
    public let cardSpacing: CGFloat

    /// Inner padding applied to card surfaces.
    public let cardPadding: CGFloat

    /// Spacing between header title and subtitle.
    public let headerSpacing: CGFloat

    public init(
        backgroundColor: Color,
        cardBackgroundColor: Color,
        placeholderBackgroundColor: Color,
        spacing: HomeSpacing = .default,
        cornerRadius: HomeCornerRadius = .default,
        typography: HomeTypography = .default,
        sectionSpacing: CGFloat? = nil,
        horizontalContentPadding: CGFloat? = nil,
        cardSpacing: CGFloat? = nil,
        cardPadding: CGFloat? = nil,
        headerSpacing: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cardBackgroundColor = cardBackgroundColor
        self.placeholderBackgroundColor = placeholderBackgroundColor
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.typography = typography
        self.sectionSpacing = sectionSpacing ?? spacing.extraLarge
        self.horizontalContentPadding = horizontalContentPadding ?? spacing.large
        self.cardSpacing = cardSpacing ?? spacing.small
        self.cardPadding = cardPadding ?? 10
        self.headerSpacing = headerSpacing ?? 2
    }

    /// System-friendly defaults that adapt to light and dark mode.
    public static let `default` = HomeComposerTheme(
        backgroundColor: systemGroupedBackground,
        cardBackgroundColor: systemCardBackground,
        placeholderBackgroundColor: systemPlaceholderBackground
    )
}

private extension HomeComposerTheme {
    static var systemGroupedBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var systemCardBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.white
        #endif
    }

    static var systemPlaceholderBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color.gray.opacity(0.15)
        #endif
    }
}

private struct HomeComposerThemeKey: EnvironmentKey {
    static let defaultValue = HomeComposerTheme.default
}

extension EnvironmentValues {
    /// Theme applied to descendant HomeComposerKit views.
    public var homeComposerTheme: HomeComposerTheme {
        get { self[HomeComposerThemeKey.self] }
        set { self[HomeComposerThemeKey.self] = newValue }
    }
}

extension View {
    /// Installs a HomeComposerKit theme for descendant section views.
    public func homeComposerTheme(_ theme: HomeComposerTheme) -> some View {
        environment(\.homeComposerTheme, theme)
    }
}
