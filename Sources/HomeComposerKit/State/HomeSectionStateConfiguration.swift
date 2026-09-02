import Foundation

/// Appearance options for section loading skeletons.
public struct HomeSectionLoadingConfiguration: Sendable, Hashable, Equatable {

    /// Skeleton layout style.
    public enum Style: Sendable, Hashable, Equatable {
        case banner
        case horizontal(itemCount: Int)
        case grid(columns: Int, itemCount: Int)
        case productCard
    }

    public var style: Style

    public init(style: Style = .horizontal(itemCount: 4)) {
        self.style = style
    }
}

/// Appearance options for section empty states.
public struct HomeSectionEmptyConfiguration: Sendable, Hashable, Equatable {

    public var title: String
    public var message: String?
    public var actionTitle: String?
    public var action: HomeAction?

    public init(
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: HomeAction? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}

/// Appearance options for section error states.
public struct HomeSectionErrorConfiguration: Sendable, Hashable, Equatable {

    public var title: String
    public var message: String?
    public var retryTitle: String?
    public var retryAction: HomeAction?

    public init(
        title: String,
        message: String? = nil,
        retryTitle: String? = "Retry",
        retryAction: HomeAction? = nil
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
}

/// Customizable loading, empty, and error presentation for sections.
///
/// Retry actions invoke the existing ``HomeAction`` system. HomeComposerKit
/// does not perform networking or automatic retries.
public struct HomeSectionStateConfiguration: Sendable, Hashable, Equatable {

    public var loading: HomeSectionLoadingConfiguration
    public var empty: HomeSectionEmptyConfiguration
    public var error: HomeSectionErrorConfiguration

    public init(
        loading: HomeSectionLoadingConfiguration = HomeSectionLoadingConfiguration(),
        empty: HomeSectionEmptyConfiguration = HomeSectionEmptyConfiguration(
            title: "Nothing here yet"
        ),
        error: HomeSectionErrorConfiguration = HomeSectionErrorConfiguration(
            title: "Something went wrong"
        )
    ) {
        self.loading = loading
        self.empty = empty
        self.error = error
    }

    /// Default configuration used when hosts do not customize section state.
    public static let `default` = HomeSectionStateConfiguration()

    /// Returns a loading configuration suited to the given section type.
    public func loadingConfiguration(for sectionType: HomeSectionType) -> HomeSectionLoadingConfiguration {
        switch sectionType {
        case .banner:
            return HomeSectionLoadingConfiguration(style: .banner)
        case .categories, .brand:
            return HomeSectionLoadingConfiguration(style: .horizontal(itemCount: 4))
        case .products, .popularProducts, .favoriteProducts,
             .recentlyViewed, .recommendations:
            return HomeSectionLoadingConfiguration(style: .grid(columns: 2, itemCount: 4))
        case .promotion:
            return HomeSectionLoadingConfiguration(style: .horizontal(itemCount: 2))
        case .liveStream, .social:
            return HomeSectionLoadingConfiguration(style: .horizontal(itemCount: 3))
        case .custom, .unknown:
            return loading
        }
    }

    /// Returns an empty configuration suited to the given section type.
    public func emptyConfiguration(for sectionType: HomeSectionType) -> HomeSectionEmptyConfiguration {
        var configuration = empty
        switch sectionType {
        case .banner:
            configuration.title = "No banners"
        case .categories:
            configuration.title = "No categories"
        case .products, .popularProducts, .favoriteProducts,
             .recentlyViewed, .recommendations:
            configuration.title = "No products"
        case .brand:
            configuration.title = "No brands"
        case .promotion:
            configuration.title = "No promotions"
        case .liveStream:
            configuration.title = "No live streams"
        case .social:
            configuration.title = "No posts"
        case .custom, .unknown:
            break
        }
        return configuration
    }

    /// Returns an error configuration with an optional section-scoped retry action.
    public func errorConfiguration(forSectionID sectionID: String) -> HomeSectionErrorConfiguration {
        var configuration = error
        if configuration.retryAction == nil {
            configuration.retryAction = .custom(
                name: "retry",
                payload: ["sectionID": .string(sectionID)]
            )
        }
        return configuration
    }
}
