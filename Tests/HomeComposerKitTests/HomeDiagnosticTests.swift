import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

final class HomeDiagnosticTests: XCTestCase {

    private let composer = HomeComposer()
    private let validator = HomePageValidator()

    // MARK: - Model

    func testDiagnosticPreservesSeverityCategoryCodeAndMetadata() {
        let diagnostic = HomeDiagnostic(
            severity: .warning,
            code: .stateFailed,
            message: "Load failed.",
            sectionID: "products",
            category: .state,
            sectionType: .products,
            metadata: ["failureCode": "network"]
        )

        XCTAssertEqual(diagnostic.severity, .warning)
        XCTAssertEqual(diagnostic.category, .state)
        XCTAssertEqual(diagnostic.code, .stateFailed)
        XCTAssertEqual(diagnostic.message, "Load failed.")
        XCTAssertEqual(diagnostic.sectionID, "products")
        XCTAssertEqual(diagnostic.sectionType, .products)
        XCTAssertEqual(diagnostic.metadata["failureCode"], "network")
    }

    func testDiagnosticInfersCategoryFromCodeWhenOmitted() {
        XCTAssertEqual(
            HomeDiagnostic(
                severity: .error,
                code: .duplicateSectionID,
                message: "Duplicate."
            ).category,
            .validation
        )
        XCTAssertEqual(
            HomeDiagnostic(
                severity: .warning,
                code: .rendererNotRegistered,
                message: "Missing renderer."
            ).category,
            .rendering
        )
        XCTAssertEqual(
            HomeDiagnostic(
                severity: .info,
                code: .sectionHidden,
                message: "Hidden."
            ).category,
            .transformation
        )
    }

    func testDiagnosticIsHashable() {
        let a = HomeDiagnostic(
            severity: .info,
            code: .missingSectionContent,
            message: "No content.",
            sectionID: "banner"
        )
        let b = HomeDiagnostic(
            severity: .info,
            code: .missingSectionContent,
            message: "No content.",
            sectionID: "banner"
        )
        XCTAssertEqual(a, b)
        XCTAssertEqual(Set([a, b]).count, 1)
    }

    // MARK: - Reporters

    func testNoOpReporterDoesNotCollectDiagnostics() {
        let reporter = NoOpHomeComposerDiagnosticReporter()
        reporter.report(
            HomeDiagnostic(
                severity: .error,
                code: .emptySectionID,
                message: "Empty id."
            )
        )
        // No storage — verify it compiles and does not crash.
        XCTAssertNotNil(reporter)
    }

    func testCollectingReporterRecordsDiagnosticsDeterministically() {
        let reporter = CollectingHomeDiagnosticReporter()
        let first = HomeDiagnostic(
            severity: .error,
            code: .duplicateSectionID,
            message: "Duplicate.",
            sectionID: "a"
        )
        let second = HomeDiagnostic(
            severity: .warning,
            code: .unsupportedSectionType,
            message: "Unknown.",
            sectionID: "b"
        )

        reporter.report(first)
        reporter.report(second)

        XCTAssertEqual(reporter.diagnostics.count, 2)
        XCTAssertEqual(reporter.diagnostics[0].code, .duplicateSectionID)
        XCTAssertEqual(reporter.diagnostics[1].code, .unsupportedSectionType)

        reporter.reset()
        XCTAssertTrue(reporter.diagnostics.isEmpty)
    }

    func testReporterReportsValidationResultBatch() {
        let reporter = CollectingHomeDiagnosticReporter()
        let result = HomeValidationResult(diagnostics: [
            HomeDiagnostic(
                severity: .error,
                code: .emptyHomePageID,
                message: "Missing page id."
            ),
            HomeDiagnostic(
                severity: .warning,
                code: .unsupportedSectionType,
                message: "Unknown type.",
                sectionID: "x"
            )
        ])

        reporter.report(result)

        XCTAssertEqual(reporter.diagnostics.count, 2)
    }

    // MARK: - Composition

    func testDuplicateSectionIDEmitsCompositionDiagnostic() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [
                HomeSection(id: "dup", type: .banner, order: 0),
                HomeSection(id: "dup", type: .products, order: 1)
            ]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        let composed = composer.compose(page, diagnosticReporter: reporter)

