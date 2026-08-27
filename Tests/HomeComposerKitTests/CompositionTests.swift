import Foundation
import XCTest
@testable import HomeComposerKit

final class CompositionTests: XCTestCase {

    private let composer = HomeComposer()

    // MARK: - Ordering

    func testSectionsAreOrderedCorrectly() {
        let homePage = HomePage(
            id: "home-order",
            version: "1.0",
            title: "Ordered",
            sections: [
                HomeSection(id: "c", type: .social, title: "C", order: 30),
                HomeSection(id: "a", type: .banner, title: "A", order: 10),
                HomeSection(id: "b", type: .products, title: "B", order: 20)
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.map(\.id), ["a", "b", "c"])
        XCTAssertEqual(composed.map(\.order), [10, 20, 30])
    }

    func testOriginalOrderPreservedWhenPositionsAreEqual() {
        let homePage = HomePage(
            id: "home-tie",
            version: "1.0",
            sections: [
                HomeSection(id: "first", type: .banner, order: 1),
                HomeSection(id: "second", type: .categories, order: 1),
                HomeSection(id: "third", type: .products, order: 1),
                HomeSection(id: "later", type: .social, order: 5)
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.map(\.id), ["first", "second", "third", "later"])
    }

    // MARK: - Disabled sections

    func testDisabledSectionsAreExcluded() {
        let homePage = HomePage(
            id: "home-disabled",
            version: "1.0",
            sections: [
                HomeSection(id: "enabled-banner", type: .banner, order: 0, isEnabled: true),
                HomeSection(id: "disabled-products", type: .products, order: 1, isEnabled: false),
                HomeSection(id: "enabled-social", type: .social, order: 2, isEnabled: true)
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.map(\.id), ["enabled-banner", "enabled-social"])
        XCTAssertFalse(composed.contains { $0.id == "disabled-products" })
    }

    // MARK: - Empty sections

    func testEmptySectionsDoNotCrash() {
        let homePage = HomePage(
            id: "home-empty",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "empty-banner",
                    type: .banner,
                    title: "Empty Banner",
                    order: 0,
                    isEnabled: true,
                    configuration: nil
                ),
                HomeSection(
                    id: "empty-products",
                    type: .products,
                    title: nil,
                    order: 1,
                    isEnabled: true,
                    configuration: SectionConfiguration()
                )
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.count, 2)
        XCTAssertEqual(composed[0].id, "empty-banner")
        XCTAssertNil(composed[0].configuration)
        XCTAssertEqual(composed[1].id, "empty-products")
        XCTAssertNotNil(composed[1].configuration)
    }

    // MARK: - Supported section types

    func testAllSupportedSectionTypesCanBeComposed() {
        let supportedTypes: [HomeSectionType] = [
            .banner,
            .categories,
            .products,
            .favoriteProducts,
            .popularProducts,
            .liveStream,
            .social
        ]

        let sections = supportedTypes.enumerated().map { index, type in
            HomeSection(
                id: "section-\(type.rawValue)",
                type: type,
                title: type.rawValue,
                order: index,
                isEnabled: true
            )
        }

        let homePage = HomePage(
            id: "home-supported",
            version: "1.0",
            sections: sections
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.count, supportedTypes.count)
        XCTAssertEqual(composed.map(\.type), supportedTypes)
        XCTAssertEqual(Set(composed.map(\.id)).count, supportedTypes.count)
    }

    // MARK: - Composed payload

    func testComposedSectionCarriesRendererData() {
        let configuration = SectionConfiguration(
            layout: .grid,
            limit: 8,
            columns: 2,
            spacing: 12.0
        )
        let homePage = HomePage(
            id: "home-payload",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "products-1",
                    type: .products,
                    title: "Trending",
                    order: 4,
                    isEnabled: true,
                    configuration: configuration
                )
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.count, 1)
        XCTAssertEqual(composed[0].id, "products-1")
        XCTAssertEqual(composed[0].type, .products)
        XCTAssertEqual(composed[0].title, "Trending")
        XCTAssertEqual(composed[0].order, 4)
        XCTAssertEqual(composed[0].configuration?.layout, .grid)
        XCTAssertEqual(composed[0].configuration?.limit, 8)
        XCTAssertEqual(composed[0].configuration?.columns, 2)
        XCTAssertEqual(composed[0].configuration?.spacing, 12.0)
    }

    func testComposeUsesMockHomePage() {
        let composed = composer.compose(MockHomePage.sample)

        XCTAssertEqual(composed.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(composed.map(\.order), composed.map(\.order).sorted())
        XCTAssertEqual(composed.first?.type, .banner)
        XCTAssertEqual(composed.last?.type, .social)
    }

    func testComposeAttachesSectionContentByID() {
        let composed = composer.compose(
            MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(composed.count, MockHomePage.sample.sections.count)
        XCTAssertNotNil(composed.first?.content)
        XCTAssertEqual(composed.first?.type, .banner)

        if case .banner(let banners) = composed.first?.content {
            XCTAssertFalse(banners.banners.isEmpty)
        } else {
            XCTFail("Expected banner content on the first section")
        }
    }

    func testHomeSectionComposableRespectsEnabledFlag() {
        let enabled = HomeSection(id: "on", type: .banner, order: 0, isEnabled: true)
        let disabled = HomeSection(id: "off", type: .banner, order: 1, isEnabled: false)

        XCTAssertTrue(enabled.canCompose)
        XCTAssertFalse(disabled.canCompose)
    }
}
