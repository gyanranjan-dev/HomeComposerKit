import Foundation
import XCTest
@testable import HomeComposerKit

private final class RecordingDiagnosticReporter: HomeComposerDiagnosticReporting, @unchecked Sendable {
    private let lock = NSLock()
    private var _diagnostics: [HomeDiagnostic] = []

    var diagnostics: [HomeDiagnostic] {
        lock.lock()
        defer { lock.unlock() }
        return _diagnostics
    }

    func report(_ diagnostic: HomeDiagnostic) {
        lock.lock()
        _diagnostics.append(diagnostic)
        lock.unlock()
    }
}

final class ConfigurationResilienceTests: XCTestCase {

    private let decoder = HomePageDecoder()
    private let composer = HomeComposer()
    private let validator = HomePageValidator()

    // MARK: - Versioning

    func testConfigurationVersionDecoding() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "schemaVersion": "2024-01",
            "configurationVersion": "42",
            "title": "Discover",
            "sections": []
        }
        """

        let page = try decoder.decode(json)

        XCTAssertEqual(page.schemaVersion, "2024-01")
        XCTAssertEqual(page.configurationVersion, "42")
        XCTAssertEqual(page.version, "1.0")
    }

    func testMissingVersionFieldsDecodeAsNil() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "sections": []
        }
        """

        let page = try decoder.decode(json)

        XCTAssertNil(page.schemaVersion)
        XCTAssertNil(page.configurationVersion)
    }

    // MARK: - Unknown section types

    func testUnknownSectionTypeDecodingPreservesRawValue() throws {
        let json = """
        {
            "id": "home-001",
            "version": "1.0",
            "sections": [
                {
                    "id": "new-section",
                    "type": "flash_sale_v2",
                    "title": "Flash Sale",
                    "order": 1,
                    "isEnabled": true
                }
            ]
        }
        """

        let page = try decoder.decode(json)

        XCTAssertEqual(page.sections.count, 1)
        XCTAssertEqual(page.sections[0].type, .unknown("flash_sale_v2"))
        XCTAssertEqual(page.sections[0].type.rawValue, "flash_sale_v2")
        XCTAssertFalse(page.sections[0].type.isKnown)
    }

    func testUnknownSectionCompositionDoesNotCrash() throws {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "known", type: .banner, order: 0),
                HomeSection(id: "new-section", type: .unknown("flash_sale_v2"), order: 1)
            ]
        )

        let reporter = RecordingDiagnosticReporter()
        let composed = composer.compose(page, diagnosticReporter: reporter)

        XCTAssertEqual(composed.map(\.id), ["known", "new-section"])
        XCTAssertEqual(composed[1].type, .unknown("flash_sale_v2"))
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .unsupportedSectionType })
    }

    // MARK: - Validation

    func testDuplicateSectionIDsProduceErrorDiagnostics() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "dup", type: .banner, order: 0),
                HomeSection(id: "dup", type: .products, order: 1)
            ]
        )

        let result = validator.validate(page)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == .duplicateSectionID })
    }

    func testEmptySectionIDsProduceErrorDiagnostics() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "   ", type: .banner, order: 0)
            ]
        )

        let result = validator.validate(page)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == .emptySectionID })
    }

    func testInvalidPositionsProduceErrorDiagnostics() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "bad-order", type: .banner, order: -1)
            ]
        )

        let result = validator.validate(page)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == .invalidSectionPosition })
    }

    func testUnsupportedSectionTypeProducesWarningDiagnostic() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "x", type: .unknown("flash_sale_v2"), order: 0)
            ]
        )

        let result = validator.validate(page)

        XCTAssertTrue(result.isValid, "Unknown types are warnings, not hard failures")
        XCTAssertTrue(result.warnings.contains { $0.code == .unsupportedSectionType })
    }

    func testInvalidSectionConfigurationProducesErrorDiagnostics() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "bad-config",
                    type: .products,
                    order: 0,
                    configuration: SectionConfiguration(limit: -5, columns: -1, spacing: -2)
                )
            ]
        )

        let result = validator.validate(page)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(
            result.errors.filter { $0.code == .invalidSectionConfiguration }.count,
            3
        )
    }

    func testValidConfigurationPassesValidation() {
        let result = validator.validate(MockHomePage.sample)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    // MARK: - Diagnostics

    func testDefaultNoOpDiagnosticReporterIsSilent() {
        let reporter = NoOpHomeComposerDiagnosticReporter()
        reporter.report(
            HomeDiagnostic(
                severity: .error,
                code: .emptySectionID,
                message: "test"
            )
        )
        // No crash / no output expected.
    }

    func testCustomDiagnosticReporterReceivesValidationResult() {
        let reporter = RecordingDiagnosticReporter()
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "", type: .banner, order: 0),
                HomeSection(id: "ok", type: .unknown("x"), order: 1)
            ]
        )

        let context = HomeRenderContext(homePage: page)
        let result = context.validate(diagnosticReporter: reporter)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(reporter.diagnostics.count, result.diagnostics.count)
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .emptySectionID })
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .unsupportedSectionType })
    }

    // MARK: - Safe composition

    func testEmptyAndDuplicateAndInvalidSectionsAreSkippedSafely() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "keep", type: .banner, order: 2),
                HomeSection(id: "", type: .products, order: 0),
                HomeSection(id: "keep", type: .social, order: 3),
                HomeSection(id: "negative", type: .categories, order: -4),
                HomeSection(id: "disabled", type: .liveStream, order: 1, isEnabled: false)
            ]
        )

        let composed = composer.compose(page)

        XCTAssertEqual(composed.map(\.id), ["keep"])
    }

    func testMissingContentDoesNotCrashComposition() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "banner", type: .banner, order: 0)
            ]
        )

        let composed = composer.compose(page, contentBySectionID: [:])

        XCTAssertEqual(composed.count, 1)
        XCTAssertNil(composed[0].content)
    }

    func testDisabledSectionsRemainExcluded() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "on", type: .banner, order: 0, isEnabled: true),
                HomeSection(id: "off", type: .products, order: 1, isEnabled: false)
            ]
        )

        let composed = composer.compose(page)

        XCTAssertEqual(composed.map(\.id), ["on"])
    }

    func testOrderingBehaviorRemainsUnchanged() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "c", type: .social, order: 30),
                HomeSection(id: "a", type: .banner, order: 10),
                HomeSection(id: "b", type: .products, order: 20)
            ]
        )

        let composed = composer.compose(page)

        XCTAssertEqual(composed.map(\.id), ["a", "b", "c"])
    }

    func testMalformedJSONRemainsDecodingFailure() {
        XCTAssertThrowsError(try decoder.decode(Data("not-json".utf8))) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Edge cases

    func testEmptyHomePageIDProducesErrorDiagnostic() {
        let page = HomePage(
            id: "  ",
            version: "1.0",
            sections: []
        )

        let result = validator.validate(page)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == .emptyHomePageID })
    }

    func testNilConfigurationDoesNotProduceDiagnostics() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "ok", type: .banner, order: 0, configuration: nil)
            ]
        )

        let result = validator.validate(page)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.diagnostics.isEmpty)
    }

    func testZeroOrderIsValid() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "zero", type: .banner, order: 0)
            ]
        )

        XCTAssertTrue(validator.validate(page).isValid)
        XCTAssertEqual(composer.compose(page).map(\.id), ["zero"])
    }

    func testUnknownSectionTypeRoundTripPreservesRawValue() throws {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "flash", type: .unknown("flash_sale_v2"), order: 1)
            ],
            schemaVersion: "2",
            configurationVersion: "9"
        )

        let data = try JSONEncoder().encode(page)
        let decoded = try decoder.decode(data)

        XCTAssertEqual(decoded.schemaVersion, "2")
        XCTAssertEqual(decoded.configurationVersion, "9")
        let decodedType = decoded.sections[0].type
        XCTAssertEqual(decodedType, HomeSectionType.unknown("flash_sale_v2"))
        XCTAssertEqual(decodedType.rawValue, "flash_sale_v2")
    }

    func testEqualOrderPreservesOriginalAPIOrderWithUnknownTypes() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "first", type: .unknown("alpha"), order: 1),
                HomeSection(id: "second", type: .banner, order: 1),
                HomeSection(id: "third", type: .unknown("beta"), order: 1)
            ]
        )

        let composed = composer.compose(page)

        XCTAssertEqual(composed.map(\.id), ["first", "second", "third"])
    }

    func testInvalidConfigurationIsSkippedDuringComposition() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "bad",
                    type: .products,
                    order: 0,
                    configuration: SectionConfiguration(limit: -1)
                ),
                HomeSection(id: "good", type: .banner, order: 1)
            ]
        )

        let reporter = RecordingDiagnosticReporter()
        let composed = composer.compose(page, diagnosticReporter: reporter)

        XCTAssertEqual(composed.map(\.id), ["good"])
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .invalidSectionConfiguration })
    }

    func testBuilderValidateFlagReportsDiagnosticsWithoutThrowing() throws {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "dup", type: .banner, order: 0),
                HomeSection(id: "dup", type: .products, order: 1)
            ]
        )
        let data = try JSONEncoder().encode(page)
        let reporter = RecordingDiagnosticReporter()

        let context = try HomeRenderContextBuilder().makeContext(
            from: data,
            validate: true,
            diagnosticReporter: reporter
        )

        XCTAssertEqual(context.homePage.id, "home-001")
        XCTAssertFalse(reporter.diagnostics.isEmpty)
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .duplicateSectionID })
    }

    func testWhitespaceDuplicateIDsAreTreatedAsDuplicates() {
        let page = HomePage(
            id: "home-001",
            version: "1.0",
            sections: [
                HomeSection(id: "same", type: .banner, order: 0),
                HomeSection(id: " same ", type: .products, order: 1)
            ]
        )

        let result = validator.validate(page)
        let composed = composer.compose(page)

        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.code == .duplicateSectionID })
        XCTAssertEqual(composed.map(\.id), ["same"])
    }
}
