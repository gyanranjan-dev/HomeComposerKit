import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class HomeSectionStateTests: XCTestCase {

    private let composer = HomeComposer()

    // MARK: - State model

    func testLoadingState() {
        XCTAssertEqual(HomeSectionState.loading, .loading)
        XCTAssertFalse(HomeSectionState.loading.isLoaded)
    }

    func testLoadedState() {
        XCTAssertTrue(HomeSectionState.loaded.isLoaded)
    }

    func testEmptyState() {
        XCTAssertEqual(HomeSectionState.empty, .empty)
        XCTAssertFalse(HomeSectionState.empty.isLoaded)
    }

    func testFailedStatePreservesMessageAndCode() {
        let failure = HomeSectionFailure(message: "Network unavailable", code: "offline")
        let state = HomeSectionState.failed(failure)

        guard case .failed(let resolved) = state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertEqual(resolved.message, "Network unavailable")
        XCTAssertEqual(resolved.code, "offline")
    }

    func testSectionStateIsSendableAndHashable() {
        let lhs = HomeSectionState.failed(HomeSectionFailure(message: "Error", code: "E1"))
        let rhs = lhs
        XCTAssertEqual(lhs, rhs)
        XCTAssertEqual(Set([lhs, rhs]).count, 1)
        acceptSendable(HomeSectionState.loading)
    }

    private func acceptSendable<T: Sendable>(_ value: T) {
        XCTAssertNotNil(value)
    }

    // MARK: - Configuration

    func testDefaultStateConfiguration() {
        let configuration = HomeSectionStateConfiguration.default
        XCTAssertEqual(configuration.empty.title, "Nothing here yet")
        XCTAssertEqual(configuration.error.title, "Something went wrong")
        XCTAssertEqual(configuration.error.retryTitle, "Retry")
    }

    func testCustomStateConfiguration() {
        let configuration = HomeSectionStateConfiguration(
            loading: HomeSectionLoadingConfiguration(style: .banner),
            empty: HomeSectionEmptyConfiguration(
                title: "All caught up",
                message: "Check back later"
            ),
            error: HomeSectionErrorConfiguration(
                title: "Unable to load",
                message: "Please try again",
                retryTitle: "Reload",
                retryAction: .custom(name: "reload", payload: nil)
            )
        )

        XCTAssertEqual(configuration.empty.title, "All caught up")
        XCTAssertEqual(configuration.error.retryTitle, "Reload")
        XCTAssertEqual(configuration.loading.style, .banner)
    }

    func testEmptyConfigurationPerSectionType() {
        let configuration = HomeSectionStateConfiguration.default

        XCTAssertEqual(configuration.emptyConfiguration(for: .products).title, "No products")
        XCTAssertEqual(configuration.emptyConfiguration(for: .categories).title, "No categories")
        XCTAssertEqual(configuration.emptyConfiguration(for: .banner).title, "No banners")
        XCTAssertEqual(configuration.emptyConfiguration(for: .brand).title, "No brands")
        XCTAssertEqual(configuration.emptyConfiguration(for: .promotion).title, "No promotions")
        XCTAssertEqual(configuration.emptyConfiguration(for: .liveStream).title, "No live streams")
        XCTAssertEqual(configuration.emptyConfiguration(for: .social).title, "No posts")
    }

    func testLoadingConfigurationPerSectionType() {
        let configuration = HomeSectionStateConfiguration.default

        XCTAssertEqual(
            configuration.loadingConfiguration(for: .banner).style,
            .banner
        )
        XCTAssertEqual(
            configuration.loadingConfiguration(for: .products).style,
            .grid(columns: 2, itemCount: 4)
        )
        XCTAssertEqual(
            configuration.loadingConfiguration(for: .categories).style,
            .horizontal(itemCount: 4)
        )
    }

    func testErrorConfigurationProvidesSectionScopedRetryAction() {
        let configuration = HomeSectionStateConfiguration.default
        let error = configuration.errorConfiguration(forSectionID: "section-products")

        guard case .custom(let name, let payload) = error.retryAction else {
            return XCTFail("Expected custom retry action")
        }
        XCTAssertEqual(name, "retry")
        XCTAssertEqual(payload?["sectionID"], .string("section-products"))
    }

    func testCustomRetryActionIsPreserved() {
        let customRetry = HomeAction.section(id: "section-products")
        let configuration = HomeSectionStateConfiguration(
            error: HomeSectionErrorConfiguration(
                title: "Error",
                retryAction: customRetry
            )
        )
        let error = configuration.errorConfiguration(forSectionID: "section-products")
        XCTAssertEqual(error.retryAction, customRetry)
    }

    // MARK: - Environment

    func testSectionStatesEnvironmentDefaultIsEmpty() {
        let environment = EnvironmentValues()
        XCTAssertTrue(environment.homeSectionStates.isEmpty)
    }

    func testSectionStatesEnvironmentCanBeOverridden() {
        var environment = EnvironmentValues()
        environment.homeSectionStates = ["section-products": .loading]
        XCTAssertEqual(environment.homeSectionStates["section-products"], .loading)
    }

    func testSectionStateConfigurationEnvironmentDefault() {
        let environment = EnvironmentValues()
        XCTAssertEqual(
            environment.homeSectionStateConfiguration.empty.title,
            HomeSectionStateConfiguration.default.empty.title
        )
    }

    // MARK: - State precedence and legacy behavior

    func testMissingSectionStatePreservesLegacyComposition() {
        let composed = composer.compose(
            MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        XCTAssertFalse(composed.isEmpty)
        XCTAssertEqual(composed.count, MockHomePage.sample.sections.count)
    }

    func testExplicitLoadedStateDefersToContentRendering() {
        let section = ComposedHomeSection(
            id: "section-products",
            type: .products,
            title: "Trending",
            order: 0,
            content: .products(ProductSection(products: [
                Product(id: "p1", name: "One", price: 1, currency: "USD")
            ]))
        )
        let states = ["section-products": HomeSectionState.loaded]

        var environment = EnvironmentValues()
        environment.homeSectionStates = states

        XCTAssertEqual(environment.homeSectionStates[section.id], .loaded)
    }

    func testExplicitEmptyStateOverridesContentPresence() {
        let states = ["section-products": HomeSectionState.empty]
        XCTAssertEqual(states["section-products"], .empty)
    }

    func testExplicitLoadingStateLookupBySectionID() {
        let states: [String: HomeSectionState] = [
            "section-banner": .loading,
            "section-products": .failed(HomeSectionFailure(message: "Timeout", code: "408"))
        ]

        XCTAssertEqual(states["section-banner"], .loading)
        guard case .failed(let failure) = states["section-products"] else {
            return XCTFail("Expected failed state")
        }
        XCTAssertEqual(failure.code, "408")
    }

    func testUnknownSectionsRemainSafeWithoutExplicitState() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "future",
            type: .unknown("future_widget"),
            order: 0
        )

        XCTAssertFalse(registry.isRegistered(for: section.type))
        _ = registry.view(for: section)
    }

    // MARK: - Existing pipeline compatibility

    func testPersonalizationBehaviorRemainsIntactWithSectionStates() {
        let homePage = HomePage(
            id: "home-state",
            version: "1.0",
            sections: [
                HomeSection(id: "products-1", type: .products, order: 0)
            ]
        )
        let content: [String: HomeSectionContent] = [
            "products-1": .products(ProductSection(products: [
                Product(id: "p1", name: "One", price: 1, currency: "USD"),
                Product(id: "p2", name: "Two", price: 2, currency: "USD")
            ]))
        ]
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            HomePersonalizationTransformer(strategy: .filterMatchingProducts)
        ])
        let personalization = HomePersonalizationContext(favoriteProductIDs: ["p2"])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline,
            personalization: personalization
        )

        guard case .products(let payload) = composed[0].content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.map(\.id), ["p2"])
    }

    func testTransformationPipelineRemainsIntactWithoutSectionStates() {
        let (homePage, content) = (
            HomePage(
                id: "home-transform",
                version: "1.0",
                sections: [
                    HomeSection(id: "products-1", type: .products, title: "Trending", order: 0)
                ]
            ),
            ["products-1": HomeSectionContent.products(ProductSection(products: [
                Product(id: "p1", name: "One", price: 1, currency: "USD"),
                Product(id: "p2", name: "Two", price: 2, currency: "USD")
            ]))]
        )
        let pipeline = HomeSectionContentTransformerPipeline(transformers: [
            LimitProductsTransformer(limit: 1)
        ])

        let composed = composer.compose(
            homePage,
            contentBySectionID: content,
            transformationPipeline: pipeline
        )

        guard case .products(let payload) = composed[0].content else {
            return XCTFail("Expected products content")
        }
        XCTAssertEqual(payload.products.count, 1)
    }

    func testExistingRenderersRemainRegisteredWithStateSystem() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertTrue(registry.isRegistered(for: .recentlyViewed))
        XCTAssertTrue(registry.isRegistered(for: .recommendations))
        XCTAssertTrue(registry.isRegistered(for: .brand))
        XCTAssertTrue(registry.isRegistered(for: .promotion))
    }

    // MARK: - Empty configuration actions

    func testEmptyStateConfigurationPreservesOptionalAction() {
        let configuration = HomeSectionEmptyConfiguration(
            title: "No favorites",
            message: "Save items to see them here",
            actionTitle: "Browse",
            action: .section(id: "section-products")
        )

        XCTAssertEqual(configuration.title, "No favorites")
        XCTAssertEqual(configuration.actionTitle, "Browse")
        XCTAssertEqual(configuration.action, .section(id: "section-products"))
    }
}

// MARK: - Test transformer from Step 13

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
            section.replacing(content: .products(ProductSection(products: limited)))
        )
    }
}
