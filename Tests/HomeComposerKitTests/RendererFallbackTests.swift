import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class RendererFallbackTests: XCTestCase {

    func testUnsupportedRendererFallsBackWithoutCrashing() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "flash",
            type: .unknown("flash_sale_v2"),
            order: 0
        )

        XCTAssertFalse(registry.isRegistered(for: .unknown("flash_sale_v2")))

        let view = registry.view(for: section)
        _ = view
        // Unregistered types return EmptyView — no runtime failure.
    }

    func testHostCanRegisterUnknownSectionRenderer() {
        let registry = HomeSectionRendererRegistry.makeDefault()
            .registering(.unknown("flash_sale_v2")) { section in
                Text(section.id)
            }

        XCTAssertTrue(registry.isRegistered(for: .unknown("flash_sale_v2")))
        XCTAssertTrue(registry.isRegistered(for: .banner))
    }

    func testKnownTypesWithoutBuiltInRenderersFallBackSafely() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let unregisteredBuiltIns: [HomeSectionType] = [
            .recentlyViewed,
            .recommendations,
            .custom
        ]

        for type in unregisteredBuiltIns {
            XCTAssertFalse(
                registry.isRegistered(for: type),
                "\(type.rawValue) should not have a built-in renderer"
            )
            _ = registry.view(
                for: ComposedHomeSection(id: type.rawValue, type: type, order: 0)
            )
        }
    }

    func testFallbackIsDeterministicForRepeatedLookups() {
        let registry = HomeSectionRendererRegistry.makeDefault()
        let section = ComposedHomeSection(
            id: "x",
            type: .unknown("future_widget"),
            order: 0
        )

        XCTAssertFalse(registry.isRegistered(for: section.type))
        _ = registry.view(for: section)
        _ = registry.view(for: section)
        XCTAssertFalse(registry.isRegistered(for: section.type))
    }
}
