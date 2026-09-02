import Foundation

/// A safe, value-oriented failure representation for section state.
///
/// HomeComposerKit does not perform networking. The host supplies failure
/// information after its own loading operations complete.
public struct HomeSectionFailure: Sendable, Hashable, Equatable {

    /// Human-readable failure description.
    public let message: String

    /// Optional machine-readable failure code supplied by the host.
    public let code: String?

    public init(message: String, code: String? = nil) {
        self.message = message
        self.code = code
    }
}

/// Presentation state for a home page section.
///
/// Section state describes UI presentation only. The host application owns
/// data loading, errors, and retry behavior.
public enum HomeSectionState: Sendable, Hashable, Equatable {
    /// Content is being loaded by the host.
    case loading
    /// Content is available and should render normally.
    case loaded
    /// Content loaded successfully but has nothing to display.
    case empty
    /// Content failed to load.
    case failed(HomeSectionFailure)
}

extension HomeSectionState {

    /// Whether this state represents a successful loaded presentation.
    public var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}
