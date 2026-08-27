import SwiftUI

/// Reusable product card for products, popular products, and favorites.
struct ProductCardView: View {
    let product: Product
    var onTap: (() -> Void)? = nil

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
        VStack(alignment: .leading, spacing: 8) {
            RemoteImageView(url: product.imageURL)
                .frame(width: 148, height: 148)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 148, alignment: .leading)

            Text(ProductPriceFormatter.string(price: product.price, currency: product.currency))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    Text("Price \(ProductPriceFormatter.string(price: product.price, currency: product.currency))")
                )

            if product.isFavorite {
                Label("Favorite", systemImage: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
                    .accessibilityLabel("Marked as favorite")
            }
        }
        .padding(10)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(product.name))
        .accessibilityAddTraits(onTap == nil ? [] : .isButton)
    }
}
