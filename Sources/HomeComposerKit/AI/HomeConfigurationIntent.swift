import Foundation

/// A natural-language request for generating a structured home page configuration.
///
/// The prompt is opaque to the kit — any human language or instruction format
/// accepted by the host's ``HomeAIProvider`` implementation may be used.
public struct HomeConfigurationIntent: Codable, Sendable, Equatable {

    /// Primary instruction describing the desired home page layout or content.
    public let prompt: String

    /// Optional free-form context (locale, audience, brand guidelines, etc.).
    public let context: String?

    /// Section types the requester would like included when possible.
    public let preferredSectionTypes: [HomeSectionType]?

    /// Section types that should be omitted from the generated configuration.
    public let excludedSectionTypes: [HomeSectionType]?

    /// Optional target platform hint (for example `"ios"`, `"tv"`, `"web"`).
    public let targetPlatform: String?

    public init(
        prompt: String,
        context: String? = nil,
        preferredSectionTypes: [HomeSectionType]? = nil,
        excludedSectionTypes: [HomeSectionType]? = nil,
        targetPlatform: String? = nil
    ) {
        self.prompt = prompt
        self.context = context
        self.preferredSectionTypes = preferredSectionTypes
        self.excludedSectionTypes = excludedSectionTypes
        self.targetPlatform = targetPlatform
    }
}
