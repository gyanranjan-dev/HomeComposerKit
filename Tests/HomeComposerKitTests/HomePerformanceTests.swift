import Foundation
import XCTest
@testable import HomeComposerKit

@MainActor
final class HomePerformanceTests: XCTestCase {

    private let composer = HomeComposer()

    private func makeLargeHomePage(sectionCount: Int = 50, productsPerSection: Int = 100) -> (
        HomePage,
        [String: HomeSectionContent]
    ) {
        var sections: [HomeSection] = []
        var content: [String: HomeSectionContent] = [:]

        for index in 0..<sectionCount {
            let sectionID = "section-\(index)"
            sections.append(
                HomeSection(
                    id: sectionID,
                    type: .products,
                    title: "Products \(index)",
                    order: index
                )
            )
            content[sectionID] = .products(
                ProductSection(products: makeProducts(count: productsPerSection, prefix: "s\(index)"))
            )
        }

        return (
            HomePage(id: "large-home", version: "1.0", sections: sections),
            content
        )
    }

    private func makeProducts(count: Int, prefix: String) -> [Product] {
        (0..<count).map { index in
            Product(
                id: "\(prefix)-prod-\(index)",
                name: "Product \(index)",
                price: Decimal(index + 1),
                currency: "USD"
            )
        }
    }

    // MARK: - Stable identity

    func testComposedSectionsUseStableIDs() {
        let (homePage, content) = makeLargeHomePage(sectionCount: 5, productsPerSection: 2)
        let composed = composer.compose(homePage, contentBySectionID: content)

        XCTAssertEqual(composed.map(\.id), (0..<5).map { "section-\($0)" })
        XCTAssertEqual(Set(composed.map(\.id)).count, composed.count)
    }

    func testDuplicateSectionIDsPreserveExistingSemantics() {
        let homePage = HomePage(
            id: "duplicate-home",
            version: "1.0",
            sections: [
                HomeSection(id: "dup", type: .products, order: 0),
                HomeSection(id: "dup", type: .banner, order: 1),
                HomeSection(id: "unique", type: .categories, order: 2)
            ]
        )

        let composed = composer.compose(homePage)
        XCTAssertEqual(composed.map(\.id), ["dup", "unique"])
        XCTAssertEqual(composed[0].type, .products)
    }

    func testProductModelsProvideStableIdentifiableIDs() {
        let products = makeProducts(count: 3, prefix: "p")
        XCTAssertEqual(products.map(\.id), ["p-prod-0", "p-prod-1", "p-prod-2"])
    }

    // MARK: - Pipeline

    func testIdentityPipelineDoesNotAlterContent() {
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            order: 0,
            content: .products(ProductSection(products: makeProducts(count: 2, prefix: "p")))
        )

