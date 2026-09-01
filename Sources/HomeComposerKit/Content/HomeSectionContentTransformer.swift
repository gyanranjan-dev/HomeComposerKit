import Foundation

/// Transforms composed section content before rendering.
///
/// Transformers receive a ``ComposedHomeSection`` and optional ``HomeRenderContext``
/// for deterministic, host-defined enrichment. They must not perform networking,
/// persistence, or UI work.
public protocol HomeSectionContentTransforming: Sendable {
    func transform(
        section: ComposedHomeSection,
        context: HomeRenderContext?
    ) -> HomeSectionContentTransformation
}

/// Runs zero or more content transformers in registration order.
///
/// ## Execution order
///
/// Transformers run sequentially for each section. The current section value is
/// passed to the next transformer after each step.
///
/// ## Semantics
///
/// - ``HomeSectionContentTransformation/unchanged(_:)`` — continue with the same section.
/// - ``HomeSectionContentTransformation/replace(_:)`` — continue with the replacement section.
/// - ``HomeSectionContentTransformation/hidden`` — stop processing and omit the section.
///
/// ## No networking
///
/// The pipeline performs no I/O. Hosts resolve content before composition or
/// inside transformers using data already present in the section/context.
public struct HomeSectionContentTransformerPipeline: Sendable {

    private let transformers: [@Sendable (ComposedHomeSection, HomeRenderContext?) -> HomeSectionContentTransformation]

    /// A pipeline that leaves all sections unchanged.
    public static let identity = HomeSectionContentTransformerPipeline()

    /// Creates an empty pipeline.
    public init() {
        transformers = []
    }

    /// Creates a pipeline from protocol-based transformers.
    public init(transformers: [any HomeSectionContentTransforming]) {
        self.transformers = transformers.map { transformer in
            { section, context in
                transformer.transform(section: section, context: context)
            }
        }
    }

    /// Creates a pipeline from type-erased transformer closures.
    public init(
        transformers: [@Sendable (ComposedHomeSection, HomeRenderContext?) -> HomeSectionContentTransformation]
    ) {
        self.transformers = transformers
    }

    /// Applies the pipeline to a single composed section.
    ///
    /// - Returns: The transformed section, or `nil` when a transformer hides it.
    public func apply(
        to section: ComposedHomeSection,
        context: HomeRenderContext? = nil
    ) -> ComposedHomeSection? {
        var current = section

        for transformer in transformers {
            switch transformer(current, context) {
            case .unchanged(let unchanged):
                current = unchanged
            case .replace(let replacement):
                current = replacement
            case .hidden:
                return nil
            }
        }

        return current
    }

    /// Applies the pipeline to composed sections, preserving order.
    public func apply(
        to sections: [ComposedHomeSection],
        context: HomeRenderContext? = nil
    ) -> [ComposedHomeSection] {
        sections.compactMap { apply(to: $0, context: context) }
    }
}

extension ComposedHomeSection {

    /// Returns a copy with selectively replaced values.
    public func replacing(
        title: String? = nil,
        content: HomeSectionContent? = nil
    ) -> ComposedHomeSection {
        ComposedHomeSection(
            id: id,
            type: type,
            title: title ?? self.title,
            order: order,
            configuration: configuration,
            content: content ?? self.content
        )
    }
}
