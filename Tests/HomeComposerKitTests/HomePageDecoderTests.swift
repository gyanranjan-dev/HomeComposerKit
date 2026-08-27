import Foundation
import XCTest
@testable import HomeComposerKit

final class HomePageDecoderTests: XCTestCase {

    private let decoder = HomePageDecoder()

    // MARK: - Valid payloads

    func testDecodeValidHomePageFromData() throws {
        let data = try XCTUnwrap(Self.validHomePageJSON.data(using: .utf8))

        let homePage = try decoder.decode(data)

        XCTAssertEqual(homePage.id, "home-001")
        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertEqual(homePage.title, "Discover")
        XCTAssertEqual(homePage.sections.count, 2)
    }

    func testDecodeMockHomePageRoundTrip() throws {
        let encoded = try JSONEncoder().encode(MockHomePage.sample)

        let homePage = try decoder.decode(encoded)

        XCTAssertEqual(homePage.id, MockHomePage.sample.id)
        XCTAssertEqual(homePage.version, MockHomePage.sample.version)
        XCTAssertEqual(homePage.title, MockHomePage.sample.title)
        XCTAssertEqual(homePage.sections.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(
            homePage.sections.map(\.id),
            MockHomePage.sample.sections.map(\.id)
        )
    }

    func testDecodeFromString() throws {
        let homePage = try decoder.decode(Self.validHomePageJSON)

        XCTAssertEqual(homePage.id, "home-001")
        XCTAssertEqual(homePage.sections.first?.type, .banner)
    }

    // MARK: - Invalid payloads

    func testInvalidJSONThrows() {
        let data = Data("not-json".utf8)

        XCTAssertThrowsError(try decoder.decode(data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testMissingRequiredFieldThrowsDecodingError() {
        let json = """
        {
            "id": "home-001",
            "title": "Discover",
            "sections": []
        }
        """
        let data = Data(json.utf8)

        XCTAssertThrowsError(try decoder.decode(data)) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("Expected keyNotFound DecodingError, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "version")
        }
    }

    // MARK: - Order and configuration

    func testDecodedSectionsPreserveOriginalOrder() throws {
        let homePage = try decoder.decode(Self.validHomePageJSON)

        XCTAssertEqual(homePage.sections.map(\.id), ["section-banner", "section-products"])
        XCTAssertEqual(homePage.sections.map(\.order), [0, 2])
        XCTAssertEqual(homePage.sections.map(\.type), [.banner, .products])
    }

    func testDecodedSectionConfigurationRemainsIntact() throws {
        let homePage = try decoder.decode(Self.validHomePageJSON)
        let products = try XCTUnwrap(homePage.sections.first { $0.id == "section-products" })

        XCTAssertEqual(products.configuration?.layout, .grid)
        XCTAssertEqual(products.configuration?.limit, 10)
        XCTAssertEqual(products.configuration?.columns, 2)
        XCTAssertEqual(products.configuration?.spacing, 12.0)
        XCTAssertTrue(products.isEnabled)
    }

    func testDecoderMatchesDirectJSONDecoderBehavior() throws {
        let data = try XCTUnwrap(Self.validHomePageJSON.data(using: .utf8))

        let viaAPI = try decoder.decode(data)
        let viaJSONDecoder = try JSONDecoder().decode(HomePage.self, from: data)

        XCTAssertEqual(viaAPI.id, viaJSONDecoder.id)
        XCTAssertEqual(viaAPI.version, viaJSONDecoder.version)
        XCTAssertEqual(viaAPI.title, viaJSONDecoder.title)
        XCTAssertEqual(viaAPI.sections.count, viaJSONDecoder.sections.count)
        XCTAssertEqual(viaAPI.sections.map(\.id), viaJSONDecoder.sections.map(\.id))
        XCTAssertEqual(
            viaAPI.sections.map(\.configuration?.layout),
            viaJSONDecoder.sections.map(\.configuration?.layout)
        )
    }

    // MARK: - Fixtures

    private static let validHomePageJSON = """
    {
        "id": "home-001",
        "version": "1.0",
        "title": "Discover",
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
                }
            },
            {
                "id": "section-products",
                "type": "products",
                "title": "Trending",
                "order": 2,
                "isEnabled": true,
                "configuration": {
                    "layout": "grid",
                    "limit": 10,
                    "columns": 2,
                    "spacing": 12.0
                }
            }
        ]
    }
    """
}
