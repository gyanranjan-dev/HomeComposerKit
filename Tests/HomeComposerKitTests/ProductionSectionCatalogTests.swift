import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class ProductionSectionCatalogTests: XCTestCase {

    private let composer = HomeComposer()

    private func sampleProduct(id: String, name: String) -> Product {
        Product(
            id: id,
            name: name,
            price: Decimal(10),
            currency: "USD"
        )
    }

    // MARK: - Section type decoding

    func testRecentlyViewedSectionTypeDecodesFromCamelCase() throws {
        let section = try decodeSection(type: "recentlyViewed")
        XCTAssertEqual(section.type, .recentlyViewed)
    }

    func testRecentlyViewedSectionTypeDecodesFromSnakeCase() throws {
        let section = try decodeSection(type: "recently_viewed")
        XCTAssertEqual(section.type, .recentlyViewed)
    }

    func testRecommendationsSectionTypeDecodes() throws {
        let section = try decodeSection(type: "recommendations")
        XCTAssertEqual(section.type, .recommendations)
    }

    func testBrandSectionTypeDecodes() throws {
        let section = try decodeSection(type: "brand")
        XCTAssertEqual(section.type, .brand)
    }

    func testPromotionSectionTypeDecodes() throws {
        let section = try decodeSection(type: "promotion")
        XCTAssertEqual(section.type, .promotion)
    }

    func testUnknownSectionTypeStillDecodesSafely() throws {
        let section = try decodeSection(type: "flash_sale_v3")
        XCTAssertEqual(section.type, .unknown("flash_sale_v3"))
    }

    // MARK: - Model decoding

    func testBrandSectionRoundTrip() throws {
        let section = BrandSection(brands: [
            Brand(id: "brand-1", name: "Acme", imageURL: URL(string: "https://example.com/acme.png"))
        ])
        let decoded = try JSONDecoder().decode(
            BrandSection.self,
            from: JSONEncoder().encode(section)
        )
        XCTAssertEqual(decoded.brands[0].id, "brand-1")
        XCTAssertEqual(decoded.brands[0].name, "Acme")
    }

    func testPromotionSectionRoundTrip() throws {
        let section = PromotionSection(promotions: [
            Promotion(
                id: "promo-1",
                title: "Free Shipping",
                subtitle: "On orders over $50",
                imageURL: URL(string: "https://example.com/promo.png"),
                action: PromotionAction(title: "Shop", destination: "https://example.com/shop"),
                expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        ])
        let decoded = try JSONDecoder().decode(
            PromotionSection.self,
            from: JSONEncoder().encode(section)
        )
        XCTAssertEqual(decoded.promotions[0].title, "Free Shipping")
        XCTAssertEqual(decoded.promotions[0].action?.destination, "https://example.com/shop")
    }

    // MARK: - Renderer registration

    func testBuiltInRenderersAreRegisteredForNewSectionTypes() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertTrue(registry.isRegistered(for: .recentlyViewed))
        XCTAssertTrue(registry.isRegistered(for: .recommendations))
        XCTAssertTrue(registry.isRegistered(for: .brand))
        XCTAssertTrue(registry.isRegistered(for: .promotion))
    }

    func testExistingBuiltInRenderersRemainRegistered() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .categories))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertTrue(registry.isRegistered(for: .popularProducts))
        XCTAssertTrue(registry.isRegistered(for: .favoriteProducts))
        XCTAssertTrue(registry.isRegistered(for: .liveStream))
        XCTAssertTrue(registry.isRegistered(for: .social))
    }

    func testCustomSectionTypeRemainsUnregisteredByDefault() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        XCTAssertFalse(registry.isRegistered(for: .custom))
    }

    // MARK: - Recently viewed

    func testRecentlyViewedSectionUsesProductContent() {
        let section = ComposedHomeSection(
            id: "recent",
            type: .recentlyViewed,
            title: "Recently Viewed",
            order: 0,
            configuration: SectionConfiguration(layout: .horizontal, limit: 2),
            content: .recentlyViewed(
                ProductSection(products: [
                    sampleProduct(id: "p1", name: "One"),
                    sampleProduct(id: "p2", name: "Two"),
                    sampleProduct(id: "p3", name: "Three")
                ])
            )
        )

        guard case .recentlyViewed(let payload) = section.content else {
            return XCTFail("Expected recently viewed content")
        }
        XCTAssertEqual(payload.products.count, 3)
        XCTAssertEqual(section.effectiveLayout, .horizontal)
    }

    // MARK: - Recommendations

    func testRecommendationSectionUsesProductContent() {
        let section = ComposedHomeSection(
            id: "recs",
            type: .recommendations,
            title: "Recommended",
            order: 0,
            content: .recommendations(
                ProductSection(products: [sampleProduct(id: "p9", name: "Nine")])
            )
        )

        guard case .recommendations(let payload) = section.content else {
            return XCTFail("Expected recommendations content")
        }
        XCTAssertEqual(payload.products.first?.id, "p9")
    }

    // MARK: - Brand

    func testBrandSectionPreservesIdentifiersAndImageSources() {
        let imageURL = URL(string: "https://example.com/brand.png")!
        let section = ComposedHomeSection(
            id: "brands",
            type: .brand,
            title: "Top Brands",
            order: 0,
            content: .brand(
                BrandSection(brands: [
                    Brand(id: "brand-1", name: "Acme", imageURL: imageURL)
                ])
            )
        )

        guard case .brand(let payload) = section.content else {
            return XCTFail("Expected brand content")
        }
        XCTAssertEqual(payload.brands[0].id, "brand-1")
        XCTAssertEqual(payload.brands[0].imageURL, imageURL)
    }

    func testBrandActionMappingUsesCustomAction() {
        let action = HomeAction.from(brand: Brand(id: "brand-1", name: "Acme"))
        guard case .custom(let name, let payload) = action else {
            return XCTFail("Expected custom action")
        }
        XCTAssertEqual(name, "brand")
        XCTAssertEqual(payload?["id"], .string("brand-1"))
    }

    // MARK: - Promotion

    func testPromotionSectionPreservesContentAndAction() {
        let section = ComposedHomeSection(
            id: "promos",
            type: .promotion,
            title: "Offers",
            order: 0,
            content: .promotion(
                PromotionSection(promotions: [
                    Promotion(
                        id: "promo-1",
                        title: "20% Off",
                        subtitle: "Limited time",
                        imageURL: URL(string: "https://example.com/promo.png"),
                        action: PromotionAction(title: "Claim", destination: "https://example.com/claim")
                    )
                ])
            )
        )

        guard case .promotion(let payload) = section.content else {
            return XCTFail("Expected promotion content")
        }
        XCTAssertEqual(payload.promotions[0].title, "20% Off")
        XCTAssertEqual(payload.promotions[0].action?.destination, "https://example.com/claim")
    }

    func testPromotionActionMappingUsesOpenURLForHTTPDestinations() {
        let action = HomeAction.from(
            promotion: Promotion(
                id: "promo-1",
                title: "Sale",
                action: PromotionAction(destination: "https://example.com/sale")
            )
        )
        guard case .openURL(let url) = action else {
            return XCTFail("Expected openURL action")
        }
        XCTAssertEqual(url, "https://example.com/sale")
    }

    // MARK: - Presentation configuration

    func testPresentationConfigurationIsPreservedForNewSections() {
        let configuration = SectionConfiguration(
            layout: .grid,
            limit: 4,
            columns: 2,
            spacing: 16,
            showTitle: true,
            showSeeAll: true
        )
        let section = ComposedHomeSection(
            id: "brand-grid",
            type: .brand,
            title: "Brands",
            order: 0,
            configuration: configuration,
            content: .brand(BrandSection(brands: []))
        )

        XCTAssertEqual(section.effectiveLayout, .grid)
        XCTAssertEqual(section.effectiveSpacing, 16)
        XCTAssertEqual(section.effectiveColumns(default: 2), 2)
        XCTAssertTrue(section.effectiveShowTitle)
        XCTAssertTrue(section.effectiveShowSeeAll)
    }

    // MARK: - Empty content

    func testEmptyRecentlyViewedContentIsSafe() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "recent-empty",
            type: .recentlyViewed,
            title: "Recently Viewed",
            order: 0,
            content: .recentlyViewed(ProductSection(products: []))
        )

        _ = registry.view(for: section)
    }

    func testEmptyBrandContentIsSafe() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "brand-empty",
            type: .brand,
            title: "Brands",
            order: 0,
            content: .brand(BrandSection(brands: []))
        )

        _ = registry.view(for: section)
    }

    func testEmptyPromotionContentIsSafe() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "promo-empty",
            type: .promotion,
            title: "Offers",
            order: 0,
            content: .promotion(PromotionSection(promotions: []))
        )

        _ = registry.view(for: section)
    }

    // MARK: - Personalization compatibility

    func testPersonalizationTransformerFiltersRecentlyViewedProducts() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let section = ComposedHomeSection(
            id: "recent",
            type: .recentlyViewed,
            order: 0,
            content: .recentlyViewed(
                ProductSection(products: [
                    sampleProduct(id: "p1", name: "One"),
                    sampleProduct(id: "p2", name: "Two")
                ])
            )
        )
        let personalization = HomePersonalizationContext(recentlyViewedProductIDs: ["p2"])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .recentlyViewed(let payload) = transformed?.content else {
            return XCTFail("Expected recently viewed content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p2"])
    }

    func testPersonalizationTransformerReordersRecommendationsSection() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .reorderByRecommendations)
        ])
        let section = ComposedHomeSection(
            id: "recs",
            type: .recommendations,
            order: 0,
            content: .recommendations(
                ProductSection(products: [
                    sampleProduct(id: "p1", name: "One"),
                    sampleProduct(id: "p2", name: "Two"),
                    sampleProduct(id: "p3", name: "Three")
                ])
            )
        )
        let personalization = HomePersonalizationContext(recommendationIDs: ["p3", "p1"])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .recommendations(let payload) = transformed?.content else {
            return XCTFail("Expected recommendations content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p3", "p1", "p2"])
    }

    func testPersonalizationPreservesRecommendationsContentCase() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let section = ComposedHomeSection(
            id: "recs",
            type: .recommendations,
            order: 0,
            content: .recommendations(
                ProductSection(products: [
                    sampleProduct(id: "p1", name: "One"),
                    sampleProduct(id: "p2", name: "Two")
                ])
            )
        )
        let personalization = HomePersonalizationContext(recommendationIDs: ["p2"])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .recommendations = transformed?.content else {
            return XCTFail("Expected recommendations content case to be preserved")
        }
    }

    func testCompositionIncludesNewProductionSections() {
        let homePage = HomePage(
            id: "catalog-home",
            version: "1.0",
            sections: [
                HomeSection(id: "recent", type: .recentlyViewed, title: "Recent", order: 0),
                HomeSection(id: "recs", type: .recommendations, title: "For You", order: 1),
                HomeSection(id: "brands", type: .brand, title: "Brands", order: 2),
                HomeSection(id: "promos", type: .promotion, title: "Offers", order: 3)
            ]
        )
        let content: [String: HomeSectionContent] = [
            "recent": .recentlyViewed(ProductSection(products: [sampleProduct(id: "p1", name: "One")])),
            "recs": .recommendations(ProductSection(products: [sampleProduct(id: "p2", name: "Two")])),
            "brands": .brand(BrandSection(brands: [Brand(id: "b1", name: "Acme")])),
            "promos": .promotion(PromotionSection(promotions: [Promotion(id: "promo-1", title: "Sale")]))
        ]

        let composed = composer.compose(homePage, contentBySectionID: content)
        XCTAssertEqual(composed.map(\.id), ["recent", "recs", "brands", "promos"])
    }

    // MARK: - Helpers

    private func decodeSection(type: String) throws -> HomeSection {
        let json = """
        {
            "id": "section-1",
            "type": "\(type)",
            "order": 0,
            "isEnabled": true
        }
        """.data(using: .utf8)!
        return try JSONDecoder().decode(HomeSection.self, from: json)
    }
}
