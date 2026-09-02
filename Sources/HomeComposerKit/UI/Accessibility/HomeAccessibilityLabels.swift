import Foundation

/// Testable accessibility label builders for built-in HomeComposerKit views.
///
/// Labels derive from section content models. Custom host renderers are
/// responsible for their own accessibility semantics.
public enum HomeAccessibilityLabels {

    /// Accessibility label for a product card.
    public static func product(_ product: Product) -> String {
        var parts = [product.name, ProductPriceFormatter.string(price: product.price, currency: product.currency)]
        if product.isFavorite {
            parts.append("Favorite")
        }
        return parts.joined(separator: ", ")
    }

    /// Accessibility label for a category item.
    public static func category(_ category: Category) -> String {
        category.name
    }

    /// Accessibility label for a banner.
    public static func banner(_ banner: Banner) -> String {
        [banner.title, banner.subtitle, banner.action?.title]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    /// Accessibility label for a brand item.
    public static func brand(_ brand: Brand) -> String {
        brand.name
    }

    /// Accessibility label for a promotion.
    public static func promotion(_ promotion: Promotion) -> String {
        [promotion.title, promotion.subtitle, promotion.action?.title]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    /// Accessibility label for a live stream card.
    public static func liveStream(_ stream: LiveStream) -> String {
        stream.isLive ? "Live: \(stream.title)" : stream.title
    }

    /// Accessibility label for a social post card.
    public static func socialPost(_ post: SocialPost) -> String {
        if let content = post.content {
            return "\(post.author): \(content)"
        }
        return post.author
    }

    /// Accessibility label for an empty section state.
    public static func emptyState(title: String, message: String?) -> String {
        if let message, !message.isEmpty {
            return "\(title). \(message)"
        }
        return title
    }

    /// Accessibility label for an error section state.
    public static func errorState(title: String, message: String, retryTitle: String?) -> String {
        var parts = [title, message]
        if let retryTitle, !retryTitle.isEmpty {
            parts.append(retryTitle)
        }
        return parts.joined(separator: ". ")
    }
}
