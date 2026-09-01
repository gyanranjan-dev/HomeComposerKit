import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

final class HomePersonalizationContextTests: XCTestCase {

    private let composer = HomeComposer()

    private func sampleProducts(ids: [String]) -> [Product] {
        ids.enumerated().map { index, id in
            Product(
                id: id,
                name: "Product \(index)",
                price: Decimal(index + 1),
                currency: "USD"
            )
        }
    }

    private func productSection(
        id: String = "products-1",
        products: [Product]
    ) -> ComposedHomeSection {
        ComposedHomeSection(
            id: id,
            type: .products,
            title: "For You",
            order: 0,
            content: .products(ProductSection(products: products))
        )
    }

    // MARK: - Context value type

    func testEmptyDefaultPersonalizationContext() {
        let context = HomePersonalizationContext.empty

        XCTAssertNil(context.customerReference)
        XCTAssertTrue(context.preferredCategoryIDs.isEmpty)
        XCTAssertTrue(context.favoriteProductIDs.isEmpty)
        XCTAssertTrue(context.recentlyViewedProductIDs.isEmpty)
        XCTAssertTrue(context.recommendationIDs.isEmpty)
        XCTAssertNil(context.localeIdentifier)
        XCTAssertNil(context.regionIdentifier)
        XCTAssertTrue(context.experimentIdentifiers.isEmpty)
        XCTAssertTrue(context.personalizedProductIDs.isEmpty)
    }

    func testPersonalizationContextIsHashable() {
        let lhs = HomePersonalizationContext(
            customerReference: "customer-42",
            preferredCategoryIDs: ["c1"],
            favoriteProductIDs: ["p1"],
            recentlyViewedProductIDs: ["p2"],
            recommendationIDs: ["p3"],
            localeIdentifier: "en_US",
            regionIdentifier: "US",
            experimentIdentifiers: ["exp": "variant-a"]
        )
        let rhs = lhs

        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(lhs.hashValue, rhs.hashValue)
        XCTAssertEqual(Set([lhs, rhs]).count, 1)
    }

    func testPersonalizationContextIsSendable() {
        let context = HomePersonalizationContext(customerReference: "customer-42")
        acceptSendable(context)
    }

    private func acceptSendable<T: Sendable>(_ value: T) {
        XCTAssertEqual(String(describing: value).isEmpty, false)
    }

    func testPreferredCategoryIDsPreserved() {
        let context = HomePersonalizationContext(preferredCategoryIDs: ["cat-1", "cat-2"])
        XCTAssertEqual(context.preferredCategoryIDs, ["cat-1", "cat-2"])
    }

    func testFavoriteProductIDsPreserved() {
        let context = HomePersonalizationContext(favoriteProductIDs: ["p1", "p4", "p8"])
        XCTAssertEqual(context.favoriteProductIDs, ["p1", "p4", "p8"])
    }

    func testRecentlyViewedProductIDsPreserved() {
        let context = HomePersonalizationContext(recentlyViewedProductIDs: ["p8", "p2"])
        XCTAssertEqual(context.recentlyViewedProductIDs, ["p8", "p2"])
    }

    func testRecommendationIDsPreserved() {
        let context = HomePersonalizationContext(recommendationIDs: ["p4", "p9", "p3"])
        XCTAssertEqual(context.recommendationIDs, ["p4", "p9", "p3"])
    }

    func testLocaleAndRegionPreserved() {
        let context = HomePersonalizationContext(
            localeIdentifier: "en_US",
            regionIdentifier: "US"
        )
        XCTAssertEqual(context.localeIdentifier, "en_US")
        XCTAssertEqual(context.regionIdentifier, "US")
    }

    func testExperimentIdentifiersPreserved() {
        let context = HomePersonalizationContext(
            experimentIdentifiers: ["home-layout": "grid", "ranking": "v2"]
        )
        XCTAssertEqual(context.experimentIdentifiers["home-layout"], "grid")
        XCTAssertEqual(context.experimentIdentifiers["ranking"], "v2")
    }

    func testPersonalizedProductIDsUnionIsDeterministic() {
        let context = HomePersonalizationContext(
            favoriteProductIDs: ["p1", "p4"],
            recentlyViewedProductIDs: ["p4", "p8"],
            recommendationIDs: ["p9", "p1"]
        )

        XCTAssertEqual(context.personalizedProductIDs, ["p9", "p1", "p4", "p8"])
    }

    // MARK: - SwiftUI environment

    func testPersonalizationEnvironmentDefaultIsEmpty() {
        let environment = EnvironmentValues()
        XCTAssertEqual(environment.homePersonalizationContext, .empty)
    }

