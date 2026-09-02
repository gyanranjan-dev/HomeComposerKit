import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

final class HomeAccessibilityTests: XCTestCase {

    private func sampleProduct(
        id: String = "prod-1",
        name: String = "Wireless Headphones",
        price: Decimal = 199.99,
        isFavorite: Bool = false
    ) -> Product {
        Product(
            id: id,
            name: name,
            price: price,
            currency: "USD",
            isFavorite: isFavorite
        )
    }

    // MARK: - Typography configuration

    func testSemanticTypographyRolesRemainAvailable() {
        let typography = HomeComposerTheme.default.typography

        XCTAssertNotNil(typography.pageTitle)
        XCTAssertNotNil(typography.sectionTitle)
        XCTAssertNotNil(typography.body)
        XCTAssertNotNil(typography.caption)
        XCTAssertNotNil(typography.price)
        XCTAssertNotNil(typography.emphasis)
    }

    // MARK: - Grid columns

    func testExplicitColumnBehaviorIsPreserved() {
        let configuration = SectionConfiguration(columns: 3)

        XCTAssertTrue(configuration.hasExplicitColumns)
        XCTAssertEqual(
            HomeAdaptiveLayout.gridColumnCount(
                configuredColumns: 3,
                defaultColumns: 2,
                horizontalSizeClass: .compact,
                dynamicTypeSize: .large
            ),
            3
        )
    }

    func testAdaptiveDefaultGridBehaviorUsesDefaultColumns() {
        let configuration = SectionConfiguration(columns: nil)

        XCTAssertFalse(configuration.hasExplicitColumns)
        XCTAssertEqual(
            configuration.adaptiveColumns(
                default: 2,
                horizontalSizeClass: .compact,
                dynamicTypeSize: .large
            ),
            2
        )
    }

    func testAdaptiveGridIncreasesOnRegularWidth() {
        let configuration = SectionConfiguration(columns: nil)

        XCTAssertEqual(
            configuration.adaptiveColumns(
                default: 2,
                horizontalSizeClass: .regular,
                dynamicTypeSize: .large
            ),
            4
        )
    }

    func testAdaptiveGridReducesForAccessibilityDynamicType() {
        let configuration = SectionConfiguration(columns: nil)

        XCTAssertEqual(
            configuration.adaptiveColumns(
                default: 2,
                horizontalSizeClass: .compact,
                dynamicTypeSize: .accessibility3
            ),
            1
        )
    }

    func testSectionConfigurationEffectiveColumnsBehaviorRemainsIntact() {
        let configuration = SectionConfiguration(columns: 2)
        XCTAssertEqual(configuration.effectiveColumns(), 2)
        XCTAssertEqual(configuration.effectiveColumns(default: 4), 2)

        let clamped = SectionConfiguration(columns: -1)
        XCTAssertEqual(clamped.effectiveColumns(default: 2), 1)
    }

    func testNegativeExplicitColumnsClampToOne() {
        XCTAssertEqual(
            HomeAdaptiveLayout.gridColumnCount(
                configuredColumns: -1,
                defaultColumns: 2,
                horizontalSizeClass: nil,
                dynamicTypeSize: .large
            ),
            1
        )
    }

    // MARK: - Accessibility labels

    func testProductAccessibilityLabelIncludesNameAndPrice() {
        let label = HomeAccessibilityLabels.product(
            sampleProduct(name: "Running Shoes", price: 110)
        )
        XCTAssertTrue(label.contains("Running Shoes"))
        XCTAssertTrue(label.contains("110"))
    }

    func testProductAccessibilityLabelIncludesFavorite() {
        let label = HomeAccessibilityLabels.product(
            sampleProduct(isFavorite: true)
        )
        XCTAssertTrue(label.contains("Favorite"))
    }

    func testCategoryAccessibilityLabelUsesName() {
        let label = HomeAccessibilityLabels.category(
            Category(id: "cat-1", name: "Electronics")
        )
        XCTAssertEqual(label, "Electronics")
    }

    func testBannerAccessibilityLabelCombinesAvailableFields() {
        let label = HomeAccessibilityLabels.banner(
            Banner(
                id: "b1",
                title: "Summer Sale",
                subtitle: "Up to 50% off",
                imageURL: URL(string: "https://example.com/banner.jpg")!,
                action: BannerAction(title: "Shop Now", destination: "app://sale")
            )
        )
        XCTAssertEqual(label, "Summer Sale, Up to 50% off, Shop Now")
    }

