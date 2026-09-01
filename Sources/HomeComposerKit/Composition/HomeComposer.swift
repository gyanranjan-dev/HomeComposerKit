import Foundation

/// Converts a `HomePage` configuration into an ordered list of renderable sections.
///
/// The composer is domain-agnostic and production-safe:
/// - disabled / empty-id sections are excluded
/// - duplicate section ids keep the first occurrence only
/// - negative positions are skipped
/// - unknown section types are preserved for host/registry extension
/// - missing content never crashes composition
///
/// It does not perform networking or UI work.
public struct HomeComposer: Sendable {

    public init() {}

    /// Composes an ordered list of sections ready for rendering.
    ///
    /// - Parameters:
    ///   - homePage: The configured home page to compose.
    ///   - contentBySectionID: Optional section payloads keyed by section `id`.
    ///   - diagnosticReporter: Optional host reporter for skipped/invalid sections.
    ///   - transformationPipeline: Optional post-composition content transformers.
    ///   - context: Optional render context passed to transformers.
    /// - Returns: Safely filtered sections sorted by `order`. When two sections share
    ///   the same order, their relative position from the original API array is preserved.
    public func compose(
        _ homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter(),
        transformationPipeline: HomeSectionContentTransformerPipeline = .identity,
        context: HomeRenderContext? = nil
    ) -> [ComposedHomeSection] {
        let composed = composeSections(
            homePage,
            contentBySectionID: contentBySectionID,
            diagnosticReporter: diagnosticReporter
        )

        return transformationPipeline.apply(to: composed, context: context)
    }

    /// Composes sections without applying a transformation pipeline.
    ///
    /// Existing callers that only need composition can continue using this method
    /// for identical behavior to pre-transformation releases.
    public func composeSections(
        _ homePage: HomePage,
        contentBySectionID: [String: HomeSectionContent] = [:],
        diagnosticReporter: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
    ) -> [ComposedHomeSection] {
        var seenIDs = Set<String>()

        return homePage.sections
            .enumerated()
            .compactMap { index, section -> (offset: Int, element: HomeSection)? in
                let trimmedID = section.id.trimmingCharacters(in: .whitespacesAndNewlines)

                guard section.isEnabled else {
                    return nil
                }

                guard !trimmedID.isEmpty else {
                    diagnosticReporter.report(
                        HomeDiagnostic(
                            severity: .error,
                            code: .emptySectionID,
                            message: "Skipping section with empty id during composition.",
                            sectionID: section.id
                        )
                    )
                    return nil
                }

                if seenIDs.contains(trimmedID) {
                    diagnosticReporter.report(
                        HomeDiagnostic(
                            severity: .error,
                            code: .duplicateSectionID,
                            message: "Skipping duplicate section id '\(trimmedID)' during composition.",
                            sectionID: trimmedID
                        )
                    )
                    return nil
                }

                if section.order < 0 {
                    diagnosticReporter.report(
                        HomeDiagnostic(
                            severity: .error,
                            code: .invalidSectionPosition,
                            message: "Skipping section with invalid order \(section.order).",
                            sectionID: section.id
                        )
                    )
                    return nil
                }

                if let configuration = section.configuration,
                   hasInvalidConfiguration(configuration) {
                    diagnosticReporter.report(
                        HomeDiagnostic(
                            severity: .error,
                            code: .invalidSectionConfiguration,
                            message: "Skipping section with invalid configuration values.",
                            sectionID: section.id
                        )
                    )
                    return nil
                }

                if !section.type.isKnown {
                    diagnosticReporter.report(
                        HomeDiagnostic(
                            severity: .warning,
                            code: .unsupportedSectionType,
                            message: "Composing unsupported section type '\(section.type.rawValue)'.",
                            sectionID: section.id
                        )
                    )
                }

                seenIDs.insert(trimmedID)
                return (offset: index, element: section)
            }
            .sorted { lhs, rhs in
                if lhs.element.order != rhs.element.order {
                    return lhs.element.order < rhs.element.order
                }
                return lhs.offset < rhs.offset
            }
            .map { _, section in
                ComposedHomeSection(
                    section: section,
                    content: contentBySectionID[section.id]
                )
            }
    }

    private func hasInvalidConfiguration(_ configuration: SectionConfiguration) -> Bool {
        if let limit = configuration.limit, limit < 0 { return true }
        if let columns = configuration.columns, columns < 0 { return true }
        if let spacing = configuration.spacing, spacing < 0 { return true }
        return false
    }
}
