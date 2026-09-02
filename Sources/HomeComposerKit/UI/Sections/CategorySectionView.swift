import SwiftUI

/// Category section driven by presentation configuration.
public struct CategorySectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var categories: [Category] {
        guard case .categories(let payload) = section.content else { return [] }
        let items = payload.categories
        if let limit = section.configuration?.limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: section.effectiveSpacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: section.effectiveShowTitle,
                showSeeAll: section.effectiveShowSeeAll,
                onSeeAll: section.effectiveShowSeeAll
                    ? { actionHandler.handle(.section(id: section.id)) }
                    : nil
            )

            HomeSectionBuiltInContent.emptyOrContent(
                isEmpty: categories.isEmpty,
                sectionType: section.type
            ) {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    configuredColumns: section.configuredGridColumns,
                    defaultColumns: 4,
                    items: categories
                ) { category in
                    categoryItem(category)
                }
            }
        }
    }

    private func categoryItem(_ category: Category) -> some View {
        Button {
            actionHandler.handle(.category(id: category.id))
        } label: {
            VStack(spacing: theme.cardSpacing) {
                RemoteImageView(url: category.imageURL)
                    .frame(
                        width: HomeAdaptiveLayout.circularItemSize(dynamicTypeSize: dynamicTypeSize),
                        height: HomeAdaptiveLayout.circularItemSize(dynamicTypeSize: dynamicTypeSize)
                    )
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(category.name)
                    .font(theme.typography.caption.weight(.medium))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 80, maxWidth: 120)
            .padding(theme.spacing.small)
            .background(theme.cardBackgroundColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: theme.cornerRadius.medium,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(HomeAccessibilityLabels.category(category)))
        .accessibilityHint("Opens category")
    }
}
