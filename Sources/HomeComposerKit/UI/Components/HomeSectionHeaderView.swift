import SwiftUI

/// Reusable section header with optional subtitle and See All action.
struct HomeSectionHeaderView: View {
    let title: String?
    var subtitle: String? = nil
    var showTitle: Bool = true
    var showSeeAll: Bool = false
    var onSeeAll: (() -> Void)? = nil

    @Environment(\.homeComposerTheme) private var theme

    var body: some View {
        if shouldShow {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: theme.headerSpacing) {
                    if showTitle, let title, !title.isEmpty {
                        Text(title)
                            .font(theme.typography.sectionTitle)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(theme.typography.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: theme.spacing.small)

                if showSeeAll {
                    Button("See All") {
                        onSeeAll?()
                    }
                    .font(theme.typography.emphasis)
                    .accessibilityHint("Shows more items in this section")
                }
            }
            .padding(.horizontal, theme.horizontalContentPadding)
        }
    }

    private var shouldShow: Bool {
        let hasTitle = showTitle && !(title ?? "").isEmpty
        let hasSubtitle = !(subtitle ?? "").isEmpty
        return hasTitle || hasSubtitle || showSeeAll
    }
}
