import SwiftUI

/// Reusable section header with optional subtitle and See All action.
struct HomeSectionHeaderView: View {
    let title: String?
    var subtitle: String? = nil
    var showTitle: Bool = true
    var showSeeAll: Bool = false
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        if shouldShow {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    if showTitle, let title, !title.isEmpty {
                        Text(title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if showSeeAll {
                    Button("See All") {
                        onSeeAll?()
                    }
                    .font(.subheadline.weight(.medium))
                    .accessibilityHint("Shows more items in this section")
                }
            }
            .padding(.horizontal)
        }
    }

    private var shouldShow: Bool {
        let hasTitle = showTitle && !(title ?? "").isEmpty
        let hasSubtitle = !(subtitle ?? "").isEmpty
        return hasTitle || hasSubtitle || showSeeAll
    }
}
