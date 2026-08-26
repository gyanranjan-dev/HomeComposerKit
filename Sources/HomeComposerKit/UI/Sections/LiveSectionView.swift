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

    private var spacing: CGFloat {
        CGFloat(section.configuration?.spacing ?? 12)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: shouldShowTitle
            )

            if streams.isEmpty {
                Text("No live streams")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No live streams available")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(streams) { stream in
                            liveCard(stream)
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
