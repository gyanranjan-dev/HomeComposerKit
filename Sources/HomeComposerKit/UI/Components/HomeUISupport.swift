import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Cross-platform semantic colors used by the SwiftUI layer.
enum HomeUIColor {
    static var groupedBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var cardBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color.white
        #endif
    }

    static var placeholderBackground: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(uiColor: .secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color.gray.opacity(0.15)
        #endif
    }
}

/// Loads a remote image with loading and failure placeholders.
struct RemoteImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
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
                        ZStack {
                            HomeUIColor.placeholderBackground
                            ProgressView()
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .accessibilityHidden(url == nil)
    }

    private var placeholder: some View {
        ZStack {
            HomeUIColor.placeholderBackground
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}

/// Formats a decimal price for display.
enum ProductPriceFormatter {
    static func string(price: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: price as NSDecimalNumber) ?? "\(currency) \(price)"
    }
}
