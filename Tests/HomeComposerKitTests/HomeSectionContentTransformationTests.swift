import Foundation
import XCTest
@testable import HomeComposerKit

// MARK: - Test transformers

private struct HideEmptyProductsTransformer: HomeSectionContentTransforming {
    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        guard section.type == .products else {
            return .unchanged(section)
        }

        guard case .products(let payload) = section.content else {
            return .hidden
        }

        if payload.products.isEmpty {
            return .hidden
        }

        return .unchanged(section)
    }
}

private struct LimitProductsTransformer: HomeSectionContentTransforming {
    let limit: Int

    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        guard case .products(let payload) = section.content else {
            return .unchanged(section)
        }

        let limited = Array(payload.products.prefix(limit))
        return .replace(
            section.replacing(
                content: .products(ProductSection(products: limited))
            )
        )
    }
}

private struct RecommendationLabelTransformer: HomeSectionContentTransforming {
    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        guard section.type == .products else {
            return .unchanged(section)
        }

        let title = section.title.map { "\($0) • Recommended" } ?? "Recommended"
        return .replace(section.replacing(title: title))
    }
}

private struct HiddenMarkerTransformer: HomeSectionContentTransforming {
    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        .hidden
    }
}

private struct ReplaceIDTransformer: HomeSectionContentTransforming {
    let replacementID: String

    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        .replace(
            ComposedHomeSection(
                id: replacementID,
                type: section.type,
                title: section.title,
                order: section.order,
                configuration: section.configuration,
                content: section.content
            )
        )
    }
}

private final class IDRecorder: @unchecked Sendable {
    var ids: [String] = []
}

private struct ObserveIDTransformer: HomeSectionContentTransforming {
    let recorder: IDRecorder

    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation {
        recorder.ids.append(section.id)
        return .unchanged(section)
    }
}

final class HomeSectionContentTransformationTests: XCTestCase {

    private let composer = HomeComposer()

    private func productSection(
        id: String,
        title: String,
        products: [Product]
    ) -> (HomePage, [String: HomeSectionContent]) {
        let homePage = HomePage(
            id: "home-transform",
            version: "1.0",
            sections: [
                HomeSection(
                    id: id,
                    type: .products,
                    title: title,
                    order: 0
                )
            ]
        )
        let content = [id: HomeSectionContent.products(ProductSection(products: products))]
        return (homePage, content)
    }

    private func sampleProducts(count: Int) -> [Product] {
        (0..<count).map { index in
            Product(
                id: "prod-\(index)",
                name: "Product \(index)",
                price: Decimal(index + 1),
                currency: "USD"
            )
        }
    }

    // MARK: - Pipeline basics

    func testNoTransformersLeavesSectionUnchanged() {
        let pipeline = HomeSectionContentTransformerPipeline.identity
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0
        )

        XCTAssertEqual(pipeline.apply(to: section), section)
    }

    func testOneTransformerReplacesSection() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            LimitProductsTransformer(limit: 2)
        ])
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0,
            content: .products(ProductSection(products: sampleProducts(count: 5)))
        )

        let transformed = pipeline.apply(to: section)
        XCTAssertNotNil(transformed)
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.count, 2)
    }

    func testTransformerCanHideSection() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HideEmptyProductsTransformer()
        ])
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0,
            content: .products(ProductSection(products: []))
        )

        XCTAssertNil(pipeline.apply(to: section))
    }

    func testReplacementReachesNextTransformer() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            LimitProductsTransformer(limit: 3),
            RecommendationLabelTransformer()
        ])

        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0,
            content: .products(ProductSection(products: sampleProducts(count: 10)))
        )

        let transformed = pipeline.apply(to: section)
        XCTAssertNotNil(transformed)
        XCTAssertEqual(transformed?.title, "Trending • Recommended")
        guard case .products(let payload) = transformed?.content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.count, 3)
    }

    func testHiddenStopsLaterTransformers() {
        let recorder = IDRecorder()
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HideEmptyProductsTransformer(),
            ObserveIDTransformer(recorder: recorder)
        ])

        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            order: 0,
            content: .products(ProductSection(products: []))
        )

        XCTAssertNil(pipeline.apply(to: section))
        XCTAssertTrue(recorder.ids.isEmpty)
    }

    func testMultipleTransformersExecuteDeterministically() {
        let recorder = IDRecorder()
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            ReplaceIDTransformer(replacementID: "products-replaced"),
            ObserveIDTransformer(recorder: recorder)
        ])

        let section = ComposedHomeSection(id: "products-1", type: .products, order: 0)
        _ = pipeline.apply(to: section)

        XCTAssertEqual(recorder.ids, ["products-replaced"])
    }

    // MARK: - Example use cases

    func testEmptyProductSectionCanBeHidden() {
        let (homePage, content) = productSection(
            id: "products-empty",
            title: "Trending",
            products: []
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HideEmptyProductsTransformer()
        ])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline
        )

        XCTAssertTrue(composed.isEmpty)
    }

    func testProductLimitTransformationWorks() {
        let (homePage, content) = productSection(
            id: "products-limit",
            title: "Trending",
            products: sampleProducts(count: 20)
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            LimitProductsTransformer(limit: 8)
        ])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline
        )

        XCTAssertEqual(composed.count, 1)
        guard case .products(let payload) = composed[0].content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.count, 8)
    }

    func testRecommendationLabelTransformationWorks() {
        let (homePage, content) = productSection(
            id: "products-label",
            title: "For You",
            products: sampleProducts(count: 2)
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            RecommendationLabelTransformer()
        ])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline
        )

        XCTAssertEqual(composed.first?.title, "For You • Recommended")
    }

    func testOriginalSectionRemainsUnchanged() {
        let original = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0,
            content: .products(ProductSection(products: sampleProducts(count: 5)))
        )

        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            LimitProductsTransformer(limit: 2)
        ])
        _ = pipeline.apply(to: original)

        guard case .products(let payload) = original.content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.count, 5)
    }

    // MARK: - Legacy behavior

    func testExistingHomeComposerBehaviorRemainsUnchangedWithoutPipeline() {
        let composed = composer.compose(MockHomePage.sample, contentBySectionID: MockHomePage.sampleContent)
        let composedSections = composer.composeSections(
            MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(composed.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(composedSections.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(composed.map(\.id), composedSections.map(\.id))
    }

    func testOptionalPipelineDoesNotAffectLegacyCallers() {
        let baseline = composer.compose(MockHomePage.sample, contentBySectionID: MockHomePage.sampleContent)
        let withIdentity = composer.compose(
            MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent,
            transformationPipeline: .identity
        )

        XCTAssertEqual(baseline, withIdentity)
    }

    func testEmptyPipelineIsSafe() {
        let section = ComposedHomeSection(id: "section-1", type: .banner, order: 0)
        XCTAssertEqual(
            HomeSectionContentTransformerPipeline().apply(to: section),
            section
        )
    }

    func testHiddenTransformerInPipelineIsSafe() {
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HiddenMarkerTransformer()
        ])
        let section = ComposedHomeSection(id: "section-1", type: .banner, order: 0)
        XCTAssertNil(pipeline.apply(to: section))
    }

    func testRenderContextComposeAppliesPipeline() {
        let context = HomeRenderContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        let baseline = context.compose()
        let withIdentity = context.compose(transformationPipeline: .identity)

        XCTAssertEqual(baseline, withIdentity)
    }
}