    func testPersonalizationEnvironmentCanBeOverridden() {
        let personalization = HomePersonalizationContext(
            customerReference: "customer-42",
            favoriteProductIDs: ["p1", "p4"]
        )

        var environment = EnvironmentValues()
        environment.homePersonalizationContext = personalization

        XCTAssertEqual(environment.homePersonalizationContext.customerReference, "customer-42")
        XCTAssertEqual(environment.homePersonalizationContext.favoriteProductIDs, ["p1", "p4"])
    }

    // MARK: - HomePersonalizationTransformer

    func testProductFilteringByPersonalizationIDs() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let section = productSection(products: sampleProducts(ids: ["p1", "p2", "p3", "p4"]))
        let personalization = HomePersonalizationContext(
            favoriteProductIDs: ["p1", "p4"],
            recentlyViewedProductIDs: ["p8"]
        )

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }

        XCTAssertEqual(payload.products.map(\.id), ["p1", "p4"])
    }

    func testDeterministicRecommendationOrdering() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .reorderByRecommendations)
        ])
        let section = productSection(products: sampleProducts(ids: ["p1", "p2", "p3", "p4"]))
        let personalization = HomePersonalizationContext(recommendationIDs: ["p4", "p9", "p3"])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }

        XCTAssertEqual(payload.products.map(\.id), ["p4", "p3", "p1", "p2"])
    }

    func testNoMatchingIDsProducesSafeBehaviorForFilter() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let section = productSection(products: sampleProducts(ids: ["p1", "p2"]))
        let personalization = HomePersonalizationContext(favoriteProductIDs: ["p9"])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }

        XCTAssertTrue(payload.products.isEmpty)
    }

    func testHideWhenNoMatchesHidesSection() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .hideWhenNoMatches)
        ])
        let section = productSection(products: sampleProducts(ids: ["p1", "p2"]))
        let personalization = HomePersonalizationContext(recommendationIDs: ["p9"])

        XCTAssertNil(pipeline.apply(to: section, personalization: personalization))
    }

    func testOriginalSectionRemainsImmutableAfterPersonalization() {
        let original = productSection(products: sampleProducts(ids: ["p1", "p2", "p3"]))
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let personalization = HomePersonalizationContext(favoriteProductIDs: ["p1"])

        _ = pipeline.apply(to: original, personalization: personalization)

        guard case .products(let payload) = original.content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p1", "p2", "p3"])
    }

    func testNoPersonalizationBehaviorRemainsUnchanged() {
        let section = productSection(products: sampleProducts(ids: ["p1", "p2", "p3"]))
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])

        XCTAssertEqual(pipeline.apply(to: section), section)
        XCTAssertEqual(pipeline.apply(to: section, personalization: .empty), section)
    }

    // MARK: - Composition integration

    func testHomeComposerPassesPersonalizationToPipeline() {
        let homePage = HomePage(
            id: "home-personalized",
            version: "1.0",
            sections: [
                HomeSection(id: "products-1", type: .products, title: "For You", order: 0)
            ]
        )
        let content: [String: HomeSectionContent] = [
            "products-1": .products(ProductSection(products: sampleProducts(ids: ["p1", "p2", "p3", "p4"])))
        ]
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let personalization = HomePersonalizationContext(favoriteProductIDs: ["p2", "p4"])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline,
            personalization: personalization
        )

        XCTAssertEqual(composed.count, 1)
        guard case .products(let payload) = composed[0].content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p2", "p4"])
    }

    func testRenderContextComposePassesPersonalization() {
        let homePage = HomePage(
            id: "home-personalized",
            version: "1.0",
            sections: [
                HomeSection(id: "products-1", type: .products, title: "For You", order: 0)
            ]
        )
        let content: [String: HomeSectionContent] = [
            "products-1": .products(ProductSection(products: sampleProducts(ids: ["p1", "p2"])))
        ]
        let context = HomeRenderContext(homePage: homePage, contentBySectionID: content)
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .hideWhenNoMatches)
        ])
        let personalization = HomePersonalizationContext(recommendationIDs: ["p1"])

        let composed = context.compose(
            transformationPipeline: pipeline,
            personalization: personalization
        )

        XCTAssertEqual(composed.count, 1)
        guard case .products(let payload) = composed[0].content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p1"])
    }

    func testTransformationContextCarriesRenderAndPersonalizationSignals() {
        let renderContext = HomeRenderContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        let personalization = HomePersonalizationContext(customerReference: "customer-42")
        let transformationContext = HomeSectionTransformationContext(
            renderContext: renderContext,
            personalization: personalization
        )

        XCTAssertEqual(transformationContext.renderContext?.homePage.id, MockHomePage.sample.id)
        XCTAssertEqual(transformationContext.personalization.customerReference, "customer-42")
    }
}
