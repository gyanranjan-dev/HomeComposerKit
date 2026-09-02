import SwiftUI

/// Promotion section driven by presentation configuration.
public struct PromotionSectionView: View {
    let section: ComposedHomeSection

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var promotions: [Promotion] {
        guard case .promotion(let payload) = section.content else { return [] }
        let items = payload.promotions
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
                isEmpty: promotions.isEmpty,
                sectionType: section.type
            ) {
                promotionContent
            }
        }
    }

    @ViewBuilder
    private var promotionContent: some View {
        HomeSectionItemsLayoutView(
            layout: section.effectiveLayout,
            spacing: section.effectiveSpacing,
            configuredColumns: section.configuredGridColumns,
            defaultColumns: 1,
            items: promotions
        ) { promotion in
            promotionCard(promotion)
        }
    }

    @ViewBuilder
    private func promotionCard(_ promotion: Promotion) -> some View {
        let card = promotionCardContent(promotion)

        if let action = HomeAction.from(promotion: promotion) {
            Button {
                actionHandler.handle(action)
            } label: {
                card
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(HomeAccessibilityLabels.promotion(promotion)))
            .accessibilityHint("Opens promotion")
            .accessibilityAddTraits(.isButton)
        } else {
            card
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(HomeAccessibilityLabels.promotion(promotion)))
        }
    }

    private func promotionCardContent(_ promotion: Promotion) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.medium) {
            if let imageURL = promotion.imageURL {
                RemoteImageView(url: imageURL)
                    .frame(width: 96, height: 96)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: theme.cornerRadius.medium,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: theme.spacing.compact) {
                Text(promotion.title)
                    .font(theme.typography.sectionTitle)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = promotion.subtitle {
                    Text(subtitle)
                        .font(theme.typography.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let actionTitle = promotion.action?.title {
                    Text(actionTitle)
                        .font(theme.typography.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHidden(true)
        }
        .padding(theme.spacing.medium)
        .background(theme.cardBackgroundColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: theme.cornerRadius.large,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        .padding(.horizontal, theme.horizontalContentPadding)
    }
}
