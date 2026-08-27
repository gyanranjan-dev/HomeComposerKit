import Foundation
import XCTest
@testable import HomeComposerKit

final class SectionPresentationTests: XCTestCase {

    private let composer = HomeComposer()
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    // MARK: - Layout decoding

    func testKnownLayoutValuesDecode() throws {
        for (raw, expected) in [
            ("horizontal", HomeSectionLayout.horizontal),
            ("vertical", HomeSectionLayout.vertical),
            ("grid", HomeSectionLayout.grid),
            ("carousel", HomeSectionLayout.carousel)
        ] {
            let configuration = try decodeConfiguration("""
            { "layout": "\(raw)" }
            """)
            XCTAssertEqual(configuration.layout, expected)
        }
    }

    func testLayoutDecodingIsCaseInsensitive() throws {
        let configuration = try decodeConfiguration("""
        { "layout": "GRID" }
        """)
        XCTAssertEqual(configuration.layout, .grid)
    }

    func testUnknownLayoutDecodesWithoutCrashing() throws {
        let configuration = try decodeConfiguration("""
        { "layout": "masonry" }
        """)
        XCTAssertEqual(configuration.layout, .unknown("masonry"))
        XCTAssertFalse(configuration.layout?.isKnown ?? true)
    }

    func testUnknownLayoutFallsBackToSectionDefault() {
        let configuration = SectionConfiguration(layout: .unknown("masonry"))
        XCTAssertEqual(configuration.effectiveLayout(for: .products), .horizontal)
        XCTAssertEqual(configuration.effectiveLayout(for: .banner), .carousel)
    }

    // MARK: - Defaults

    func testDefaultLayoutBySectionType() {
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .banner), .carousel)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .categories), .horizontal)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .products), .horizontal)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .popularProducts), .horizontal)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .favoriteProducts), .horizontal)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .liveStream), .horizontal)
        XCTAssertEqual(SectionConfiguration.defaultLayout(for: .social), .horizontal)
    }

    func testMissingLayoutUsesSectionDefault() {
        let configuration = SectionConfiguration()
        XCTAssertEqual(configuration.effectiveLayout(for: .banner), .carousel)
        XCTAssertEqual(configuration.effectiveLayout(for: .categories), .horizontal)
    }

    // MARK: - Presentation fields

    func testShowTitleAndShowSeeAllDecode() throws {
        let configuration = try decodeConfiguration("""
        {
            "showTitle": false,
            "showSeeAll": true
        }
        """)

        XCTAssertEqual(configuration.showTitle, false)
        XCTAssertEqual(configuration.showSeeAll, true)
    }

    func testEffectiveShowTitleDefaultsToTitlePresence() {
        let configuration = SectionConfiguration()
        XCTAssertTrue(configuration.effectiveShowTitle(hasTitle: true))
        XCTAssertFalse(configuration.effectiveShowTitle(hasTitle: false))
    }

    func testEffectiveShowTitleRespectsExplicitFalse() {
        let configuration = SectionConfiguration(showTitle: false)
        XCTAssertFalse(configuration.effectiveShowTitle(hasTitle: true))
    }

    func testEffectiveShowSeeAllDefaultsToFalse() {
        XCTAssertFalse(SectionConfiguration().effectiveShowSeeAll)
        XCTAssertTrue(
            SectionConfiguration(showSeeAll: true).effectiveShowSeeAll
        )
    }

    func testEffectiveSpacingAndColumnsDefaults() {
        let configuration = SectionConfiguration()
        XCTAssertEqual(configuration.effectiveSpacing, 12)
        XCTAssertEqual(configuration.effectiveColumns(), 2)
    }

    func testEffectiveColumnsClampsToAtLeastOne() {
        let configuration = SectionConfiguration(columns: 0)
        XCTAssertEqual(configuration.effectiveColumns(default: 2), 1)
    }

    func testItemLimitRemainsSupported() throws {
        let configuration = try decodeConfiguration("""
        { "limit": 6 }
        """)
        XCTAssertEqual(configuration.limit, 6)
    }

    // MARK: - Round-trip and compatibility

    func testConfigurationRoundTripPreservesPresentationFields() throws {
        let original = SectionConfiguration(
            layout: .grid,
            limit: 10,
            columns: 2,
            spacing: 16,
            showTitle: true,
            showSeeAll: true
        )

        let data = try jsonEncoder.encode(original)
        let decoded = try jsonDecoder.decode(SectionConfiguration.self, from: data)

        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.layout?.rawValue, "grid")
    }

    func testMissingConfigurationFieldsDecodeAsNil() throws {
        let configuration = try decodeConfiguration("{}")

        XCTAssertNil(configuration.layout)
        XCTAssertNil(configuration.limit)
        XCTAssertNil(configuration.columns)
        XCTAssertNil(configuration.spacing)
        XCTAssertNil(configuration.showTitle)
        XCTAssertNil(configuration.showSeeAll)
    }

    func testBackendUnknownConfigurationFieldsAreIgnored() throws {
        let configuration = try decodeConfiguration("""
        {
            "layout": "horizontal",
            "futureFeatureFlag": true,
            "animationProfile": "spring"
        }
        """)

        XCTAssertEqual(configuration.layout, .horizontal)
    }

    func testExistingMockHomePageConfigurationsRemainCompatible() throws {
        let data = try jsonEncoder.encode(MockHomePage.sample)
        let decoded = try jsonDecoder.decode(HomePage.self, from: data)

        XCTAssertEqual(decoded.sections.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(decoded.sections[0].configuration?.layout, .carousel)
        XCTAssertEqual(decoded.sections[2].configuration?.layout, .grid)
    }

    // MARK: - Composition

    func testCompositionPreservesPresentationConfiguration() {
        let configuration = SectionConfiguration(
            layout: .vertical,
            limit: 4,
            columns: 3,
            spacing: 8,
            showTitle: false,
            showSeeAll: true
        )
        let homePage = HomePage(
            id: "home-presentation",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "products-1",
                    type: .products,
                    title: "Trending",
                    order: 0,
                    configuration: configuration
                )
            ]
        )

        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.count, 1)
        XCTAssertEqual(composed[0].configuration, configuration)
        XCTAssertEqual(composed[0].configuration?.layout, .vertical)
        XCTAssertEqual(composed[0].configuration?.showSeeAll, true)
    }

    // MARK: - Helpers

    private func decodeConfiguration(_ json: String) throws -> SectionConfiguration {
        try jsonDecoder.decode(SectionConfiguration.self, from: Data(json.utf8))
    }
}
