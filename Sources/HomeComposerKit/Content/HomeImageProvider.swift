import SwiftUI

/// Host-injected image resolution for ``HomeImageSource`` values.
///
/// **HomeComposerKit does not download or cache images.** The host application
/// owns networking, persistence, and caching. The default ``placeholder``
/// provider resolves only local asset/system images and shows a placeholder
/// for remote sources.
public protocol HomeImageProviding {
    func image(for source: HomeImageSource, contentMode: ContentMode) -> AnyView
}

/// Type-erased image provider for SwiftUI environment injection.
public struct HomeImageProvider: HomeImageProviding, @unchecked Sendable {

    private let resolver: (HomeImageSource, ContentMode) -> AnyView

    /// Creates a provider from a view-building closure.
    public init<Image: View>(
        @ViewBuilder _ resolver: @escaping (HomeImageSource, ContentMode) -> Image
    ) {
        self.resolver = { source, contentMode in
            AnyView(resolver(source, contentMode))
        }
    }

    /// Creates a provider from any ``HomeImageProviding`` implementation.
    public init<P: HomeImageProviding>(_ provider: P) {
        self.resolver = { source, contentMode in
            provider.image(for: source, contentMode: contentMode)
        }
    }

    public func image(for source: HomeImageSource, contentMode: ContentMode) -> AnyView {
        resolver(source, contentMode)
    }

    /// Default provider that does not perform networking.
    ///
    /// - ``HomeImageSource/asset`` and ``HomeImageSource/system`` render locally.
    /// - ``HomeImageSource/remote`` and unknown sources render a themed placeholder.
    public static let placeholder = HomeImageProvider { source, contentMode in
        HomeDefaultImageContent(source: source, contentMode: contentMode)
    }
}

/// Built-in local image resolution used by ``HomeImageProvider/placeholder``.
struct HomeDefaultImageContent: View {
    let source: HomeImageSource
    let contentMode: ContentMode

    @Environment(\.homeComposerTheme) private var theme

    var body: some View {
        switch source {
        case .asset(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        case .system(let name):
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        case .remote, .none, .unknown:
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            theme.placeholderBackgroundColor
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}
