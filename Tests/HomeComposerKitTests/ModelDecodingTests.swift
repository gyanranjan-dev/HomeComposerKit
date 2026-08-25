import Foundation
import XCTest
@testable import HomeComposerKit

final class ModelDecodingTests: XCTestCase {

    // MARK: - HomePage

    func testDecodingHomePageFromJSON() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "title": "Discover",
            "sections": [
                {
                    "id": "section-001",
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
                }
            ]
        }
        """.data(using: .utf8)!

        let homePage = try JSONDecoder().decode(HomePage.self, from: json)

        XCTAssertEqual(homePage.id, "home-001")
        XCTAssertEqual(homePage.version, "1.0")
        XCTAssertEqual(homePage.title, "Discover")
        XCTAssertEqual(homePage.sections.count, 1)
        XCTAssertEqual(homePage.sections[0].id, "section-001")
    }

    func testHomePageRoundTrip() throws {
        let homePage = MockHomePage.sample
        let data = try JSONEncoder().encode(homePage)
        let decoded = try JSONDecoder().decode(HomePage.self, from: data)

        XCTAssertEqual(decoded.id, homePage.id)
        XCTAssertEqual(decoded.version, homePage.version)
        XCTAssertEqual(decoded.title, homePage.title)
        XCTAssertEqual(decoded.sections.count, homePage.sections.count)
    }

    // MARK: - HomeSection

    func testDecodingHomeSectionFromJSON() throws {
        let json = """
        {
            "id": "section-001",
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
        """.data(using: .utf8)!

        let section = try JSONDecoder().decode(HomeSection.self, from: json)

        XCTAssertEqual(section.id, "section-001")
        XCTAssertEqual(section.type, .products)
        XCTAssertEqual(section.title, "Trending")
        XCTAssertEqual(section.order, 2)
        XCTAssertTrue(section.isEnabled)
        XCTAssertEqual(section.configuration?.layout, "grid")
        XCTAssertEqual(section.configuration?.limit, 10)
        XCTAssertEqual(section.configuration?.columns, 2)
        XCTAssertEqual(section.configuration?.spacing, 12.0)
    }

    func testHomeSectionRoundTrip() throws {
        let section = HomeSection(
            id: "section-001",
            type: .products,
            title: "Trending",
            order: 2,
            isEnabled: true,
            configuration: SectionConfiguration(
                layout: "grid",
                limit: 10,
                columns: 2,
                spacing: 12.0
            )
        )

        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(HomeSection.self, from: data)

        XCTAssertEqual(decoded.id, section.id)
        XCTAssertEqual(decoded.type, section.type)
        XCTAssertEqual(decoded.title, section.title)
        XCTAssertEqual(decoded.order, section.order)
        XCTAssertEqual(decoded.isEnabled, section.isEnabled)
        XCTAssertEqual(decoded.configuration?.layout, section.configuration?.layout)
    }

    // MARK: - Product

    func testDecodingProductFromJSON() throws {
        let json = """
        {
            "id": "prod-001",
            "name": "Wireless Headphones",
            "description": "Premium noise-cancelling headphones",
            "imageURL": "https://example.com/headphones.jpg",
            "price": 199.99,
            "currency": "USD",
            "isFavorite": true,
            "categoryID": "cat-electronics"
        }
        """.data(using: .utf8)!

        let product = try JSONDecoder().decode(Product.self, from: json)

        XCTAssertEqual(product.id, "prod-001")
        XCTAssertEqual(product.name, "Wireless Headphones")
        XCTAssertEqual(product.description, "Premium noise-cancelling headphones")
        XCTAssertEqual(product.imageURL?.absoluteString, "https://example.com/headphones.jpg")
        XCTAssertEqual(product.price, Decimal(string: "199.99"))
        XCTAssertEqual(product.currency, "USD")
        XCTAssertTrue(product.isFavorite)
        XCTAssertEqual(product.categoryID, "cat-electronics")
    }

    func testProductSectionRoundTrip() throws {
        let section = MockHomePage.sampleProductSection
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(ProductSection.self, from: data)

        XCTAssertEqual(decoded.products.count, section.products.count)
        XCTAssertEqual(decoded.products[0].id, section.products[0].id)
    }

    // MARK: - Banner

    func testDecodingBannerFromJSON() throws {
        let json = """
        {
            "id": "banner-001",
            "title": "Summer Sale",
            "subtitle": "Up to 50% off",
            "imageURL": "https://example.com/banner.jpg",
            "action": {
                "title": "Shop Now",
                "destination": "app://sale/summer"
            }
        }
        """.data(using: .utf8)!

        let banner = try JSONDecoder().decode(Banner.self, from: json)

        XCTAssertEqual(banner.id, "banner-001")
        XCTAssertEqual(banner.title, "Summer Sale")
        XCTAssertEqual(banner.subtitle, "Up to 50% off")
        XCTAssertEqual(banner.imageURL.absoluteString, "https://example.com/banner.jpg")
        XCTAssertEqual(banner.action?.title, "Shop Now")
        XCTAssertEqual(banner.action?.destination, "app://sale/summer")
    }

    func testBannerSectionRoundTrip() throws {
        let section = MockHomePage.sampleBannerSection
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(BannerSection.self, from: data)

        XCTAssertEqual(decoded.banners.count, section.banners.count)
        XCTAssertEqual(decoded.banners[0].id, section.banners[0].id)
    }

    // MARK: - Category

    func testCategorySectionRoundTrip() throws {
        let section = MockHomePage.sampleCategorySection
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(CategorySection.self, from: data)

        XCTAssertEqual(decoded.categories.count, section.categories.count)
        XCTAssertEqual(decoded.categories[0].id, section.categories[0].id)
    }

    // MARK: - Live

    func testLiveSectionRoundTrip() throws {
        let section = MockHomePage.sampleLiveSection
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(LiveSection.self, from: data)

        XCTAssertEqual(decoded.streams.count, section.streams.count)
        XCTAssertEqual(decoded.streams[0].id, section.streams[0].id)
        XCTAssertTrue(decoded.streams[0].isLive)
    }

    // MARK: - Social

    func testSocialSectionRoundTrip() throws {
        let section = MockHomePage.sampleSocialSection
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(SocialSection.self, from: data)

        XCTAssertEqual(decoded.posts.count, section.posts.count)
        XCTAssertEqual(decoded.posts[0].author, section.posts[0].author)
    }
}
