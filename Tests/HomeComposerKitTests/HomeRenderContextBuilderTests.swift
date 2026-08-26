import Foundation
import XCTest
@testable import HomeComposerKit

final class HomeRenderContextBuilderTests: XCTestCase {

    private let builder = HomeRenderContextBuilder()
    private let composer = HomeComposer()

    func testMakeContextFromDataAttachesContent() throws {
        let data = try JSONEncoder().encode(MockHomePage.sample)

        let context = try builder.makeContext(
            from: data,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(context.homePage.id, MockHomePage.sample.id)
        XCTAssertEqual(context.contentBySectionID.count, MockHomePage.sampleContent.count)
        XCTAssertNotNil(context.contentBySectionID["section-banner"])
    }

    func testMakeContextFromString() throws {
        let json = String(data: try JSONEncoder().encode(MockHomePage.sample), encoding: .utf8)!

        let context = try builder.makeContext(
            from: json,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(context.homePage.title, "Discover")
        XCTAssertFalse(context.homePage.sections.isEmpty)
    }

    func testMakeContextFromExistingHomePage() {
        let context = builder.makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        XCTAssertEqual(context.homePage.id, "home-001")
        XCTAssertEqual(
            context.contentBySectionID.keys.sorted(),
            MockHomePage.sampleContent.keys.sorted()
        )
    }

    func testContextFeedsComposerWithSectionContent() throws {
        let context = try builder.makeContext(
            from: JSONEncoder().encode(MockHomePage.sample),
            contentBySectionID: MockHomePage.sampleContent
        )

        let composed = composer.compose(
            context.homePage,
            contentBySectionID: context.contentBySectionID
        )

        XCTAssertEqual(composed.count, MockHomePage.sample.sections.count)
        XCTAssertEqual(composed.first?.type, .banner)
        XCTAssertNotNil(composed.first?.content)

        if case .banner(let banners) = composed.first?.content {
            XCTAssertFalse(banners.banners.isEmpty)
        } else {
            XCTFail("Expected banner content on the first composed section")
        }
    }

    func testInvalidJSONDoesNotProduceContext() {
        XCTAssertThrowsError(
            try builder.makeContext(from: Data("not-json".utf8))
        ) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
