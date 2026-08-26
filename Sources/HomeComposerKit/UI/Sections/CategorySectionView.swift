import SwiftUI

/// Horizontal scrolling category section.
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

    private var spacing: CGFloat {
        CGFloat(section.configuration?.spacing ?? 12)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: shouldShowTitle
            )

            if categories.isEmpty {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No categories available")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(categories) { category in
                            categoryItem(category)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var shouldShowTitle: Bool {
        !(section.title ?? "").isEmpty
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
