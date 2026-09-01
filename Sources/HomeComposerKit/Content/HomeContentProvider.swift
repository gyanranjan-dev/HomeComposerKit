import Foundation

/// A host-side content reference that HomeComposerKit does not resolve itself.
public struct HomeContentRequest: Sendable, Hashable, Equatable {
    /// Opaque content reference (for example a cache key or API path).
    public let reference: String

    public init(reference: String) {
        self.reference = reference
    }
}

/// Host-injected content resolution for section payloads.
///
/// **HomeComposerKit does not fetch content.** The host application owns
/// networking, authentication, caching, and persistence.
public protocol HomeContentProviding: Sendable {
    func content(for request: HomeContentRequest) async throws -> HomeSectionContent?
}

/// Type-erased content provider for dependency injection.
public struct HomeContentProvider: HomeContentProviding, @unchecked Sendable {

    private let handler: (HomeContentRequest) async throws -> HomeSectionContent?

    /// Creates a provider from an async closure.
    public init(
        _ handler: @escaping (HomeContentRequest) async throws -> HomeSectionContent?
    ) {
        self.handler = handler
    }

    /// Creates a provider from any ``HomeContentProviding`` implementation.
    public init<P: HomeContentProviding>(_ provider: P) {
        self.handler = { request in
            try await provider.content(for: request)
        }
    }

    public func content(for request: HomeContentRequest) async throws -> HomeSectionContent? {
        try await handler(request)
    }

    /// A provider that always returns `nil`.
    public static let unavailable = HomeContentProvider { _ in nil }
}