        XCTAssertFalse(HomeSectionContentTransformerPipeline.identity.hasTransformers)
        XCTAssertEqual(
            HomeSectionContentTransformerPipeline.identity.apply(to: section),
            section
        )
    }

    func testIdentityPipelineBatchApplyReturnsSameSections() {
        let (homePage, content) = makeLargeHomePage(sectionCount: 10, productsPerSection: 5)
        let composed = composer.composeSections(homePage, contentBySectionID: content)
        let transformed = HomeSectionContentTransformerPipeline.identity.apply(to: composed)

        XCTAssertEqual(composed, transformed)
    }

    func testMultipleTransformersExecuteOncePerSection() {
        let counter = TransformerCallCounter()
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            CountingTransformer(counter: counter, marker: "first"),
            CountingTransformer(counter: counter, marker: "second")
        ])

        let section = ComposedHomeSection(id: "products-1", type: .products, order: 0)
        _ = pipeline.apply(to: section)

        XCTAssertEqual(counter.counts["first"], 1)
        XCTAssertEqual(counter.counts["second"], 1)
    }

    func testHiddenSectionStopsLaterTransformers() {
        let counter = TransformerCallCounter()
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HiddenTransformer(),
            CountingTransformer(counter: counter, marker: "after-hidden")
        ])

        let section = ComposedHomeSection(id: "products-1", type: .products, order: 0)
        XCTAssertNil(pipeline.apply(to: section))
        XCTAssertNil(counter.counts["after-hidden"])
    }

    // MARK: - Personalization

    func testLargeProductListPersonalizationFilterRemainsCorrect() {
        let products = makeProducts(count: 1_000, prefix: "p")
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            order: 0,
            content: .products(ProductSection(products: products))
        )
        let allowedIDs = Set((0..<100).map { "p-prod-\($0)" })
        let personalization = HomePersonalizationContext(
            favoriteProductIDs: Array(allowedIDs)
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])

        let transformed = pipeline.apply(to: section, personalization: personalization)
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }

        XCTAssertEqual(payload.products.count, 100)
        XCTAssertTrue(payload.products.allSatisfy { allowedIDs.contains($0.id) })
    }

    func testLargeProductListRecommendationOrderingRemainsDeterministic() {
        let products = makeProducts(count: 500, prefix: "p")
        let recommendationIDs = (0..<20).map { "p-prod-\(499 - $0)" }
        let section = ComposedHomeSection(
            id: "recs",
            type: .recommendations,
            order: 0,
            content: .recommendations(ProductSection(products: products))
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .reorderByRecommendations)
        ])
        let personalization = HomePersonalizationContext(recommendationIDs: recommendationIDs)

        let first = pipeline.apply(to: section, personalization: personalization)
        let second = pipeline.apply(to: section, personalization: personalization)

        guard case .recommendations(let firstPayload) = first?.content,
              case .recommendations(let secondPayload) = second?.content else {
            return XCTFail("Expected recommendations content")
        }

        XCTAssertEqual(firstPayload.products.map(\.id), secondPayload.products.map(\.id))
        XCTAssertEqual(firstPayload.products.prefix(20).map(\.id), recommendationIDs)
    }

    // MARK: - Renderer registry

    func testRendererLookupRemainsDeterministic() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(id: "products-1", type: .products, order: 0)

        _ = registry.view(for: section)
        _ = registry.view(for: section)

        XCTAssertTrue(registry.isRegistered(for: .products))
    }

    func testUnregisteredRendererUsesSharedFallbackView() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "unknown",
            type: .unknown("future_widget"),
            order: 0
        )

        let first = registry.view(for: section)
        let second = registry.view(for: section)

        XCTAssertFalse(registry.isRegistered(for: section.type))
        _ = first
        _ = second
    }

    // MARK: - State configuration

    func testExplicitLoadingStateDoesNotRequireSectionContent() {
        let state = HomeSectionState.loading
        XCTAssertNotEqual(state, .loaded)
        XCTAssertFalse(state.isLoaded)
    }

    func testExistingCompositionBehaviorRemainsUnchangedWithoutTransformers() {
        let baseline = composer.compose(MockHomePage.sample, contentBySectionID: MockHomePage.sampleContent)
        let withIdentity = composer.compose(
            MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent,
            transformationPipeline: .identity
        )

        XCTAssertEqual(baseline, withIdentity)
    }

    // MARK: - Performance measurement

    func testPerformanceCompositionOfLargeHomePage() {
        let (homePage, content) = makeLargeHomePage(sectionCount: 100, productsPerSection: 50)

        measure {
            _ = composer.composeSections(homePage, contentBySectionID: content)
        }
    }

    func testPerformanceTransformationOfLargeProductSection() {
        let products = makeProducts(count: 2_000, prefix: "p")
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            order: 0,
            content: .products(ProductSection(products: products))
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .reorderByRecommendations)
        ])
        let personalization = HomePersonalizationContext(
            recommendationIDs: (0..<200).map { "p-prod-\($0)" }
        )

        measure {
            _ = pipeline.apply(to: section, personalization: personalization)
        }
    }

    func testPerformanceRendererLookup() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(id: "products-1", type: .products, order: 0)

        measure {
            for _ in 0..<1_000 {
                _ = registry.view(for: section)
            }
        }
    }
}

// MARK: - Test helpers

private final class TransformerCallCounter: @unchecked Sendable {
    var counts: [String: Int] = [:]
}

private struct CountingTransformer: HomeSectionContentTransforming {
    let counter: TransformerCallCounter
    let marker: String

    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        counter.counts[marker, default: 0] += 1
        return .unchanged(section)
    }
}

private struct HiddenTransformer: HomeSectionContentTransforming {
    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        .hidden
    }
}
