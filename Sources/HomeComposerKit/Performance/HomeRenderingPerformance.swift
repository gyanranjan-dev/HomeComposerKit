import Foundation

/// Internal performance helpers for deterministic home page processing.
///
/// HomeComposerKit intentionally avoids global caches. Helpers here improve
/// algorithmic efficiency without retaining stale derived state.
enum HomeRenderingPerformance {

    /// Applies a transformation pipeline, returning the input unchanged when empty.
    static func applyPipeline(
        _ pipeline: HomeSectionContentTransformerPipeline,
        to sections: [ComposedHomeSection],
        context: HomeSectionTransformationContext
    ) -> [ComposedHomeSection] {
        guard pipeline.hasTransformers else {
            return sections
        }

        var output: [ComposedHomeSection] = []
        output.reserveCapacity(sections.count)

        for section in sections {
            if let transformed = pipeline.apply(to: section, context: context) {
                output.append(transformed)
            }
        }

        return output
    }
}
