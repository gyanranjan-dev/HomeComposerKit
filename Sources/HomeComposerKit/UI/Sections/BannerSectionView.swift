import SwiftUI

/// Displays a swipeable banner carousel for banner sections.
public struct BannerSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var banners: [Banner] {
        if case .banner(let payload) = section.content {
            return payload.banners
        }
        return []
    }

    public var body: some View {
        HomeSectionContainer(title: section.title) {
            if banners.isEmpty {
                emptyPlaceholder
            } else {
                #if os(iOS)
                TabView {
                    ForEach(banners) { banner in
                        bannerCard(banner)
                            .padding(.horizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: banners.count > 1 ? .automatic : .never))
                .frame(height: 200)
                #else
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(banners) { banner in
                            bannerCard(banner)
                                .frame(width: 520, height: 200)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 200)
                #endif
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
                if let action = banner.action {
                    Text(action.title ?? "View")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.92))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    }
}

struct BannerSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .banner
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(BannerSectionView(section: section))
    }
}
