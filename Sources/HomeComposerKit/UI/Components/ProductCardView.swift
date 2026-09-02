import SwiftUI

/// Reusable product card for products, popular products, and favorites.
struct ProductCardView: View {
    let product: Product
    var onTap: (() -> Void)? = nil

    @Environment(\.homeComposerTheme) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var imageDimension: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 168 : 148
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: theme.cardSpacing) {
            RemoteImageView(url: product.imageURL)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: imageDimension, minHeight: imageDimension, maxHeight: imageDimension)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: theme.cornerRadius.small,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            Text(product.name)
                .font(theme.typography.emphasis)
                .foregroundStyle(.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(ProductPriceFormatter.string(price: product.price, currency: product.currency))
                .font(theme.typography.price)
                .foregroundStyle(.secondary)

            if product.isFavorite {
                Label("Favorite", systemImage: "heart.fill")
                    .font(theme.typography.caption)
                    .foregroundStyle(.pink)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel(Text(HomeAccessibilityLabels.product(product)))
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
        .modifier(ProductCardAccessibilityHint(hasAction: onTap != nil))
    }
}

private struct ProductCardAccessibilityHint: ViewModifier {
    let hasAction: Bool

    func body(content: Content) -> some View {
        if hasAction {
            content.accessibilityHint("Opens product details")
        } else {
            content
        }
    }
}
