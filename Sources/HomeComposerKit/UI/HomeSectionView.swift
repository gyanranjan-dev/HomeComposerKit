import SwiftUI

/// Renders a single composed home section by delegating to the renderer registry.
public struct HomeSectionView: View {
    public let section: ComposedHomeSection
    private let registry: HomeSectionRendererRegistry

    public init(
        section: ComposedHomeSection,
        registry: HomeSectionRendererRegistry = .makeDefault()
    ) {
        self.section = section
        self.registry = registry
    }

    public var body: some View {
        HomeSectionStateView(
            sectionID: section.id,
            sectionType: section.type,
            sectionTitle: section.title
        ) {
            HomeSectionRenderer.view(for: section, in: registry)
        }
        .accessibilityElement(children: .contain)
    }
}
