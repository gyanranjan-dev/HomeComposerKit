import SwiftUI

/// Horizontal scrolling category cards.
public struct CategorySectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var categories: [Category] {
        if case .categories(let payload) = section.content {
            return payload.categories
        }
        return []
    }

    public var body: some View {
        HomeSectionContainer(title: section.title) {
            if categories.isEmpty {
                Text("No categories")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories) { category in
                            categoryItem(category)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func categoryItem(_ category: Category) -> some View {
        VStack(spacing: 8) {
            RemoteImageView(url: category.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(category.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .frame(width: 80)
        }
        .padding(8)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        // Tap intentionally no-op for Step 3.
        .onTapGesture {}
    }
}

struct CategorySectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .categories
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(CategorySectionView(section: section))
    }
}
