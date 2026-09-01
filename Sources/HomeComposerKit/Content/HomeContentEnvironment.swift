import SwiftUI

private struct HomeImageProviderKey: EnvironmentKey {
    static let defaultValue = HomeImageProvider.placeholder
}

private struct HomeContentProviderKey: EnvironmentKey {
    static let defaultValue = HomeContentProvider.unavailable
}

extension EnvironmentValues {
    /// Image provider used by built-in HomeComposerKit views.
    public var homeImageProvider: HomeImageProvider {
        get { self[HomeImageProviderKey.self] }
        set { self[HomeImageProviderKey.self] = newValue }
    }

    /// Content provider used when hosts resolve section payloads asynchronously.
    public var homeContentProvider: HomeContentProvider {
        get { self[HomeContentProviderKey.self] }
        set { self[HomeContentProviderKey.self] = newValue }
    }
}

extension View {
    /// Installs a host image provider for descendant HomeComposerKit views.
    public func homeImageProvider(_ provider: HomeImageProvider) -> some View {
        environment(\.homeImageProvider, provider)
    }

    /// Installs a host content provider for descendant HomeComposerKit views.
    public func homeContentProvider(_ provider: HomeContentProvider) -> some View {
        environment(\.homeContentProvider, provider)
    }
}
