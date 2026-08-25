import XCTest
@testable import HomeComposerKit

final class HomeComposerKitTests: XCTestCase {

    func testMockHomePageHasSections() {
        let homePage = MockHomePage.sample

        XCTAssertEqual(homePage.id, "home-001")
        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertEqual(homePage.title, "Discover")
        XCTAssertFalse(homePage.sections.isEmpty)
    }

    func testMockSectionSamplesArePopulated() {
        XCTAssertFalse(MockHomePage.sampleBannerSection.banners.isEmpty)
        XCTAssertFalse(MockHomePage.sampleCategorySection.categories.isEmpty)
        XCTAssertFalse(MockHomePage.sampleProductSection.products.isEmpty)
        XCTAssertFalse(MockHomePage.sampleLiveSection.streams.isEmpty)
        XCTAssertFalse(MockHomePage.sampleSocialSection.posts.isEmpty)
    }
}
