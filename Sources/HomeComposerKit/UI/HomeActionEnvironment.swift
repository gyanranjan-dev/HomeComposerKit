import SwiftUI

private struct HomeActionHandlerKey: EnvironmentKey {
    static let defaultValue = HomeActionHandler.noop
}

extension EnvironmentValues {
    /// Handler invoked when built-in section views emit a ``HomeAction``.
    public var homeActionHandler: HomeActionHandler {
        get { self[HomeActionHandlerKey.self] }
        set { self[HomeActionHandlerKey.self] = newValue }
    }
}

extension View {
    /// Installs a host action handler for descendant home section views.
    public func homeActionHandler(_ handler: HomeActionHandler) -> some View {
        environment(\.homeActionHandler, handler)
    }

    /// Installs a closure-based host action handler.
    public func onHomeAction(_ action: @escaping (HomeAction) -> Void) -> some View {
        homeActionHandler(HomeActionHandler(action))
    }
}
