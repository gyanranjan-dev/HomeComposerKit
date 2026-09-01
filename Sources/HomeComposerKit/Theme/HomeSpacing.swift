import CoreGraphics

/// A compact spacing scale for HomeComposerKit layout values.
public struct HomeSpacing: Sendable, Equatable {
    public let compact: CGFloat
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let extraLarge: CGFloat

    public init(
        compact: CGFloat,
        small: CGFloat,
        medium: CGFloat,
        large: CGFloat,
        extraLarge: CGFloat
    ) {
        self.compact = compact
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
    }

    public static let `default` = HomeSpacing(
        compact: 4,
        small: 8,
        medium: 12,
        large: 16,
        extraLarge: 24
    )
}
