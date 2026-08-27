import SwiftUI

extension ComposedHomeSection {

    var presentationConfiguration: SectionConfiguration {
        configuration ?? SectionConfiguration()
    }

    var hasNonEmptyTitle: Bool {
        !(title ?? "").isEmpty
    }

    var effectiveShowTitle: Bool {
        presentationConfiguration.effectiveShowTitle(hasTitle: hasNonEmptyTitle)
    }

    var effectiveShowSeeAll: Bool {
        presentationConfiguration.effectiveShowSeeAll
    }

    var effectiveLayout: HomeSectionLayout {
        presentationConfiguration.effectiveLayout(for: type)
    }

    var effectiveSpacing: CGFloat {
        CGFloat(presentationConfiguration.effectiveSpacing)
    }

    func effectiveColumns(default defaultValue: Int = 2) -> Int {
        presentationConfiguration.effectiveColumns(default: defaultValue)
    }
}
