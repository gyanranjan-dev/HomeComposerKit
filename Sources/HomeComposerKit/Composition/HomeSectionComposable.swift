import Foundation

/// Determines whether a home section can be included in a composed result.
///
/// Conformers decide composability from section state (for example, enabled flags).
/// The composition engine relies on this abstraction instead of hard-coding host rules.
public protocol HomeSectionComposable {
    /// Returns `true` when the section should be included in the composed output.
    var canCompose: Bool { get }
}

extension HomeSection: HomeSectionComposable {
    /// Enabled sections are eligible for composition.
    public var canCompose: Bool {
        isEnabled
    }
}
