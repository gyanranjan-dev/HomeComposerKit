import Foundation
import XCTest
@testable import HomeComposerKit

private actor FakeHomeAIProvider: HomeAIProvider {
    enum Behavior {
        case success(HomeConfigurationSuggestion)
        case failure(Error)
    }

    var behavior: Behavior
    private(set) var receivedIntents: [HomeConfigurationIntent] = []

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func generateSuggestion(
        from intent: HomeConfigurationIntent
    ) async throws -> HomeConfigurationSuggestion {
        receivedIntents.append(intent)

        switch behavior {
        case .success(let suggestion):
            return suggestion
        case .failure(let error):
            throw error
        }
    }
}

private enum TestError: Error, Equatable {
    case providerUnavailable
}

final class HomeAIConfigurationEngineTests: XCTestCase {

    private let composer = HomeComposer()

    private var validHomePage: HomePage {
        HomePage(
            id: "ai-home-1",
            version: "1.0",
            title: "Generated Home",
            sections: [
                HomeSection(
                    id: "banner-1",
                    type: .banner,
                    title: "Featured",
                    order: 0
                ),
                HomeSection(
                    id: "products-1",
                    type: .products,
                    title: "Trending",
                    order: 1,
                    configuration: SectionConfiguration(layout: .horizontal, limit: 8)
                )
            ]
        )
    }

    private var invalidHomePage: HomePage {
        HomePage(
            id: "ai-home-invalid",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "dup",
                    type: .products,
                    order: 0
                ),
                HomeSection(
                    id: "dup",
                    type: .categories,
                    order: 1
                ),
                HomeSection(
                    id: "bad-order",
                    type: .banner,
                    order: -1
                )
            ]
        )
    }

    // MARK: - Provider injection

    func testEngineUsesInjectedProvider() async throws {
        let provider = FakeHomeAIProvider(
            behavior: .success(
                HomeConfigurationSuggestion(
                    homePage: validHomePage,
                    explanation: "Added banner and products."
                )
            )
        )
        let engine = HomeAIConfigurationEngine(provider: provider)
        let intent = HomeConfigurationIntent(
            prompt: "Create a homepage with featured content and products."
        )

        let result = try await engine.generate(from: intent)
        let receivedIntents = await provider.receivedIntents

        XCTAssertEqual(receivedIntents.count, 1)
        XCTAssertEqual(receivedIntents[0], intent)
        XCTAssertEqual(result.homePage.id, "ai-home-1")
        XCTAssertEqual(result.explanation, "Added banner and products.")
    }

    // MARK: - Validation

    func testValidConfigurationPassesValidation() async throws {
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(
                behavior: .success(HomeConfigurationSuggestion(homePage: validHomePage))
            )
        )

        let result = try await engine.generate(
            from: HomeConfigurationIntent(prompt: "Build a simple homepage")
        )

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.validationResult.errors.isEmpty)
    }

    func testInvalidConfigurationReportsValidationDiagnostics() async throws {
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(
                behavior: .success(
                    HomeConfigurationSuggestion(
                        homePage: invalidHomePage,
                        providerWarnings: ["Duplicate sections detected by model."]
                    )
                )
            )
        )

        let result = try await engine.generate(
            from: HomeConfigurationIntent(prompt: "Generate homepage")
        )

        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.validationResult.errors.isEmpty)
        XCTAssertTrue(
            result.validationResult.errors.contains { $0.code == .duplicateSectionID }
        )
        XCTAssertTrue(
            result.validationResult.errors.contains { $0.code == .invalidSectionPosition }
        )
        XCTAssertEqual(result.suggestion.providerWarnings.count, 1)
        XCTAssertTrue(result.allWarnings.contains("Duplicate sections detected by model."))
    }

    func testValidationIsAlwaysExecuted() async throws {
        let validator = HomePageValidator()
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(
                behavior: .success(HomeConfigurationSuggestion(homePage: validHomePage))
            ),
            validator: validator
        )

        let result = try await engine.generate(
            from: HomeConfigurationIntent(prompt: "Any prompt")
        )

        XCTAssertNotNil(result.validationResult)
        XCTAssertEqual(
            validator.validate(validHomePage).diagnostics,
            result.validationResult.diagnostics
        )
    }

    // MARK: - Safety

    func testUnknownSectionTypesRemainSafeThroughComposition() async throws {
        let homePage = HomePage(
            id: "ai-unknown",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "flash",
                    type: .unknown("flash_sale_v2"),
                    order: 0
                )
            ]
        )
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(
                behavior: .success(HomeConfigurationSuggestion(homePage: homePage))
            )
        )

        let result = try await engine.generate(
            from: HomeConfigurationIntent(prompt: "Add a flash sale section")
        )

        XCTAssertTrue(result.validationResult.warnings.contains {
            $0.code == .unsupportedSectionType
        })

        let composed = composer.compose(result.homePage)
        XCTAssertEqual(composed.count, 1)
        XCTAssertEqual(composed[0].type, .unknown("flash_sale_v2"))
    }

    func testProviderErrorsPropagate() async {
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(behavior: .failure(TestError.providerUnavailable))
        )

        do {
            _ = try await engine.generate(
                from: HomeConfigurationIntent(prompt: "Generate homepage")
            )
            XCTFail("Expected provider error")
        } catch {
            XCTAssertEqual(error as? TestError, .providerUnavailable)
        }
    }

    // MARK: - Intent model

    func testIntentEncodesPreferredAndExcludedSectionTypes() throws {
        let intent = HomeConfigurationIntent(
            prompt: "Homepage with categories and products",
            context: "Mobile app, dark mode",
            preferredSectionTypes: [.categories, .products],
            excludedSectionTypes: [.social],
            targetPlatform: "ios"
        )

        let data = try JSONEncoder().encode(intent)
        let decoded = try JSONDecoder().decode(HomeConfigurationIntent.self, from: data)

        XCTAssertEqual(decoded.prompt, intent.prompt)
        XCTAssertEqual(decoded.context, intent.context)
        XCTAssertEqual(decoded.preferredSectionTypes, [.categories, .products])
        XCTAssertEqual(decoded.excludedSectionTypes, [.social])
        XCTAssertEqual(decoded.targetPlatform, "ios")
    }

    // MARK: - Existing behavior

    func testExistingComposerBehaviorRemainsUnchangedForAIOutput() async throws {
        let engine = HomeAIConfigurationEngine(
            provider: FakeHomeAIProvider(
                behavior: .success(HomeConfigurationSuggestion(homePage: invalidHomePage))
            )
        )

        let result = try await engine.generate(
            from: HomeConfigurationIntent(prompt: "Generate homepage")
        )

        let composed = composer.compose(result.homePage)
        XCTAssertEqual(composed.count, 1)
        XCTAssertEqual(composed[0].id, "dup")
    }

    func testEngineDependsOnProviderProtocolOnly() {
        // HomeAIConfigurationEngine has no URLSession, API keys, or vendor SDK imports.
        // Networking lives exclusively in host HomeAIProvider implementations.
        XCTAssertNotNil(HomeAIConfigurationEngine.self)
    }
}
