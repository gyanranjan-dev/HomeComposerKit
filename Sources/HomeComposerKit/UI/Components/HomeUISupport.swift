import SwiftUI

/// Loads an image through the injected ``HomeImageProvider``.
struct RemoteImageView: View {
    let source: HomeImageSource
    var contentMode: ContentMode = .fill

    @Environment(\.homeImageProvider) private var imageProvider

    init(url: URL?, contentMode: ContentMode = .fill) {
        self.source = HomeImageSource(url: url)
        self.contentMode = contentMode
    }

    init(source: HomeImageSource, contentMode: ContentMode = .fill) {
        self.source = source
        self.contentMode = contentMode
    }

    var body: some View {
        imageProvider.image(for: source, contentMode: contentMode)
            .accessibilityHidden(source == .none)
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

/// Renders a collection of section items according to presentation layout intent.
struct HomeSectionItemsLayoutView<Item: Identifiable, ItemContent: View>: View {
    let layout: HomeSectionLayout
    let spacing: CGFloat
    let columns: Int
    let items: [Item]
    let carouselHeight: CGFloat?
    let itemContent: (Item) -> ItemContent

    @Environment(\.homeComposerTheme) private var theme

    init(
        layout: HomeSectionLayout,
        spacing: CGFloat,
        columns: Int,
        items: [Item],
        carouselHeight: CGFloat? = nil,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent
    ) {
        self.layout = layout
        self.spacing = spacing
        self.columns = columns
        self.items = items
        self.carouselHeight = carouselHeight
        self.itemContent = itemContent
    }

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            switch layout {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            case .grid:
                gridLayout
            case .carousel:
                carouselLayout
            case .unknown:
                horizontalLayout
            }
        }
    }

    private var horizontalLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(items) { item in
                    itemContent(item)
                }
            }
            .padding(.horizontal, theme.horizontalContentPadding)
        }
    }

    private var verticalLayout: some View {
        VStack(spacing: spacing) {
            ForEach(items) { item in
                itemContent(item)
            }
        }
        .padding(.horizontal, theme.horizontalContentPadding)
    }

    private var gridLayout: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: max(columns, 1)
            ),
            spacing: spacing
        ) {
            ForEach(items) { item in
                itemContent(item)
            }
        }
        .padding(.horizontal, theme.horizontalContentPadding)
    }

    @ViewBuilder
    private var carouselLayout: some View {
        #if os(iOS)
        TabView {
            ForEach(items) { item in
                itemContent(item)
                    .padding(.horizontal, theme.horizontalContentPadding)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: items.count > 1 ? .automatic : .never))
        .frame(height: carouselHeight)
        #else
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                ForEach(items) { item in
                    itemContent(item)
                }
            }
            .padding(.horizontal, theme.horizontalContentPadding)
        }
        .frame(height: carouselHeight)
        #endif
    }
}