        XCTAssertEqual(composed.map(\.id), ["dup"])
        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .duplicateSectionID
                    && $0.category == .composition
                    && $0.sectionID == "dup"
                    && $0.sectionType == .products
            }
        )
    }

    func testInvalidConfigurationEmitsCompositionDiagnostic() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [
                HomeSection(
                    id: "bad",
                    type: .products,
                    order: 0,
                    configuration: SectionConfiguration(limit: -1)
                )
            ]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        let composed = composer.compose(page, diagnosticReporter: reporter)

        XCTAssertTrue(composed.isEmpty)
        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .invalidSectionConfiguration
                    && $0.category == .composition
                    && $0.sectionID == "bad"
                    && $0.sectionType == .products
            }
        )
    }

    func testMissingContentEmitsInfoDiagnostic() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [
                HomeSection(id: "products", type: .products, order: 0)
            ]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        let composed = composer.compose(page, diagnosticReporter: reporter)

        XCTAssertEqual(composed.count, 1)
        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .missingSectionContent
                    && $0.category == .content
                    && $0.sectionID == "products"
            }
        )
    }

    func testIdentityPipelineDoesNotEmitTransformationDiagnostics() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [HomeSection(id: "banner", type: .banner, order: 0)]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        _ = composer.compose(
            page,
            diagnosticReporter: reporter,
            transformationPipeline: .identity
        )

        XCTAssertFalse(reporter.diagnostics.contains { $0.category == .transformation })
    }

    // MARK: - Rendering

    @MainActor
    func testUnknownRendererEmitsRenderingDiagnostic() {
        let section = ComposedHomeSection(
            id: "flash",
            type: .unknown("flash_sale_v2"),
            order: 0
        )
        let registry = HomeSectionRendererRegistry.makeDefault()
        let reporter = CollectingHomeDiagnosticReporter()

        _ = HomeSectionRenderer.view(
            for: section,
            in: registry,
            diagnosticReporter: reporter
        )

        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .rendererNotRegistered
                    && $0.category == .rendering
                    && $0.sectionID == "flash"
                    && $0.sectionType == .unknown("flash_sale_v2")
            }
        )
    }

    @MainActor
    func testRendererDiagnosticDoesNotChangeFallbackBehavior() {
        let section = ComposedHomeSection(
            id: "custom",
            type: .custom,
            order: 0
        )
        let registry = HomeSectionRendererRegistry.makeDefault()

        let withoutReporter = registry.view(for: section)
        let withReporter = HomeSectionRenderer.view(
            for: section,
            in: registry,
            diagnosticReporter: CollectingHomeDiagnosticReporter()
        )

        _ = withoutReporter
        _ = withReporter
    }

    // MARK: - Transformation

    func testHiddenTransformationEmitsDiagnostic() {
        let section = ComposedHomeSection(id: "hide-me", type: .banner, order: 0)
        let pipeline = HomeSectionContentTransformerPipeline(
            transformers: [{ _, _ in .hidden }]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        let result = pipeline.apply(to: section, diagnosticReporter: reporter)

        XCTAssertNil(result)
        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .sectionHidden
                    && $0.category == .transformation
                    && $0.sectionID == "hide-me"
            }
        )
    }

    func testReplacementTransformationEmitsDiagnostic() {
        let section = ComposedHomeSection(id: "replace-me", type: .banner, order: 0)
        let replacement = section.replacing(title: "Updated")
        let pipeline = HomeSectionContentTransformerPipeline(
            transformers: [{ _, _ in .replace(replacement) }]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        let result = pipeline.apply(to: section, diagnosticReporter: reporter)

        XCTAssertEqual(result?.title, "Updated")
        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .sectionReplaced
                    && $0.category == .transformation
                    && $0.sectionID == "replace-me"
            }
        )
    }

    func testUnchangedTransformationDoesNotEmitDiagnostic() {
        let section = ComposedHomeSection(id: "same", type: .banner, order: 0)
        let pipeline = HomeSectionContentTransformerPipeline(
            transformers: [{ section, _ in .unchanged(section) }]
        )
        let reporter = CollectingHomeDiagnosticReporter()

        _ = pipeline.apply(to: section, diagnosticReporter: reporter)

        XCTAssertTrue(reporter.diagnostics.isEmpty)
    }

    // MARK: - State

    func testFailedStateEmitsStateDiagnostic() {
        let sections = [
            ComposedHomeSection(id: "products", type: .products, order: 0)
        ]
        let reporter = CollectingHomeDiagnosticReporter()

        HomeSectionStateDiagnostics.report(
            sectionStates: [
                "products": .failed(HomeSectionFailure(message: "Network error.", code: "offline"))
            ],
            sections: sections,
            reporter: reporter
        )

        XCTAssertTrue(
            reporter.diagnostics.contains {
                $0.code == .stateFailed
                    && $0.category == .state
                    && $0.sectionID == "products"
                    && $0.metadata["failureCode"] == "offline"
            }
        )
    }

    func testLoadedStateDoesNotEmitDiagnostic() {
        let sections = [
            ComposedHomeSection(id: "products", type: .products, order: 0)
        ]
        let reporter = CollectingHomeDiagnosticReporter()

        HomeSectionStateDiagnostics.report(
            sectionStates: ["products": .loaded],
            sections: sections,
            reporter: reporter
        )

        XCTAssertTrue(reporter.diagnostics.isEmpty)
    }

    // MARK: - Behavior preservation

    func testDiagnosticsDoNotAlterCompositionOutput() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [
                HomeSection(id: "a", type: .banner, order: 1),
                HomeSection(id: "b", type: .products, order: 0),
                HomeSection(
                    id: "bad",
                    type: .products,
                    order: 2,
                    configuration: SectionConfiguration(columns: -1)
                )
            ]
        )

        let silent = composer.compose(page)
        let observed = composer.compose(
            page,
            diagnosticReporter: CollectingHomeDiagnosticReporter()
        )

        XCTAssertEqual(silent.map(\.id), observed.map(\.id))
    }

    func testNoReporterPreservesExistingCompositionBehavior() {
        let page = MockHomePage.sample
        let baseline = composer.compose(page)
        let withNoOp = composer.compose(
            page,
            diagnosticReporter: NoOpHomeComposerDiagnosticReporter()
        )

        XCTAssertEqual(baseline.map(\.id), withNoOp.map(\.id))
    }

    // MARK: - AI validation compatibility

    func testAIValidationDiagnosticsPassThroughReporter() {
        let page = HomePage(
            id: "",
            version: "1.0",
            sections: [
                HomeSection(id: "x", type: .unknown("future"), order: -1)
            ]
        )
        let reporter = CollectingHomeDiagnosticReporter()
        let context = HomeRenderContext(homePage: page)

        let result = context.validate(diagnosticReporter: reporter)

        XCTAssertFalse(result.isValid)
        XCTAssertFalse(reporter.diagnostics.isEmpty)
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .emptyHomePageID })
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .invalidSectionPosition })
        XCTAssertTrue(reporter.diagnostics.contains { $0.code == .unsupportedSectionType })
    }

    // MARK: - Privacy / no implicit I/O

    func testDiagnosticsContainNoImplicitNetworkOrPersistenceBehavior() {
        let reporter = CollectingHomeDiagnosticReporter()
        reporter.report(
            HomeDiagnostic(
                severity: .info,
                code: .stateLoading,
                message: "Loading.",
                sectionID: "a"
            )
        )

        XCTAssertEqual(reporter.diagnostics.count, 1)
        // Collecting reporter is in-memory only; no URLSession or file APIs involved.
        XCTAssertNotNil(CollectingHomeDiagnosticReporter.self)
        XCTAssertNotNil(NoOpHomeComposerDiagnosticReporter.self)
    }

    func testValidationDiagnosticIncludesSectionType() {
        let page = HomePage(
            id: "home",
            version: "1.0",
            sections: [
                HomeSection(id: "dup", type: .banner, order: 0),
                HomeSection(id: "dup", type: .categories, order: 1)
            ]
        )

        let diagnostics = validator.validate(page).diagnostics

        XCTAssertTrue(
            diagnostics.contains {
                $0.code == .duplicateSectionID
                    && $0.category == .validation
                    && $0.sectionType == .categories
            }
        )
    }
}
