import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

/// Integration-boundary tests: host-supplied Data → decode → compose → view inputs.
///
/// These tests intentionally never touch URLSession or any network API.
@MainActor
final class HomeIntegrationTests: XCTestCase {

    private let builder = HomeRenderContextBuilder()

    // MARK: - Decode

    func testValidJSONDataDecodesIntoHomePage() throws {
        let data = try JSONEncoder().encode(MockHomePage.sample)

        let context = try builder.makeContext(from: data)

        XCTAssertEqual(context.homePage.id, MockHomePage.sample.id)
        XCTAssertEqual(context.homePage.version, MockHomePage.sample.version)
        XCTAssertEqual(context.homePage.sections.count, MockHomePage.sample.sections.count)
    }

    func testDataProviderDecodesThroughExistingDecoder() throws {
        let data = try JSONEncoder().encode(MockHomePage.sample)
        let provider = StaticHomePageDataProvider(data)

        let context = try builder.makeContext(
            fromDataProvider: provider,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(context.homePage.id, "home-001")
        XCTAssertFalse(context.contentBySectionID.isEmpty)
    }

    func testHomePageProviderSuppliesDecodedPageWithoutNetworking() throws {
        let provider = StaticHomePageProvider(MockHomePage.sample)

        let context = try builder.makeContext(
            from: provider,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(context.homePage.title, "Discover")
        XCTAssertEqual(context.contentBySectionID.count, MockHomePage.sampleContent.count)
    }

    // MARK: - Compose through integration boundary

    func testDecodedHomePageCanBeComposed() throws {
        let data = try JSONEncoder().encode(MockHomePage.sample)
        let context = try builder.makeContext(
            from: data,
            contentBySectionID: MockHomePage.sampleContent
        )

        let composed = context.compose()

        XCTAssertFalse(composed.isEmpty)
        XCTAssertEqual(composed.count, MockHomePage.sample.sections.filter(\.isEnabled).count)
    }

    func testSectionOrderingAndFilteringThroughIntegrationBoundary() throws {
        let page = HomePage(
            id: "integration-order",
            version: "1.0",
            sections: [
                HomeSection(id: "c", type: .social, order: 30, isEnabled: true),
                HomeSection(id: "disabled", type: .banner, order: 5, isEnabled: false),
                HomeSection(id: "a", type: .banner, order: 10, isEnabled: true),
                HomeSection(id: "b", type: .products, order: 20, isEnabled: true)
            ]
        )

        let context = builder.makeContext(homePage: page)
        let composed = context.compose()

        XCTAssertEqual(composed.map(\.id), ["a", "b", "c"])
        XCTAssertFalse(composed.contains { $0.id == "disabled" })
    }

    func testContentBySectionIDReachesComposedSections() throws {
        let data = try JSONEncoder().encode(MockHomePage.sample)
        let context = try builder.makeContext(
            from: data,
            contentBySectionID: MockHomePage.sampleContent
        )

        let composed = context.compose()
        let banner = try XCTUnwrap(composed.first { $0.id == "section-banner" })

        XCTAssertNotNil(banner.content)
        guard case .banner(let payload) = banner.content else {
            return XCTFail("Expected banner content to reach composed section")
        }
        XCTAssertFalse(payload.banners.isEmpty)
    }

    // MARK: - Renderer registry injection

    func testRendererRegistryCanBeInjectedIntoHomeComposerView() throws {
        let context = try builder.makeContext(
            from: JSONEncoder().encode(MockHomePage.sample),
            contentBySectionID: MockHomePage.sampleContent
        )

        let registry = HomeSectionRendererRegistry.makeDefault()
            .registering(.custom) { section in
                Text(section.id)
            }

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertTrue(registry.isRegistered(for: .custom))

        _ = HomeComposerView(context: context, rendererRegistry: registry)
    }

    func testRegisteringDoesNotMutateOriginalRegistry() {
        let original = HomeSectionRendererRegistry.makeDefault()
        let customized = original.registering(.custom) { section in
            Text(section.title ?? section.id)
        }

        XCTAssertFalse(original.isRegistered(for: .custom))
        XCTAssertTrue(customized.isRegistered(for: .custom))
    }

    // MARK: - Failure / no networking

    func testMalformedJSONFailsCleanly() {
        XCTAssertThrowsError(
            try builder.makeContext(from: Data("{not-json".utf8))
        ) { error in
            XCTAssertTrue(
                error is DecodingError,
                "Expected DecodingError from decoder, got \(error)"
            )
        }
    }

    func testMalformedDataProviderFailsCleanly() {
        let provider = StaticHomePageDataProvider(Data("totally-invalid".utf8))

        XCTAssertThrowsError(
            try builder.makeContext(fromDataProvider: provider)
        ) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
