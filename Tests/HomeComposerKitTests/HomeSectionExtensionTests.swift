import SwiftUI
import XCTest
@testable import HomeComposerKit

// MARK: - Example custom renderer (test-only)

@MainActor
private struct FlashSaleRenderer: HomeSectionRendering {
    func render(section: ComposedHomeSection) -> some View {
        Text(section.title ?? section.id)
            .accessibilityIdentifier("flash-sale-renderer")
    }
}

@MainActor
final class HomeSectionExtensionTests: XCTestCase {

    // MARK: - Built-in resolution

    func testBuiltInRendererResolutionStillWorks() {
        let registry = HomeSectionRendererRegistry.default

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertNotNil(registry.view(for: composedSection(type: .banner)))
    }

    func testUnknownSectionHasSafeFallback() {
        let registry = HomeSectionRendererRegistry.default
        let section = composedSection(type: .unknown("flash_sale"))

        XCTAssertFalse(registry.isRegistered(for: section.type))
        _ = registry.view(for: section)
    }

    // MARK: - Custom registration

    func testCustomRendererRegistrationByRawType() {
        let registry = HomeSectionRendererRegistry.default
            .registering(type: "flash_sale") { section in
                Text("Flash \(section.id)")
            }

        XCTAssertTrue(registry.isRegistered(for: "flash_sale"))
        XCTAssertTrue(registry.isRegistered(for: .unknown("flash_sale")))
        XCTAssertTrue(registry.isRegistered(for: .banner))
    }

    func testCustomRendererResolvesUnknownRawType() {
        let registry = HomeSectionRendererRegistry.default
            .registering(type: "flash_sale") { section in
                Text(section.id)
            }

        let section = composedSection(
            id: "flash-1",
            type: .unknown("flash_sale"),
            title: "Flash Deals"
        )

        _ = registry.view(for: section)
        XCTAssertTrue(registry.isRegistered(for: section.type))
    }

    func testProtocolBasedRendererRegistration() {
        let registry = HomeSectionRendererRegistry.default
            .registering(type: "flash_sale", renderer: FlashSaleRenderer())

        XCTAssertTrue(registry.isRegistered(for: "flash_sale"))
        _ = registry.view(
            for: composedSection(
                id: "flash-2",
                type: .unknown("flash_sale"),
                title: "Limited Time"
            )
        )
    }

    func testCustomRendererReceivesExpectedSection() {
        var receivedID: String?
        var receivedTitle: String?

        let registry = HomeSectionRendererRegistry.default
            .registering(type: "flash_sale") { section in
                receivedID = section.id
                receivedTitle = section.title
                return Text(section.title ?? section.id)
            }

        let section = composedSection(
            id: "flash-3",
            type: .unknown("flash_sale"),
            title: "Today Only"
        )

        _ = registry.view(for: section)

        XCTAssertEqual(receivedID, "flash-3")
        XCTAssertEqual(receivedTitle, "Today Only")
    }

    // MARK: - Override behavior

    func testCustomRendererCanOverrideBuiltInRenderer() {
        var renderedBannerOverride = false

        let registry = HomeSectionRendererRegistry.default
            .registering(type: "banner") { _ in
                renderedBannerOverride = true
                return Text("override")
            }

        XCTAssertTrue(registry.isRegistered(for: .banner))
        _ = registry.view(for: composedSection(type: .banner))
        XCTAssertTrue(renderedBannerOverride)
    }

    func testDuplicateRegistrationUsesLatestRenderer() {
        var first = false
        var second = false

        var registry = HomeSectionRendererRegistry.default
        registry.register(type: "flash_sale") { _ in
            first = true
            return Text("first")
        }
        registry.register(type: "flash_sale") { _ in
            second = true
            return Text("second")
        }

        _ = registry.view(for: composedSection(type: .unknown("flash_sale")))

        XCTAssertFalse(first)
        XCTAssertTrue(second)
    }

    // MARK: - Instance isolation

    func testSeparateRegistryInstancesDoNotShareMutableState() {
        var registryA = HomeSectionRendererRegistry.default
        var registryB = HomeSectionRendererRegistry.default

        registryA.register(type: "flash_sale") { _ in Text("A") }

        XCTAssertTrue(registryA.isRegistered(for: "flash_sale"))
        XCTAssertFalse(registryB.isRegistered(for: "flash_sale"))
    }

    // MARK: - Safe registration

    func testEmptyRendererRegistrationIsSafe() {
        let registry = HomeSectionRendererRegistry.default
            .registering(type: "empty_widget") { _ in
                EmptyView()
            }

        _ = registry.view(for: composedSection(type: .unknown("empty_widget")))
        XCTAssertTrue(registry.isRegistered(for: "empty_widget"))
    }

    // MARK: - HomeComposerView compatibility

    func testHomeComposerViewPreservesExistingInitializerBehavior() {
        let context = HomeRenderContextBuilder().makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        _ = HomeComposerView(context: context)
        _ = HomeComposerView(
            context: context,
            rendererRegistry: HomeSectionRendererRegistry.default
        )
    }

    func testUnknownBackendTypeDecodesAndComposesSafely() throws {
        let section = try JSONDecoder().decode(
            HomeSection.self,
            from: Data("""
            {
                "id": "flash-1",
                "type": "flash_sale",
                "title": "Flash Sale",
                "order": 0,
                "isEnabled": true
            }
            """.utf8)
        )

        XCTAssertEqual(section.type, .unknown("flash_sale"))

        let composed = HomeComposer().compose(
            HomePage(id: "home", version: "1.0", sections: [section])
        )
        XCTAssertEqual(composed.count, 1)
        XCTAssertEqual(composed[0].type, .unknown("flash_sale"))
    }

    // MARK: - Helpers

    private func composedSection(
        id: String = "section-1",
        type: HomeSectionType,
        title: String? = nil
    ) -> ComposedHomeSection {
        ComposedHomeSection(
            id: id,
            type: type,
            title: title,
            order: 0
        )
    }
}
