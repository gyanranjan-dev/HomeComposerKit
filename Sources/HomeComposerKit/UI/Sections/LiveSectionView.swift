import SwiftUI

/// Visual live-stream section. Does not play or stream video.
public struct LiveSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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
                showSeeAll: section.effectiveShowSeeAll,
                onSeeAll: section.effectiveShowSeeAll
                    ? { actionHandler.handle(.section(id: section.id)) }
                    : nil
            )

            HomeSectionBuiltInContent.emptyOrContent(
                isEmpty: streams.isEmpty,
                sectionType: section.type
            ) {
                HomeSectionItemsLayoutView(
                    layout: section.effectiveLayout,
                    spacing: section.effectiveSpacing,
                    configuredColumns: section.configuredGridColumns,
                    defaultColumns: 2,
                    items: streams,
                    carouselHeight: 160
                ) { stream in
                    liveCard(stream)
                }
            }
        }
    }

    private func liveCard(_ stream: LiveStream) -> some View {
        VStack(alignment: .leading, spacing: theme.cardSpacing) {
            ZStack(alignment: .topLeading) {
                RemoteImageView(url: stream.thumbnailURL)
                    .aspectRatio(5 / 3, contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 140)
                    .clipped()
                    .accessibilityHidden(true)

                if stream.isLive {
                    Text("LIVE")
                        .font(theme.typography.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, theme.spacing.small)
                        .padding(.vertical, theme.spacing.compact)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(theme.spacing.small)
                        .accessibilityHidden(true)
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: theme.cornerRadius.small,
                    style: .continuous
                )
            )

            Text(stream.title)
                .font(theme.typography.emphasis)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.cardPadding)
        .background(theme.cardBackgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.medium,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(HomeAccessibilityLabels.liveStream(stream)))
    }
}
