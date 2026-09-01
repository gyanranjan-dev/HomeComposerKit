import Foundation

/// Outcome of transforming a composed section's content before rendering.
///
/// Transformers run synchronously and must not perform networking.
public enum HomeSectionContentTransformation: Sendable, Equatable {
    /// Keep the current section and continue to the next transformer.
    case unchanged(ComposedHomeSection)
    /// Replace the section and continue to the next transformer with the replacement.
    case replace(ComposedHomeSection)
    /// Hide the section and stop processing further transformers for it.
    case hidden
}

extension HomeSectionContentTransformation {

    /// The section value carried by ``unchanged`` or ``replace``.
    public var section: ComposedHomeSection? {
        switch self {
        case .unchanged(let section), .replace(let section):
            return section
        case .hidden:
            return nil
        }
    }
}
