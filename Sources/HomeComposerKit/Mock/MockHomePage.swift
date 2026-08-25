import Foundation

/// Sample home page data for previews, tests, and development.
public enum MockHomePage {

    public static let sample: HomePage = HomePage(
        id: "home-001",
        version: "1.0",
        title: "Discover",
        sections: [
            HomeSection(
                id: "section-banner",
                type: .banner,
                title: "Featured",
                order: 0,
                isEnabled: true,
                configuration: SectionConfiguration(
                    layout: "carousel",
                    limit: 5,
                    columns: 1,
                    spacing: 8.0
                )
            ),
            HomeSection(
                id: "section-categories",
                type: .categories,
                title: "Shop by Category",
                order: 1,
                isEnabled: true,
                configuration: SectionConfiguration(
                    layout: "horizontal",
                    limit: 10,
                    columns: 4,
                    spacing: 12.0
                )
            ),
            HomeSection(
                id: "section-products",
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
            ),
            HomeSection(
                id: "section-live",
                type: .liveStream,
                title: "Live Now",
                order: 3,
                isEnabled: true
            ),
            HomeSection(
                id: "section-social",
                type: .social,
                title: "Community",
                order: 4,
                isEnabled: true
            )
        ]
    )

    public static let sampleBannerSection = BannerSection(
        banners: [
            Banner(
                id: "banner-001",
                title: "Summer Sale",
                subtitle: "Up to 50% off",
                imageURL: URL(string: "https://example.com/banner.jpg")!,
                action: BannerAction(
                    title: "Shop Now",
                    destination: "app://sale/summer"
                )
            )
        ]
    )

    public static let sampleCategorySection = CategorySection(
        categories: [
            Category(
                id: "cat-electronics",
                name: "Electronics",
                imageURL: URL(string: "https://example.com/electronics.jpg")
            ),
            Category(
                id: "cat-fashion",
                name: "Fashion",
                imageURL: URL(string: "https://example.com/fashion.jpg")
            )
        ]
    )

    public static let sampleProductSection = ProductSection(
        products: [
            Product(
                id: "prod-001",
                name: "Wireless Headphones",
                description: "Premium noise-cancelling headphones",
                imageURL: URL(string: "https://example.com/headphones.jpg"),
                price: Decimal(string: "199.99")!,
                currency: "USD",
                isFavorite: true,
                categoryID: "cat-electronics"
            )
        ]
    )

    public static let sampleLiveSection = LiveSection(
        streams: [
            LiveStream(
                id: "live-001",
                title: "Product Launch",
                streamURL: URL(string: "https://example.com/stream.m3u8"),
                thumbnailURL: URL(string: "https://example.com/thumb.jpg"),
                isLive: true
            )
        ]
    )

    public static let sampleSocialSection = SocialSection(
        posts: [
            SocialPost(
                id: "post-001",
                author: "Jane Doe",
                content: "Just got my new headphones!",
                imageURL: URL(string: "https://example.com/post.jpg")
            )
        ]
    )
}
