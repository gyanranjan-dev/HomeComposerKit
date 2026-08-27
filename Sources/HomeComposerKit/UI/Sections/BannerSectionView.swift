import SwiftUI

/// Banner section driven by presentation configuration.
public struct BannerSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var banners: [Banner] {
        guard case .banner(let payload) = section.content else { return [] }
        let items = payload.banners
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

            if banners.isEmpty {
                emptyPlaceholder
            } else {
                bannerContent
            }
        }
    }

    @ViewBuilder
    private var bannerContent: some View {
        switch section.effectiveLayout {
        case .carousel:
            if banners.count == 1, let banner = banners.first {
                bannerCard(banner)
                    .padding(.horizontal)
                    .frame(height: 200)
            } else {
                HomeSectionItemsLayoutView(
                    layout: .carousel,
                    spacing: section.effectiveSpacing,
                    columns: 1,
                    items: banners,
                    carouselHeight: 200
                ) { banner in
                    bannerCard(banner)
                }
            }
        case .horizontal:
            HomeSectionItemsLayoutView(
                layout: .horizontal,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(width: 480, height: 200)
            }
            .frame(height: 200)
        case .vertical:
            HomeSectionItemsLayoutView(
                layout: .vertical,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(height: 200)
            }
        case .grid:
            HomeSectionItemsLayoutView(
                layout: .grid,
                spacing: section.effectiveSpacing,
                columns: section.effectiveColumns(default: 1),
                items: banners
            ) { banner in
                bannerCard(banner)
                    .frame(height: 160)
            }
        case .unknown:
            HomeSectionItemsLayoutView(
                layout: .carousel,
                spacing: section.effectiveSpacing,
                columns: 1,
                items: banners,
                carouselHeight: 200
            ) { banner in
                bannerCard(banner)
            }
        }
    }

    private func bannerCard(_ banner: Banner) -> some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: banner.imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                if let title = banner.title {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                if let subtitle = banner.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                if let actionTitle = banner.action?.title {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.92))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                        .padding(.top, 2)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel(for: banner)))
    }

    private func accessibilityLabel(for banner: Banner) -> String {
        [banner.title, banner.subtitle, banner.action?.title]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private var emptyPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(HomeUIColor.placeholderBackground)
            .frame(height: 160)
            .overlay {
                Text("No banners")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .accessibilityLabel("No banners available")
    }
}
