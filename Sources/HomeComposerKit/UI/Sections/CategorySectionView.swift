import SwiftUI

/// Category section driven by presentation configuration.
public struct CategorySectionView: View {
    let section: ComposedHomeSection

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
                showSeeAll: section.effectiveShowSeeAll
            )

            if categories.isEmpty {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No categories available")
            } else {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    columns: section.effectiveColumns(default: 4),
                    items: categories
                ) { category in
                    categoryItem(category)
                }
            }
        }
    }

    private func categoryItem(_ category: Category) -> some View {
        VStack(spacing: 8) {
            RemoteImageView(url: category.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(category.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(width: 80)
        }
        .padding(8)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(category.name))
        .accessibilityAddTraits(.isButton)
        // Navigation is intentionally deferred.
        .onTapGesture {}
    }
}
