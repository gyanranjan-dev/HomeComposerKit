import SwiftUI

/// Reusable error-state presentation for home sections.
///
/// Retry invokes the existing ``HomeAction`` system. HomeComposerKit does
/// not perform networking or automatic retries.
public struct HomeSectionErrorStateView: View {

    private let configuration: HomeSectionErrorConfiguration
    private let failure: HomeSectionFailure

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme

    public init(
        configuration: HomeSectionErrorConfiguration,
        failure: HomeSectionFailure
    ) {
        self.configuration = configuration
        self.failure = failure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text(configuration.title)
                .font(theme.typography.body.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(displayMessage)
                .font(theme.typography.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let retryTitle = configuration.retryTitle,
               let retryAction = configuration.retryAction {
                Button(retryTitle) {
                    actionHandler.handle(retryAction)
                }
                .font(theme.typography.caption.weight(.semibold))
                .accessibilityLabel(retryTitle)
                .accessibilityHint("Retries loading this section")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.horizontalContentPadding)
        .accessibilityElement(children: hasRetry ? .contain : .combine)
        .accessibilityLabel(
            HomeAccessibilityLabels.errorState(
                title: configuration.title,
                message: displayMessage,
                retryTitle: configuration.retryTitle
            )
        )
    }

    private var displayMessage: String {
        configuration.message ?? failure.message
    }

    private var hasRetry: Bool {
        configuration.retryTitle != nil && configuration.retryAction != nil
    }
}
