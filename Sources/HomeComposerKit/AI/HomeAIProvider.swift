import Foundation

/// External AI provider that converts a ``HomeConfigurationIntent`` into structured
/// home configuration.
///
/// **HomeComposerKit does not ship a vendor implementation.** The host application
/// owns networking, credentials, model selection, rate limits, and retries.
///
/// Implementations must return ``HomePage`` configuration only. They must not
/// generate or execute arbitrary Swift, SwiftUI, or other executable code.
public protocol HomeAIProvider: Sendable {

    /// Generates a structured home configuration suggestion from natural language intent.
    func generateSuggestion(
        from intent: HomeConfigurationIntent
    ) async throws -> HomeConfigurationSuggestion
}
