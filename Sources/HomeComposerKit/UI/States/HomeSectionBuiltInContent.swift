import SwiftUI

/// Shared empty-content helper for built-in section renderers.
enum HomeSectionBuiltInContent {

    @ViewBuilder
    static func emptyOrContent<Content: View>(
        isEmpty: Bool,
        sectionType: HomeSectionType,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isEmpty {
            HomeSectionBuiltInEmptyView(sectionType: sectionType)
        } else {
            content()
        }
    }
}

/// Empty presentation for built-in sections when no explicit host state exists.
struct HomeSectionBuiltInEmptyView: View {

    let sectionType: HomeSectionType

    @Environment(\.homeSectionStateConfiguration) private var stateConfiguration

    var body: some View {
        HomeSectionEmptyStateView(
            configuration: stateConfiguration.emptyConfiguration(for: sectionType)
        )
    }
}
