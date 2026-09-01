import SwiftUI

/// Brand section driven by presentation configuration.
public struct BrandSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var brands: [Brand] {
        guard case .brand(let payload) = section.content else { return [] }
        let items = payload.brands
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

            if brands.isEmpty {
                Text("No brands")
                    .font(theme.typography.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, theme.horizontalContentPadding)
                    .accessibilityLabel("No brands available")
            } else {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    columns: section.effectiveColumns(default: 4),
                    items: brands
                ) { brand in
                    brandItem(brand)
                }
            }
        }
    }

    private func brandItem(_ brand: Brand) -> some View {
        Button {
            actionHandler.handle(.from(brand: brand))
        } label: {
            VStack(spacing: theme.cardSpacing) {
                RemoteImageView(url: brand.imageURL)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(brand.name)
                    .font(theme.typography.caption.weight(.medium))
                    .lineLimit(1)
                    .frame(width: 80)
            }
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
        .accessibilityLabel(Text(brand.name))
    }
}
