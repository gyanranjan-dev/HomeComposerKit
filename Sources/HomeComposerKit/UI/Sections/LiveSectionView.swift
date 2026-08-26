import SwiftUI

/// Horizontal live stream cards with a basic live indicator.
public struct LiveSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var streams: [LiveStream] {
        if case .live(let payload) = section.content {
            return payload.streams
        }
        return []
    }

    public var body: some View {
        HomeSectionContainer(title: section.title) {
            if streams.isEmpty {
                Text("No live streams")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(streams) { stream in
                            liveCard(stream)
                        }
                    }
                    .padding(.horizontal)
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
    }
}

struct LiveSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .liveStream
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(LiveSectionView(section: section))
    }
}
