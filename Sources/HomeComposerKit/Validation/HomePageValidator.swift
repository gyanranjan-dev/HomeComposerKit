import Foundation

/// Outcome of validating a ``HomePage`` configuration.
public struct HomeValidationResult: Sendable, Equatable {
    public let diagnostics: [HomeDiagnostic]

    public init(diagnostics: [HomeDiagnostic]) {
        self.diagnostics = diagnostics
    }

    /// `true` when no error-severity diagnostics were produced.
    public var isValid: Bool {
        !diagnostics.contains { $0.severity == .error }
    }

    public var errors: [HomeDiagnostic] {
        diagnostics.filter { $0.severity == .error }
    }

    public var warnings: [HomeDiagnostic] {
        diagnostics.filter { $0.severity == .warning }
    }

    public var infos: [HomeDiagnostic] {
        diagnostics.filter { $0.severity == .info }
    }
}

/// Validates a ``HomePage`` for structural issues before composition.
///
/// Validation is advisory: it does not mutate the page. Hosts decide whether
/// to block rendering based on ``HomeValidationResult/isValid``.
public struct HomePageValidator: Sendable {

    public init() {}

    /// Validates the home page and returns structured diagnostics.
    public func validate(_ homePage: HomePage) -> HomeValidationResult {
        var diagnostics: [HomeDiagnostic] = []

        if homePage.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            diagnostics.append(
                HomeDiagnostic(
                    severity: .error,
                    code: .emptyHomePageID,
                    message: "Home page id must not be empty."
                )
            )
        }

        var seenIDs = Set<String>()

        for section in homePage.sections {
            let trimmedID = section.id.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedID.isEmpty {
                diagnostics.append(
                    HomeDiagnostic(
                        severity: .error,
                        code: .emptySectionID,
                        message: "Section id must not be empty.",
                        sectionID: section.id
                    )
                )
            } else if seenIDs.contains(trimmedID) {
                diagnostics.append(
                    HomeDiagnostic(
                        severity: .error,
                        code: .duplicateSectionID,
                        message: "Duplicate section id '\(trimmedID)'.",
                        sectionID: trimmedID
                    )
                )
            } else {
                seenIDs.insert(trimmedID)
            }

            if section.order < 0 {
                diagnostics.append(
                    HomeDiagnostic(
                        severity: .error,
                        code: .invalidSectionPosition,
                        message: "Section order must be >= 0 (found \(section.order)).",
                        sectionID: section.id
                    )
                )
            }

            if !section.type.isKnown {
                diagnostics.append(
                    HomeDiagnostic(
                        severity: .warning,
                        code: .unsupportedSectionType,
                        message: "Unsupported section type '\(section.type.rawValue)'.",
                        sectionID: section.id
                    )
                )
            }

            if let configuration = section.configuration {
                diagnostics.append(
                    contentsOf: validateConfiguration(configuration, sectionID: section.id)
                )
            }
        }

        return HomeValidationResult(diagnostics: diagnostics)
    }

    private func validateConfiguration(
        _ configuration: SectionConfiguration,
        sectionID: String
    ) -> [HomeDiagnostic] {
        var diagnostics: [HomeDiagnostic] = []

        if let limit = configuration.limit, limit < 0 {
            diagnostics.append(
                HomeDiagnostic(
                    severity: .error,
                    code: .invalidSectionConfiguration,
                    message: "Section configuration limit must be >= 0.",
                    sectionID: sectionID
                )
            )
        }

        if let columns = configuration.columns, columns < 0 {
            diagnostics.append(
                HomeDiagnostic(
                    severity: .error,
                    code: .invalidSectionConfiguration,
                    message: "Section configuration columns must be >= 0.",
                    sectionID: sectionID
                )
            )
        }

        if let spacing = configuration.spacing, spacing < 0 {
            diagnostics.append(
                HomeDiagnostic(
                    severity: .error,
                    code: .invalidSectionConfiguration,
                    message: "Section configuration spacing must be >= 0.",
                    sectionID: sectionID
                )
            )
        }

        return diagnostics
    }
}
