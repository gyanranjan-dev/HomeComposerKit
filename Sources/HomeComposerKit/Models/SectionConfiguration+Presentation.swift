import Foundation

extension SectionConfiguration {

    /// Default layout for a section type when configuration omits `layout`
    /// or supplies an unknown value.
    public static func defaultLayout(for sectionType: HomeSectionType) -> HomeSectionLayout {
        switch sectionType {
        case .banner:
            return .carousel
        case .categories, .products, .popularProducts, .favoriteProducts,
             .recentlyViewed, .recommendations, .brand, .promotion,
             .liveStream, .social, .custom:
            return .horizontal
        case .unknown:
            return .horizontal
        }
    }

    /// Resolved layout for rendering, falling back to section-type defaults.
    public func effectiveLayout(for sectionType: HomeSectionType) -> HomeSectionLayout {
        guard let layout else {
            return Self.defaultLayout(for: sectionType)
        }
        if case .unknown = layout {
            return Self.defaultLayout(for: sectionType)
        }
        return layout
    }

    /// Whether the section header title should be shown.
    ///
    /// When `showTitle` is omitted, the title is shown only when non-empty.
    public func effectiveShowTitle(hasTitle: Bool) -> Bool {
        switch showTitle {
        case nil, true?:
            return hasTitle
        case false?:
            return false
        }
    }

    /// Whether the section header should include a See All action.
    public var effectiveShowSeeAll: Bool {
        showSeeAll ?? false
    }

    /// Resolved inter-item spacing with a safe default.
    public var effectiveSpacing: Double {
        spacing ?? 12
    }

    /// Resolved column count for grid layouts, clamped to at least 1.
    public func effectiveColumns(default defaultValue: Int = 2) -> Int {
        max(columns ?? defaultValue, 1)
    }
}
