import Foundation
import XCTest
@testable import HomeComposerKit

final class HomeAPIResponseTests: XCTestCase {

    private let apiDecoder = HomeAPIResponseDecoder()
    private let composer = HomeComposer()
    private let builder = HomeRenderContextBuilder()

    // MARK: - Complete / minimal decoding

    func testCompleteAPIResponseDecoding() throws {
        let response = try apiDecoder.decode(Self.completeJSON)

        XCTAssertEqual(response.id, "home-001")
        XCTAssertEqual(response.version, "1.0")
        XCTAssertEqual(response.title, "Discover")
        XCTAssertEqual(response.schemaVersion, "2024-08")
        XCTAssertEqual(response.configurationVersion, "12")
        XCTAssertEqual(response.sections.count, 2)
        XCTAssertEqual(response.sections[0].contentRef, "content://banners/featured")
        XCTAssertEqual(response.metadata?.locale, "en-US")
        XCTAssertEqual(response.metadata?.channel, "mobile")
        XCTAssertEqual(response.metadata?.tags, ["home", "launch"])
        XCTAssertEqual(response.metadata?.extras?["experiment"], "A")
    }

    func testMinimalAPIResponseDecoding() throws {
        let json = """
        {
            "id": "home-min",
            "sections": []
        }
        """

        let response = try apiDecoder.decode(json)

        XCTAssertEqual(response.id, "home-min")
        XCTAssertNil(response.version)
        XCTAssertNil(response.schemaVersion)
        XCTAssertNil(response.configurationVersion)
        XCTAssertNil(response.metadata)
        XCTAssertTrue(response.sections.isEmpty)
    }

    // MARK: - Forward compatibility

