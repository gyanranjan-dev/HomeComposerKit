import SwiftUI

/// A themed skeleton rectangle placeholder.
public struct SkeletonRectangle: View {

    @Environment(\.homeComposerTheme) private var theme

    private let width: CGFloat?
    private let height: CGFloat
    private let cornerRadius: CGFloat

    public init(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat? = nil
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius ?? 8
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(theme.placeholderBackgroundColor)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

/// A themed skeleton text line placeholder.
public struct SkeletonTextLine: View {

    @Environment(\.homeComposerTheme) private var theme

    private let width: CGFloat?
    private let height: CGFloat

    public init(width: CGFloat? = 120, height: CGFloat = 12) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(theme.placeholderBackgroundColor)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

/// Skeleton placeholder resembling a product card.
public struct ProductCardSkeleton: View {

    @Environment(\.homeComposerTheme) private var theme

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.cardSpacing) {
            SkeletonRectangle(height: 120, cornerRadius: theme.cornerRadius.medium)
            SkeletonTextLine(width: 100, height: 14)
            SkeletonTextLine(width: 60, height: 12)
        }
        .padding(theme.cardPadding)
        .background(theme.cardBackgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.medium,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }
}

/// Horizontal section skeleton with optional title line.
public struct HorizontalSectionSkeleton: View {

    @Environment(\.homeComposerTheme) private var theme

    private let itemCount: Int
    private let itemWidth: CGFloat
    private let itemHeight: CGFloat
    private let showsTitle: Bool

    public init(
        itemCount: Int = 4,
        itemWidth: CGFloat = 120,
        itemHeight: CGFloat = 120,
        showsTitle: Bool = true
    ) {
        self.itemCount = itemCount
        self.itemWidth = itemWidth
        self.itemHeight = itemHeight
        self.showsTitle = showsTitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            if showsTitle {
                SkeletonTextLine(width: 140, height: 16)
                    .padding(.horizontal, theme.horizontalContentPadding)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.medium) {
                    ForEach(0..<itemCount, id: \.self) { _ in
                        SkeletonRectangle(
                            width: itemWidth,
                            height: itemHeight,
                            cornerRadius: theme.cornerRadius.medium
                        )
                    }
                }
                .padding(.horizontal, theme.horizontalContentPadding)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

/// Grid section skeleton with optional title line.
public struct GridSectionSkeleton: View {

    @Environment(\.homeComposerTheme) private var theme

    private let columns: Int
    private let itemCount: Int
    private let showsTitle: Bool

    public init(
        columns: Int = 2,
        itemCount: Int = 4,
        showsTitle: Bool = true
    ) {
        self.columns = columns
        self.itemCount = itemCount
        self.showsTitle = showsTitle
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: theme.spacing.medium), count: columns)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            if showsTitle {
                SkeletonTextLine(width: 140, height: 16)
                    .padding(.horizontal, theme.horizontalContentPadding)
            }

            LazyVGrid(columns: gridColumns, spacing: theme.spacing.medium) {
                ForEach(0..<itemCount, id: \.self) { _ in
                    ProductCardSkeleton()
                }
            }
            .padding(.horizontal, theme.horizontalContentPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}

/// Banner-shaped section skeleton.
public struct BannerSectionSkeleton: View {

    @Environment(\.homeComposerTheme) private var theme

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            SkeletonTextLine(width: 140, height: 16)
                .padding(.horizontal, theme.horizontalContentPadding)

            SkeletonRectangle(height: 200, cornerRadius: theme.cornerRadius.large)
                .padding(.horizontal, theme.horizontalContentPadding)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading")
    }
}
