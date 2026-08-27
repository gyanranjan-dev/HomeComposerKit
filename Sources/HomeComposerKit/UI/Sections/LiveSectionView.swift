import SwiftUI

/// Visual live-stream section. Does not play or stream video.
public struct LiveSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var streams: [LiveStream] {
        guard case .live(let payload) = section.content else { return [] }
        let items = payload.streams
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

            if streams.isEmpty {
                Text("No live streams")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No live streams available")
            } else {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    columns: section.effectiveColumns(default: 2),
                    items: streams,
                    carouselHeight: 160
                ) { stream in
                    liveCard(stream)
                }
            }
        }
    }

    private func liveCard(_ stream: LiveStream) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RemoteImageView(url: stream.thumbnailURL)
                    .frame(width: 200, height: 120)
                    .clipped()

                if stream.isLive {
                    Text("LIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(8)
                        .accessibilityLabel("Currently live")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(stream.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(width: 200, alignment: .leading)
        }
        .padding(10)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(stream.isLive ? "Live: \(stream.title)" : stream.title))
    }
}
