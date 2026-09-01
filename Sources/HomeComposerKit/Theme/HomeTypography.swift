import SwiftUI

/// Dynamic Type friendly typography roles for HomeComposerKit surfaces.
public struct HomeTypography: Sendable {
    public let pageTitle: Font
    public let sectionTitle: Font
    public let body: Font
    public let caption: Font
    public let price: Font
    public let emphasis: Font

    public init(
        pageTitle: Font,
        sectionTitle: Font,
        body: Font,
        caption: Font,
        price: Font,
        emphasis: Font
    ) {
        self.pageTitle = pageTitle
        self.sectionTitle = sectionTitle
        self.body = body
        self.caption = caption
        self.price = price
        self.emphasis = emphasis
    }

    public static let `default` = HomeTypography(
        pageTitle: .largeTitle.bold(),
        sectionTitle: .title3.weight(.semibold),
        body: .subheadline,
        caption: .caption,
        price: .subheadline,
        emphasis: .subheadline.weight(.semibold)
    )
}
