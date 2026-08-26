import Foundation

/// Severity of a configuration diagnostic.
public enum HomeDiagnosticSeverity: String, Sendable, Equatable {
    case info
    case warning
    case error
}

/// Machine-readable diagnostic codes for host handling/reporting.
public enum HomeDiagnosticCode: String, Sendable, Equatable {
    case emptySectionID
    case duplicateSectionID
    case invalidSectionPosition
    case unsupportedSectionType
    case invalidSectionConfiguration
    case emptyHomePageID
}

/// A structured diagnostic describing a configuration issue.
///
/// Host apps can forward these to their own logging/analytics systems.
public struct HomeDiagnostic: Sendable, Equatable {
    public let severity: HomeDiagnosticSeverity
    public let code: HomeDiagnosticCode
    public let message: String
    public let sectionID: String?

    public init(
        severity: HomeDiagnosticSeverity,
        code: HomeDiagnosticCode,
        message: String,
        sectionID: String? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.sectionID = sectionID
    }
}

/// Receives configuration diagnostics from validation/composition.
///
/// The library does not print or log by default. Hosts inject a reporter
/// when they want observability.
public protocol HomeComposerDiagnosticReporting: Sendable {
    func report(_ diagnostic: HomeDiagnostic)
}

extension HomeComposerDiagnosticReporting {
    /// Reports every diagnostic in a validation result.
    public func report(_ result: HomeValidationResult) {
        for diagnostic in result.diagnostics {
            report(diagnostic)
        }
    }
}

/// Silent default reporter. Safe for production when the host opts out of diagnostics.
public struct NoOpHomeComposerDiagnosticReporter: HomeComposerDiagnosticReporting {
    public init() {}

    public func report(_ diagnostic: HomeDiagnostic) {}
}