    func testBrandAccessibilityLabelUsesName() {
        let label = HomeAccessibilityLabels.brand(
            Brand(id: "brand-1", name: "Acme")
        )
        XCTAssertEqual(label, "Acme")
    }

    func testPromotionAccessibilityLabelCombinesAvailableFields() {
        let label = HomeAccessibilityLabels.promotion(
            Promotion(
                id: "promo-1",
                title: "Free Shipping",
                subtitle: "Orders over $50",
                action: PromotionAction(title: "Shop", destination: "https://example.com")
            )
        )
        XCTAssertEqual(label, "Free Shipping, Orders over $50, Shop")
    }

    func testLiveStreamAccessibilityLabelIncludesLivePrefix() {
        let label = HomeAccessibilityLabels.liveStream(
            LiveStream(
                id: "live-1",
                title: "Product Launch",
                streamURL: URL(string: "https://example.com/stream.m3u8"),
                isLive: true
            )
        )
        XCTAssertEqual(label, "Live: Product Launch")
    }

    func testSocialPostAccessibilityLabelIncludesAuthorAndContent() {
        let label = HomeAccessibilityLabels.socialPost(
            SocialPost(id: "post-1", author: "Alex", content: "Great product")
        )
        XCTAssertEqual(label, "Alex: Great product")
    }

    // MARK: - State view accessibility configuration

    func testEmptyStateAccessibilityLabelIncludesMessage() {
        let label = HomeAccessibilityLabels.emptyState(
            title: "No products",
            message: "Check back later"
        )
        XCTAssertEqual(label, "No products. Check back later")
    }

    func testErrorStateAccessibilityLabelIncludesRetryTitle() {
        let label = HomeAccessibilityLabels.errorState(
            title: "Unable to load",
            message: "Network unavailable",
            retryTitle: "Retry"
        )
        XCTAssertEqual(label, "Unable to load. Network unavailable. Retry")
    }

    // MARK: - Adaptive layout

    func testHorizontalItemMinWidthScalesForAccessibilityDynamicType() {
        let standard = HomeAdaptiveLayout.horizontalItemMinWidth(dynamicTypeSize: .large)
        let accessibility = HomeAdaptiveLayout.horizontalItemMinWidth(dynamicTypeSize: .accessibility2)
        XCTAssertGreaterThan(accessibility, standard)
    }

    func testBannerHeightScalesForAccessibilityDynamicType() {
        let standard = HomeAdaptiveLayout.bannerHeight(dynamicTypeSize: .large)
        let accessibility = HomeAdaptiveLayout.bannerHeight(dynamicTypeSize: .accessibility1)
        XCTAssertGreaterThan(accessibility, standard)
    }

    // MARK: - Backward compatibility

    func testPresentationConfigurationRemainsIntactWithDynamicTypeHelpers() {
        let section = ComposedHomeSection(
            id: "products-1",
            type: .products,
            title: "Trending",
            order: 0,
            configuration: SectionConfiguration(layout: .grid, columns: 2, spacing: 16)
        )

        XCTAssertEqual(section.effectiveLayout, .grid)
        XCTAssertEqual(section.effectiveSpacing, 16)
        XCTAssertEqual(section.effectiveColumns(default: 4), 2)
        XCTAssertEqual(section.configuredGridColumns, 2)
    }

    func testExistingActionTypesRemainIntact() {
        XCTAssertEqual(HomeAction.product(id: "p1").typeName, "product")
        XCTAssertEqual(HomeAction.category(id: "c1").typeName, "category")
        XCTAssertEqual(HomeAction.section(id: "s1").typeName, "section")
    }

    func testStep16SectionStateModelRemainsUnchanged() {
        XCTAssertEqual(HomeSectionState.loading, .loading)
        XCTAssertEqual(
            HomeSectionState.failed(HomeSectionFailure(message: "Error")),
            .failed(HomeSectionFailure(message: "Error"))
        )
    }

    func testStep16StateConfigurationDefaultsRemainAvailable() {
        XCTAssertEqual(HomeSectionStateConfiguration.default.error.retryTitle, "Retry")
    }
}
