import CoreGraphics

/// Reusable corner radius values for cards and media surfaces.
public struct HomeCornerRadius: Sendable, Equatable {
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat

    public init(small: CGFloat, medium: CGFloat, large: CGFloat) {
        self.small = small
        self.medium = medium
        self.large = large
    }

    public static let `default` = HomeCornerRadius(
        small: 12,
        medium: 14,
        large: 16
    )
}
