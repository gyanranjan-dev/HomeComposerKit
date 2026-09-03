import Foundation

/// Severity of a framework diagnostic.
public enum HomeDiagnosticSeverity: String, Sendable, Equatable, Hashable {
    case info
    case warning
    case error
}

/// Structured category for grouping diagnostics.
public enum HomeDiagnosticCategory: String, Sendable, Equatable, Hashable {
    case decoding
    case validation
    case composition
    case configuration
    case rendering
    case content
    case transformation
    case state
}

/// Machine-readable diagnostic codes for host handling.
public enum HomeDiagnosticCode: String, Sendable, Equatable, Hashable {
    case emptySectionID
    case duplicateSectionID
    case invalidSectionPosition
    case unsupportedSectionType
    case invalidSectionConfiguration
    case emptyHomePageID
    case rendererNotRegistered = "renderer_not_registered"
    case sectionHidden = "section_hidden"
    case sectionReplaced = "section_replaced"
    case missingSectionContent = "missing_section_content"
    case stateLoading = "state_loading"
    case stateEmpty = "state_empty"
    case stateFailed = "state_failed"
}

/// A structured diagnostic describing an issue or notable event.
///
/// Diagnostics are developer observability signals. HomeComposerKit does not
/// persist, transmit, or print them. Hosts inject a reporter to consume them.
public struct HomeDiagnostic: Sendable, Equatable, Hashable {
    public let severity: HomeDiagnosticSeverity
    public let category: HomeDiagnosticCategory
    public let code: HomeDiagnosticCode
    public let message: String
    public let sectionID: String?
    public let sectionType: HomeSectionType?
    public let metadata: [String: String]

    public init(
        severity: HomeDiagnosticSeverity,
        code: HomeDiagnosticCode,
        message: String,
        sectionID: String? = nil,
        category: HomeDiagnosticCategory? = nil,
        sectionType: HomeSectionType? = nil,
        metadata: [String: String] = [:]
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.sectionID = sectionID
        self.category = category ?? HomeDiagnostic.category(for: code)
        self.sectionType = sectionType
        self.metadata = metadata
    }

    /// Default category for a diagnostic code.
    public static func category(for code: HomeDiagnosticCode) -> HomeDiagnosticCategory {
        switch code {
        case .emptyHomePageID, .emptySectionID, .duplicateSectionID,
             .invalidSectionPosition, .unsupportedSectionType:
            return .validation
        case .invalidSectionConfiguration:
            return .configuration
        case .rendererNotRegistered:
            return .rendering
        case .sectionHidden, .sectionReplaced:
            return .transformation
        case .missingSectionContent:
            return .content
        case .stateLoading, .stateEmpty, .stateFailed:
            return .state
        }
    }
}

/// Receives diagnostics from validation, composition, rendering, and transformation.
///
/// The library does not print, persist, or transmit diagnostics. Hosts decide
/// how to observe them. Default is ``NoOpHomeComposerDiagnosticReporter``.
public protocol HomeComposerDiagnosticReporting: Sendable {
    func report(_ diagnostic: HomeDiagnostic)
}

/// Additive alias consistent with diagnostic terminology.
public typealias HomeDiagnosticReporter = HomeComposerDiagnosticReporting

extension HomeComposerDiagnosticReporting {
    /// Reports every diagnostic in a validation result.
    public func report(_ result: HomeValidationResult) {
        for diagnostic in result.diagnostics {
            report(diagnostic)
        }
    }
}

/// Silent default reporter used when the host opts out of diagnostics.
public struct NoOpHomeComposerDiagnosticReporter: HomeComposerDiagnosticReporting {
    public init() {}

    public func report(_ diagnostic: HomeDiagnostic) {}
}

/// Deterministic in-memory reporter for tests and local debugging.
///
/// Not a global singleton. Create an instance per test or host session.
public final class CollectingHomeDiagnosticReporter: HomeComposerDiagnosticReporting, @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [HomeDiagnostic] = []

    public init() {}

    public var diagnostics: [HomeDiagnostic] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    public func report(_ diagnostic: HomeDiagnostic) {
        lock.lock()
        storage.append(diagnostic)
        lock.unlock()
    }

    public func reset() {
        lock.lock()
        storage.removeAll(keepingCapacity: true)
        lock.unlock()
    }
}

enum HomeDiagnosticFactory {

    static func rendererNotRegistered(section: ComposedHomeSection) -> HomeDiagnostic {
        HomeDiagnostic(
            severity: .warning,
            code: .rendererNotRegistered,
            message: "No renderer registered for section type '\(section.type.rawValue)'.",
            sectionID: section.id,
            sectionType: section.type
        )
    }

    static func sectionHidden(section: ComposedHomeSection) -> HomeDiagnostic {
        HomeDiagnostic(
            severity: .info,
            code: .sectionHidden,
            message: "Section was hidden by a content transformer.",
            sectionID: section.id,
            sectionType: section.type
        )
    }

    static func sectionReplaced(section: ComposedHomeSection) -> HomeDiagnostic {
        HomeDiagnostic(
            severity: .info,
            code: .sectionReplaced,
            message: "Section content was replaced by a content transformer.",
            sectionID: section.id,
            sectionType: section.type
        )
    }

    static func missingSectionContent(section: HomeSection) -> HomeDiagnostic {
        HomeDiagnostic(
            severity: .info,
            code: .missingSectionContent,
            message: "Section has no content payload.",
            sectionID: section.id,
            sectionType: section.type
        )
    }

    static func stateResolved(
        sectionID: String,
        sectionType: HomeSectionType?,
        state: HomeSectionState
    ) -> HomeDiagnostic? {
        switch state {
        case .loaded:
            return nil
        case .loading:
            return HomeDiagnostic(
                severity: .info,
                code: .stateLoading,
                message: "Section is in a loading presentation state.",
                sectionID: sectionID,
                sectionType: sectionType
            )
        case .empty:
            return HomeDiagnostic(
                severity: .info,
                code: .stateEmpty,
                message: "Section is in an empty presentation state.",
                sectionID: sectionID,
                sectionType: sectionType
            )
        case .failed(let failure):
            var metadata: [String: String] = [:]
            if let code = failure.code {
                metadata["failureCode"] = code
            }
            return HomeDiagnostic(
                severity: .warning,
                code: .stateFailed,
                message: failure.message,
                sectionID: sectionID,
                sectionType: sectionType,
                metadata: metadata
            )
        }
    }
}
