import Foundation

/// Payload associated with a composed home section.
///
/// Keeps section-specific models available to renderers without embedding
/// SwiftUI types in the model or composition layers.
public enum HomeSectionContent: Sendable, Equatable {
    case banner(BannerSection)
    case categories(CategorySection)
    case products(ProductSection)
    case favoriteProducts(ProductSection)
    case popularProducts(ProductSection)
    case recentlyViewed(ProductSection)
    case recommendations(ProductSection)
    case brand(BrandSection)
    case promotion(PromotionSection)
    case live(LiveSection)
    case social(SocialSection)
}