    func testUnknownBackendFieldsAreIgnored() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "backendOnlyFlag": true,
            "trackingPixel": "https://example.com/t",
            "sections": [
                {
                    "id": "section-1",
                    "type": "banner",
                    "order": 0,
                    "isEnabled": true,
                    "vendorExtension": { "foo": 1 },
                    "configuration": {
                        "layout": "carousel",
                        "futureLayoutHint": "parallax",
                        "limit": 3
                    }
                }
            ],
            "metadata": {
                "locale": "en",
                "unknownMeta": 123
            }
        }
        """

        let response = try apiDecoder.decode(json)

        XCTAssertEqual(response.id, "home-001")
        XCTAssertEqual(response.sections.count, 1)
        XCTAssertEqual(response.sections[0].type, .banner)
        XCTAssertEqual(response.sections[0].configuration?.layout, "carousel")
        XCTAssertEqual(response.sections[0].configuration?.limit, 3)
        XCTAssertEqual(response.metadata?.locale, "en")
    }

    func testUnknownSectionTypesSurviveDecoding() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "sections": [
                {
                    "id": "flash",
                    "type": "flash_sale_v2",
                    "order": 2,
                    "contentRef": "content://flash/1"
                }
            ]
        }
        """

        let response = try apiDecoder.decode(json)

        XCTAssertEqual(response.sections[0].type, HomeSectionType.unknown("flash_sale_v2"))
        XCTAssertEqual(response.sections[0].contentRef, "content://flash/1")
        XCTAssertEqual(response.contentReferencesBySectionID["flash"], "content://flash/1")
    }

    func testSchemaAndConfigurationVersionsDecode() throws {
        let response = try apiDecoder.decode(Self.completeJSON)

        XCTAssertEqual(response.schemaVersion, "2024-08")
        XCTAssertEqual(response.configurationVersion, "12")
    }

    // MARK: - Failures

    func testMalformedResponseFailsCleanly() {
        XCTAssertThrowsError(try apiDecoder.decode(Data("not-json".utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testMissingRequiredFieldsFailCleanly() {
        let json = """
        {
            "version": "1.0",
            "sections": []
        }
        """

        XCTAssertThrowsError(try apiDecoder.decode(json)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("Expected keyNotFound, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "id")
        }
    }

    // MARK: - Conversion

    func testConversionFromAPIResponseToHomePage() throws {
        let response = try apiDecoder.decode(Self.completeJSON)
        let homePage = response.makeHomePage()

        XCTAssertEqual(homePage.id, "home-001")
        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertEqual(homePage.title, "Discover")
        XCTAssertEqual(homePage.schemaVersion, "2024-08")
        XCTAssertEqual(homePage.configurationVersion, "12")
        XCTAssertEqual(homePage.sections.count, 2)
        XCTAssertEqual(homePage.sections[0].id, "section-banner")
        XCTAssertEqual(homePage.sections[0].type, .banner)
        XCTAssertTrue(homePage.sections[0].isEnabled)
        XCTAssertEqual(homePage.sections[1].type, .products)
        XCTAssertEqual(homePage.sections[1].configuration?.layout, "grid")
    }

    func testMinimalResponseUsesDefaultHomePageVersion() throws {
        let response = try apiDecoder.decode("""
        { "id": "home-min", "sections": [] }
        """)

        let homePage = response.makeHomePage()

        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertNil(homePage.schemaVersion)
    }

    func testConfigurationVersionDoesNotFallbackToHomePageVersion() throws {
        let response = try apiDecoder.decode("""
        {
            "id": "home-min",
            "configurationVersion": "7",
            "sections": []
        }
        """)

        let homePage = response.makeHomePage()

        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertEqual(homePage.configurationVersion, "7")
    }

    func testOmittedIsEnabledDefaultsToTrue() throws {
        let response = try apiDecoder.decode("""
        {
            "id": "home-001",
            "sections": [
                { "id": "s1", "type": "banner", "order": 0 }
            ]
        }
        """)

        XCTAssertNil(response.sections[0].isEnabled)
        XCTAssertTrue(response.makeHomePage().sections[0].isEnabled)
    }

    func testConversionIntoHomeRenderContext() throws {
        let response = try apiDecoder.decode(Self.completeJSON)
        let content: [String: HomeSectionContent] = [
            "section-banner": .banner(MockHomePage.sampleBannerSection)
        ]

        let context = builder.makeContext(
            from: response,
            contentBySectionID: content
        )

        XCTAssertEqual(context.homePage.id, "home-001")
        XCTAssertEqual(context.contentBySectionID.count, 1)

        let composed = context.compose()
        XCTAssertEqual(composed.first?.id, "section-banner")
        XCTAssertNotNil(composed.first?.content)
    }

    func testMakeContextFromAPIResponseData() throws {
        let data = Data(Self.completeJSON.utf8)

        let context = try builder.makeContext(fromAPIResponse: data)

        XCTAssertEqual(context.homePage.id, "home-001")
        XCTAssertEqual(context.homePage.sections.count, 2)
    }

    // MARK: - Composer compatibility

    func testExistingHomeComposerBehaviorRemainsUnchanged() throws {
        let response = try apiDecoder.decode("""
        {
            "id": "home-order",
            "version": "1.0",
            "sections": [
                { "id": "c", "type": "social", "order": 30, "isEnabled": true },
                { "id": "disabled", "type": "banner", "order": 5, "isEnabled": false },
                { "id": "a", "type": "banner", "order": 10, "isEnabled": true },
                { "id": "b", "type": "products", "order": 20, "isEnabled": true },
                { "id": "flash", "type": "flash_sale_v2", "order": 15, "isEnabled": true }
            ]
        }
        """)

        let homePage = response.makeHomePage()
        let composed = composer.compose(homePage)

        XCTAssertEqual(composed.map(\.id), ["a", "flash", "b", "c"])
        XCTAssertEqual(composed[1].type, HomeSectionType.unknown("flash_sale_v2"))
        XCTAssertFalse(composed.contains { $0.id == "disabled" })
    }

    // MARK: - Fixtures

    private static let completeJSON = """
    {
        "id": "home-001",
        "version": "1.0",
        "title": "Discover",
        "schemaVersion": "2024-08",
        "configurationVersion": "12",
        "sections": [
            {
                "id": "section-banner",
                "type": "banner",
                "title": "Featured",
                "order": 0,
                "isEnabled": true,
                "configuration": {
                    "layout": "carousel",
                    "limit": 5,
                    "columns": 1,
                    "spacing": 8.0
                },
                "contentRef": "content://banners/featured"
            },
            {
                "id": "section-products",
                "type": "products",
                "title": "Trending",
                "order": 1,
                "isEnabled": true,
                "configuration": {
                    "layout": "grid",
                    "limit": 10,
                    "columns": 2,
                    "spacing": 12.0
                },
                "contentRef": "content://products/trending"
            }
        ],
        "metadata": {
            "locale": "en-US",
            "channel": "mobile",
            "tags": ["home", "launch"],
            "extras": {
                "experiment": "A"
            }
        }
    }
    """
}
