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
                id: "section-popular",
                type: .popularProducts,
                title: "Popular",
                order: 3,
                isEnabled: true,
                configuration: SectionConfiguration(
                    layout: "horizontal",
                    limit: 8,
                    columns: 2,
                    spacing: 12.0
                )
            ),
            HomeSection(
                id: "section-favorites",
                type: .favoriteProducts,
                title: "Favorites",
                order: 4,
                isEnabled: true,
                configuration: SectionConfiguration(
                    layout: "horizontal",
                    limit: 8,
                    columns: 2,
                    spacing: 12.0
                )
            ),
            HomeSection(
                id: "section-live",
                type: .liveStream,
                title: "Live Now",
                order: 5,
                isEnabled: true
            ),
            HomeSection(
                id: "section-social",
                type: .social,
                title: "Community",
                order: 6,
                isEnabled: true
            )
        ]
    )

    /// Section payloads keyed by section `id`, matching `sample`.
    public static let sampleContent: [String: HomeSectionContent] = [
        "section-banner": .banner(sampleBannerSection),
        "section-categories": .categories(sampleCategorySection),
        "section-products": .products(sampleProductSection),
        "section-popular": .popularProducts(samplePopularProductSection),
        "section-favorites": .favoriteProducts(sampleFavoritesSection),
        "section-live": .live(sampleLiveSection),
        "section-social": .social(sampleSocialSection)
    ]

    public static let sampleBannerSection = BannerSection(
        banners: [
            Banner(
                id: "banner-001",
                title: "Summer Sale",
                subtitle: "Up to 50% off selected items",
                imageURL: URL(string: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=1200")!,
                action: BannerAction(
                    title: "Shop Now",
                    destination: "app://sale/summer"
                )
            ),
            Banner(
                id: "banner-002",
                title: "New Arrivals",
                subtitle: "Fresh picks for the season",
                imageURL: URL(string: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200")!,
                action: BannerAction(
                    title: "Explore",
                    destination: "app://new-arrivals"
                )
            )
        ]
    )

    public static let sampleCategorySection = CategorySection(
        categories: [
            Category(
                id: "cat-electronics",
                name: "Electronics",
                imageURL: URL(string: "https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400")
            ),
            Category(
                id: "cat-fashion",
                name: "Fashion",
                imageURL: URL(string: "https://images.unsplash.com/photo-1445205170230-053b83016050?w=400")
            ),
            Category(
                id: "cat-home",
                name: "Home",
                imageURL: URL(string: "https://images.unsplash.com/photo-1484101403633-562f39ee8481?w=400")
            ),
            Category(
                id: "cat-sports",
                name: "Sports",
                imageURL: URL(string: "https://images.unsplash.com/photo-1461896836934-ffe607ba6851?w=400")
            )
        ]
    )

    public static let sampleProductSection = ProductSection(
        products: [
            Product(
                id: "prod-001",
                name: "Wireless Headphones",
                description: "Premium noise-cancelling headphones",
                imageURL: URL(string: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400"),
                price: Decimal(string: "199.99")!,
                currency: "USD",
                isFavorite: true,
                categoryID: "cat-electronics"
            ),
            Product(
                id: "prod-002",
                name: "Leather Backpack",
                description: "Everyday carry backpack",
                imageURL: URL(string: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400"),
                price: Decimal(string: "129.00")!,
                currency: "USD",
                isFavorite: false,
                categoryID: "cat-fashion"
            ),
            Product(
                id: "prod-003",
                name: "Ceramic Mug Set",
                description: "Set of 4 handmade mugs",
                imageURL: URL(string: "https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=400"),
                price: Decimal(string: "48.50")!,
                currency: "USD",
                isFavorite: false,
                categoryID: "cat-home"
            )
        ]
    )

    public static let samplePopularProductSection = ProductSection(
        products: [
            Product(
                id: "prod-101",
                name: "Running Shoes",
                description: "Lightweight daily trainers",
                imageURL: URL(string: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400"),
                price: Decimal(string: "110.00")!,
                currency: "USD",
                isFavorite: false,
                categoryID: "cat-sports"
            ),
            Product(
                id: "prod-102",
                name: "Smart Watch",
                description: "Fitness tracking watch",
                imageURL: URL(string: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400"),
                price: Decimal(string: "249.00")!,
                currency: "USD",
                isFavorite: true,
                categoryID: "cat-electronics"
            )
        ]
    )

    public static let sampleFavoritesSection = ProductSection(
        products: sampleProductSection.products.filter(\.isFavorite) +
            samplePopularProductSection.products.filter(\.isFavorite)
    )

    public static let sampleLiveSection = LiveSection(
        streams: [
            LiveStream(
                id: "live-001",
                title: "Product Launch",
                streamURL: URL(string: "https://example.com/stream.m3u8"),
                thumbnailURL: URL(string: "https://images.unsplash.com/photo-1475724017904-b712052c192a?w=400"),
                isLive: true
            ),
            LiveStream(
                id: "live-002",
                title: "Style Session",
                streamURL: URL(string: "https://example.com/style.m3u8"),
                thumbnailURL: URL(string: "https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=400"),
                isLive: true
            )
        ]
    )

    public static let sampleSocialSection = SocialSection(
        posts: [
            SocialPost(
                id: "post-001",
                author: "Alex Rivera",
                content: "Just got my new headphones!",
                imageURL: URL(string: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400")
            ),
            SocialPost(
                id: "post-002",
                author: "Sam Chen",
                content: "Weekend wardrobe refresh",
                imageURL: URL(string: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400")
            )
        ]
    )
}
