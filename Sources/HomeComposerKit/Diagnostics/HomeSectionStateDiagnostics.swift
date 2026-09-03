import Foundation

/// Reports section presentation state diagnostics without coupling to SwiftUI.
enum HomeSectionStateDiagnostics {

    static func report(
        sectionStates: [String: HomeSectionState],
        sections: [ComposedHomeSection],
        reporter: any HomeComposerDiagnosticReporting
    ) {
        guard !sectionStates.isEmpty else {
            return
        }

        let typesByID = Dictionary(uniqueKeysWithValues: sections.map { ($0.id, $0.type) })

        for (sectionID, state) in sectionStates.sorted(by: { $0.key < $1.key }) {
            guard let diagnostic = HomeDiagnosticFactory.stateResolved(
                sectionID: sectionID,
                sectionType: typesByID[sectionID],
                state: state
            ) else {
                continue
            }
            reporter.report(diagnostic)
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI

/// Observes section state changes and reports diagnostics once per change.
struct HomeSectionStateDiagnosticObserver: View {
    let sectionStates: [String: HomeSectionState]
    let sections: [ComposedHomeSection]
    let reporter: any HomeComposerDiagnosticReporting

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear(perform: report)
            .onChange(of: sectionStates) { _ in
                report()
            }
    }

    private func report() {
        HomeSectionStateDiagnostics.report(
            sectionStates: sectionStates,
            sections: sections,
            reporter: reporter
        )
    }
}
#endif
