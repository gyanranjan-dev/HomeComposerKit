import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

final class HomeActionTests: XCTestCase {

    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()

    // MARK: - Known action decoding

    func testOpenURLActionDecoding() throws {
        let action = try decodeAction("""
        { "type": "openURL", "url": "https://example.com/sale" }
        """)

        XCTAssertEqual(action, .openURL(url: "https://example.com/sale"))
        XCTAssertEqual(action.typeName, "openURL")
        XCTAssertTrue(action.isKnown)
    }

    func testProductActionDecoding() throws {
        let action = try decodeAction("""
        { "type": "product", "id": "prod-001" }
        """)

        XCTAssertEqual(action, .product(id: "prod-001"))
    }

    func testCategoryActionDecoding() throws {
        let action = try decodeAction("""
        { "type": "category", "id": "cat-fashion" }
        """)

        XCTAssertEqual(action, .category(id: "cat-fashion"))
    }

    func testSectionActionDecoding() throws {
        let action = try decodeAction("""
        { "type": "section", "id": "section-products" }
        """)

        XCTAssertEqual(action, .section(id: "section-products"))
    }

    func testCustomActionDecoding() throws {
        let action = try decodeAction("""
        {
            "type": "custom",
            "name": "flash_sale",
            "payload": {
                "campaignId": "cmp-42",
                "priority": 1
            }
        }
        """)

        guard case .custom(let name, let payload) = action else {
            return XCTFail("Expected custom action")
        }
        XCTAssertEqual(name, "flash_sale")
        XCTAssertEqual(payload?["campaignId"], .string("cmp-42"))
        XCTAssertEqual(payload?["priority"], .int(1))
    }

    // MARK: - Resilience

    func testUnknownActionTypeDecodesWithoutCrashing() throws {
        let action = try decodeAction("""
        {
            "type": "futureAction",
            "payload": { "token": "abc" }
        }
        """)

        guard case .unknown(let type, let payload) = action else {
            return XCTFail("Expected unknown action")
        }
        XCTAssertEqual(type, "futureAction")
        XCTAssertEqual(payload?["token"], .string("abc"))
        XCTAssertFalse(action.isKnown)
    }

    func testUnknownActionPreservesTopLevelFields() throws {
        let action = try decodeAction("""
        {
            "type": "futureAction",
            "token": "abc",
            "count": 3
        }
        """)

        guard case .unknown(_, let payload) = action else {
            return XCTFail("Expected unknown action")
        }
        XCTAssertEqual(payload?["token"], .string("abc"))
        XCTAssertEqual(payload?["count"], .int(3))
    }

    func testMalformedActionDecodingThrows() {
        XCTAssertThrowsError(
            try decodeAction("""
            { "type": "openURL" }
            """)
        ) { error in
            XCTAssertTrue(error is DecodingError)
        }

        XCTAssertThrowsError(
            try decodeAction("""
            { "url": "https://example.com" }
            """)
        ) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("Expected keyNotFound")
            }
            XCTAssertEqual(key.stringValue, "type")
        }
    }

    // MARK: - Encoding / round-trip

    func testActionRoundTrip() throws {
        let actions: [HomeAction] = [
            .openURL(url: "https://example.com"),
            .product(id: "prod-1"),
            .category(id: "cat-1"),
            .section(id: "section-1"),
            .custom(name: "promo", payload: ["code": .string("SAVE10")]),
            .unknown(type: "futureAction", payload: ["token": .string("xyz")])
        ]

        for action in actions {
            let data = try jsonEncoder.encode(action)
            let decoded = try jsonDecoder.decode(HomeAction.self, from: data)
            XCTAssertEqual(decoded, action)
        }
    }

    // MARK: - Banner integration

    func testBannerActionMapsToOpenURLForHTTPDestination() {
        let action = HomeAction.from(
            bannerAction: BannerAction(title: "Shop", destination: "https://example.com/sale"),
            bannerID: "banner-1"
        )

        XCTAssertEqual(action, .openURL(url: "https://example.com/sale"))
    }

    func testBannerActionMapsToCustomForAppSchemeDestination() {
        let action = HomeAction.from(
            bannerAction: BannerAction(title: "Shop", destination: "app://sale/summer"),
            bannerID: "banner-1"
        )

        guard case .custom(let name, let payload) = action else {
            return XCTFail("Expected custom action")
        }
        XCTAssertEqual(name, "banner")
        XCTAssertEqual(payload?["destination"], .string("app://sale/summer"))
        XCTAssertEqual(payload?["bannerID"], .string("banner-1"))
        XCTAssertEqual(payload?["title"], .string("Shop"))
    }

    func testBannerWithoutActionProducesNilHomeAction() {
        let banner = Banner(
            id: "banner-1",
            title: "Sale",
            imageURL: URL(string: "https://example.com/banner.jpg")!
        )

        XCTAssertNil(HomeAction.from(banner: banner))
    }

    // MARK: - Handler

    func testActionHandlerReceivesExpectedAction() {
        let recorder = HomeActionRecorder()

        recorder.handle(.product(id: "prod-99"))
        recorder.handle(.section(id: "section-products"))

        XCTAssertEqual(recorder.actions.count, 2)
        XCTAssertEqual(recorder.actions[0], .product(id: "prod-99"))
        XCTAssertEqual(recorder.actions[1], .section(id: "section-products"))
    }

    func testClosureBasedActionHandlerForwardsActions() {
        var received: [HomeAction] = []
        let handler = HomeActionHandler { received.append($0) }

        handler.handle(.category(id: "cat-home"))
        handler.handle(.openURL(url: "https://example.com"))

        XCTAssertEqual(received, [
            .category(id: "cat-home"),
            .openURL(url: "https://example.com")
        ])
    }

    func testNoOpActionHandlerDoesNotCrash() {
        HomeActionHandler.noop.handle(.product(id: "prod-1"))
    }

    @MainActor
    func testDefaultRegistryStillRegistersBuiltInSectionTypes() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertTrue(registry.isRegistered(for: .categories))
    }

    @MainActor
    func testHostCanRegisterCustomRendererWithoutReplacingBuiltIns() {
        var registry = HomeSectionRendererRegistry.makeDefault()
        registry.register(.custom) { section in
            Text(section.id)
        }

        XCTAssertTrue(registry.isRegistered(for: .custom))
        XCTAssertTrue(registry.isRegistered(for: .banner))
    }

    func testHomeComposerViewInitializerRemainsNonBreakingWithoutActionHandler() {
        let view = HomeComposerView(homePage: MockHomePage.sample)
        XCTAssertEqual(view.homePage.id, MockHomePage.sample.id)
    }

    // MARK: - Helpers

    private func decodeAction(_ json: String) throws -> HomeAction {
        try jsonDecoder.decode(HomeAction.self, from: Data(json.utf8))
    }
}
