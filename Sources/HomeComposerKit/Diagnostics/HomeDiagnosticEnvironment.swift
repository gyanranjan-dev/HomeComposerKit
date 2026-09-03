import SwiftUI

private struct HomeDiagnosticReporterKey: EnvironmentKey {
    static let defaultValue: any HomeComposerDiagnosticReporting = NoOpHomeComposerDiagnosticReporter()
}

extension EnvironmentValues {
    /// Host diagnostic reporter for HomeComposerKit observability.
    public var homeDiagnosticReporter: any HomeComposerDiagnosticReporting {
        get { self[HomeDiagnosticReporterKey.self] }
        set { self[HomeDiagnosticReporterKey.self] = newValue }
    }
}

extension View {
    /// Installs a diagnostic reporter for descendant HomeComposerKit views.
    public func homeDiagnosticReporter(_ reporter: any HomeComposerDiagnosticReporting) -> some View {
        environment(\.homeDiagnosticReporter, reporter)
    }
}
