import SwiftUI

private struct HomePersonalizationContextKey: EnvironmentKey {
    static let defaultValue = HomePersonalizationContext.empty
}

extension EnvironmentValues {
    /// Host-provided personalization signals for section transformers.
    public var homePersonalizationContext: HomePersonalizationContext {
        get { self[HomePersonalizationContextKey.self] }
        set { self[HomePersonalizationContextKey.self] = newValue }
    }
}

extension View {
    /// Installs a personalization context for descendant HomeComposerKit views.
    public func homePersonalizationContext(_ context: HomePersonalizationContext) -> some View {
        environment(\.homePersonalizationContext, context)
    }
}
