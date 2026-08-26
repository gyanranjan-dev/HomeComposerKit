import SwiftUI

/// Cross-platform semantic colors for the SwiftUI layer.
enum HomeUIColor {
    static var groupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var cardBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var placeholderBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #else
        Color(nsColor: .underPageBackgroundColor)
        #endif
    }
}

/// Shared remote-image helper with a lightweight placeholder.
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(HomeUIColor.placeholderBackground)
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            HomeUIColor.placeholderBackground
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Formats a product price for display.
enum ProductPriceFormatter {
    static func string(price: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: price as NSDecimalNumber) ?? "\(currency) \(price)"
    }
}

/// Reusable product card used by products, favorites, and popular sections.
struct ProductCardView: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteImageView(url: product.imageURL)
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)

            Text(ProductPriceFormatter.string(price: product.price, currency: product.currency))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if product.isFavorite {
                Label("Favorite", systemImage: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
            }
        }
        .padding(10)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// Standard section chrome: optional title + content.
struct HomeSectionContainer<Content: View>: View {
    let title: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal)
            }
            content()
        }
    }
}
