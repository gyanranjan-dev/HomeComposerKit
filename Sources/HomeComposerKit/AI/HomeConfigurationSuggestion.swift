import Foundation

/// Structured home configuration produced by an external AI provider.
///
/// Contains only ``HomePage`` configuration data — never executable code or
/// SwiftUI source. The host's ``HomeAIProvider`` implementation is responsible
/// for translating model output into this type.
public struct HomeConfigurationSuggestion: Sendable {

    /// Generated home page configuration.
    public let homePage: HomePage

    /// Concise, user-facing summary of what was generated.
    ///
    /// This must not contain private chain-of-thought or internal reasoning.
    public let explanation: String?

    /// Optional provider confidence score in the range `0...1`.
    public let confidence: Double?

    /// Optional user-facing warnings returned by the provider before validation.
    public let providerWarnings: [String]

    public init(
        homePage: HomePage,
        explanation: String? = nil,
        confidence: Double? = nil,
        providerWarnings: [String] = []
    ) {
        self.homePage = homePage
        self.explanation = explanation
        self.confidence = confidence
        self.providerWarnings = providerWarnings
    }
}

/// Result of generating and validating an AI home configuration suggestion.
public struct HomeAIConfigurationResult: Sendable {

    /// The provider-generated suggestion.
    public let suggestion: HomeConfigurationSuggestion

    /// Structural validation outcome from ``HomePageValidator``.
    public let validationResult: HomeValidationResult

    /// Generated home page configuration.
    public var homePage: HomePage {
        suggestion.homePage
    }

    /// Concise user-facing summary from the provider, if any.
    public var explanation: String? {
        suggestion.explanation
    }

    /// `true` when validation produced no error-severity diagnostics.
    public var isValid: Bool {
        validationResult.isValid
    }

    /// Combined provider warnings and validation diagnostics suitable for display.
    public var allWarnings: [String] {
        var warnings = suggestion.providerWarnings
        warnings.append(contentsOf: validationResult.warnings.map(\.message))
        return warnings
    }

    public init(
        suggestion: HomeConfigurationSuggestion,
        validationResult: HomeValidationResult
    ) {
        self.suggestion = suggestion
        self.validationResult = validationResult
    }
}
