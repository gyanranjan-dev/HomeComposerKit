import SwiftUI

/// Banner carousel section with image, title, and optional subtitle.
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

    private var spacing: CGFloat {
        CGFloat(section.configuration?.spacing ?? 12)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: shouldShowTitle
            )

            if banners.isEmpty {
                emptyPlaceholder
            } else if banners.count == 1, let banner = banners.first {
                bannerCard(banner)
                    .padding(.horizontal)
                    .frame(height: 200)
            } else {
                #if os(iOS)
                TabView {
                    ForEach(banners) { banner in
                        bannerCard(banner)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 200)
                #else
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(banners) { banner in
                            bannerCard(banner)
                                .frame(width: 480, height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
                #endif
            }
        }
    }

    private var shouldShowTitle: Bool {
        !(section.title ?? "").isEmpty
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
