import Foundation

/// Orchestrates AI-generated home configuration through provider injection and
/// mandatory validation.
///
/// The engine performs no networking and holds no API credentials. It accepts a
/// host-supplied ``HomeAIProvider``, validates the returned ``HomePage`` with
/// ``HomePageValidator``, and returns a safe ``HomeAIConfigurationResult``.
///
/// ```swift
/// let engine = HomeAIConfigurationEngine(provider: myAIProvider)
/// let result = try await engine.generate(
///     from: HomeConfigurationIntent(prompt: "Create a modern homepage")
/// )
/// let homePage = result.homePage
/// ```
public struct HomeAIConfigurationEngine: Sendable {

    private let provider: any HomeAIProvider
    private let validator: HomePageValidator

    /// Creates an engine with an injected AI provider.
    ///
    /// - Parameters:
    ///   - provider: Host implementation that performs AI inference and returns
    ///     structured ``HomePage`` configuration.
    ///   - validator: Validator applied to every provider result. Defaults to
    ///     ``HomePageValidator``.
    public init(
        provider: any HomeAIProvider,
        validator: HomePageValidator = HomePageValidator()
    ) {
        self.provider = provider
        self.validator = validator
    }

    /// Generates a home configuration from intent and validates it before returning.
    ///
    /// Provider errors propagate to the caller. Validation never crashes; invalid
    /// configurations are reported through ``HomeAIConfigurationResult/validationResult``.
    public func generate(
        from intent: HomeConfigurationIntent
    ) async throws -> HomeAIConfigurationResult {
        let suggestion = try await provider.generateSuggestion(from: intent)
        let validationResult = validator.validate(suggestion.homePage)
        return HomeAIConfigurationResult(
            suggestion: suggestion,
            validationResult: validationResult
        )
    }
}
