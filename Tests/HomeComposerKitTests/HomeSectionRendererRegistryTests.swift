import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class HomeSectionRendererRegistryTests: XCTestCase {

    func testDefaultRegistryRegistersBuiltInSectionTypes() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .categories))
        XCTAssertTrue(registry.isRegistered(for: .products))
        XCTAssertTrue(registry.isRegistered(for: .popularProducts))
        XCTAssertTrue(registry.isRegistered(for: .favoriteProducts))
        XCTAssertTrue(registry.isRegistered(for: .liveStream))
        XCTAssertTrue(registry.isRegistered(for: .social))
    }

    func testDefaultRegistryDoesNotRegisterUnsupportedTypes() {
        let registry = HomeSectionRendererRegistry.makeDefault()

        XCTAssertFalse(registry.isRegistered(for: .recentlyViewed))
        XCTAssertFalse(registry.isRegistered(for: .recommendations))
        XCTAssertFalse(registry.isRegistered(for: .custom))
    }

    func testHostCanRegisterCustomRendererWithoutReplacingBuiltIns() {
        var registry = HomeSectionRendererRegistry.makeDefault()
        registry.register(.custom) { section in
            Text(section.id)
        }

        XCTAssertTrue(registry.isRegistered(for: .custom))
        XCTAssertTrue(registry.isRegistered(for: .banner))
        XCTAssertTrue(registry.isRegistered(for: .products))
    }

    func testRegisterReplacesExistingMapping() {
        var registry = HomeSectionRendererRegistry.makeDefault()
        XCTAssertTrue(registry.isRegistered(for: .banner))

        registry.register(.banner) { section in
            Text("Override \(section.id)")
        }

        XCTAssertTrue(registry.isRegistered(for: .banner))
    }
}
