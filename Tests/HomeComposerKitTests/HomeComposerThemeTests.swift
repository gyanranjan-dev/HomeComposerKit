import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class HomeComposerThemeTests: XCTestCase {

    // MARK: - Default theme

    func testDefaultSpacingScaleValues() {
        let spacing = HomeSpacing.default

        XCTAssertEqual(spacing.compact, 4)
        XCTAssertEqual(spacing.small, 8)
        XCTAssertEqual(spacing.medium, 12)
        XCTAssertEqual(spacing.large, 16)
        XCTAssertEqual(spacing.extraLarge, 24)
    }

    func testDefaultCornerRadiusValues() {
        let radius = HomeCornerRadius.default

        XCTAssertEqual(radius.small, 12)
        XCTAssertEqual(radius.medium, 14)
        XCTAssertEqual(radius.large, 16)
    }

    func testDefaultThemeLayoutValues() {
        let theme = HomeComposerTheme.default

        XCTAssertEqual(theme.sectionSpacing, HomeSpacing.default.extraLarge)
        XCTAssertEqual(theme.horizontalContentPadding, HomeSpacing.default.large)
        XCTAssertEqual(theme.cardSpacing, HomeSpacing.default.small)
        XCTAssertEqual(theme.cardPadding, 10)
        XCTAssertEqual(theme.headerSpacing, 2)
        XCTAssertEqual(theme.spacing, .default)
        XCTAssertEqual(theme.cornerRadius, .default)
    }

    // MARK: - Custom theme

    func testCustomThemeOverridesLayoutValues() {
        let spacing = HomeSpacing(
            compact: 2,
            small: 6,
            medium: 10,
            large: 14,
            extraLarge: 20
        )
        let cornerRadius = HomeCornerRadius(small: 8, medium: 10, large: 12)
        let typography = HomeTypography(
            pageTitle: .title.bold(),
            sectionTitle: .headline,
            body: .body,
            caption: .footnote,
            price: .body,
            emphasis: .headline
        )

        let theme = HomeComposerTheme(
            backgroundColor: .blue,
            cardBackgroundColor: .green,
            placeholderBackgroundColor: .gray,
            spacing: spacing,
            cornerRadius: cornerRadius,
            typography: typography,
            sectionSpacing: 32,
            horizontalContentPadding: 18,
            cardSpacing: 6,
            cardPadding: 12,
            headerSpacing: 4
        )

        XCTAssertEqual(theme.sectionSpacing, 32)
        XCTAssertEqual(theme.horizontalContentPadding, 18)
        XCTAssertEqual(theme.cardSpacing, 6)
        XCTAssertEqual(theme.cardPadding, 12)
        XCTAssertEqual(theme.headerSpacing, 4)
        XCTAssertEqual(theme.spacing.compact, 2)
        XCTAssertEqual(theme.cornerRadius.medium, 10)
    }

    func testCustomThemeCanBeInjectedIntoHomeComposerView() {
        let customTheme = HomeComposerTheme(
            backgroundColor: .purple,
            cardBackgroundColor: .orange,
            placeholderBackgroundColor: .gray,
            sectionSpacing: 28
        )

        _ = HomeComposerView(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent,
            theme: customTheme
        )
    }

    // MARK: - Backward compatibility

    func testHomeComposerViewInitializerRemainsCompatibleWithoutTheme() {
        _ = HomeComposerView(homePage: MockHomePage.sample)
        _ = HomeComposerView(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        let context = HomeRenderContextBuilder().makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        _ = HomeComposerView(context: context)
    }

    func testHomeComposerViewContextInitializerAcceptsTheme() {
        let context = HomeRenderContextBuilder().makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )

        _ = HomeComposerView(context: context, theme: .default)
    }

    // MARK: - Environment

    func testThemeEnvironmentDefaultMatchesDefaultTheme() {
        var environment = EnvironmentValues()
        XCTAssertEqual(
            environment.homeComposerTheme.sectionSpacing,
            HomeComposerTheme.default.sectionSpacing
        )
        XCTAssertEqual(
            environment.homeComposerTheme.horizontalContentPadding,
            HomeComposerTheme.default.horizontalContentPadding
        )
    }

    func testThemeEnvironmentCanBeOverridden() {
        let customTheme = HomeComposerTheme(
            backgroundColor: .indigo,
            cardBackgroundColor: .mint,
            placeholderBackgroundColor: .gray,
            sectionSpacing: 40
        )

        var environment = EnvironmentValues()
        environment.homeComposerTheme = customTheme

        XCTAssertEqual(environment.homeComposerTheme.sectionSpacing, 40)
    }

    // MARK: - Section rendering and layout configuration

    func testSectionRenderingStillWorksWithDefaultTheme() {
        let context = HomeRenderContextBuilder().makeContext(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
        let composed = context.compose()

        XCTAssertFalse(composed.isEmpty)

        _ = HomeComposerView(
            context: context,
            theme: .default
        )
    }

    func testLayoutConfigurationRemainsUnchangedWithTheme() {
        let bannerSection = MockHomePage.sample.sections.first { $0.id == "section-banner" }
        let banner = try? XCTUnwrap(bannerSection)
        let bannerConfiguration = try? XCTUnwrap(banner?.configuration)

        XCTAssertEqual(bannerConfiguration?.layout, .carousel)
        XCTAssertEqual(bannerConfiguration?.effectiveLayout(for: .banner), .carousel)
        XCTAssertEqual(bannerConfiguration?.effectiveSpacing, 8.0)

        let productSection = MockHomePage.sample.sections.first { $0.id == "section-products" }
        let products = try? XCTUnwrap(productSection)
        let productConfiguration = try? XCTUnwrap(products?.configuration)

        XCTAssertEqual(productConfiguration?.layout, .grid)
        XCTAssertEqual(productConfiguration?.effectiveLayout(for: .products), .grid)
        XCTAssertEqual(productConfiguration?.effectiveColumns(default: 2), 2)
    }
}
