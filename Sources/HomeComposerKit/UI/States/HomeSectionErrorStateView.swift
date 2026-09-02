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

            Text(displayMessage)
                .font(theme.typography.caption)
                .foregroundStyle(.secondary)

            if let retryTitle = configuration.retryTitle,
               let retryAction = configuration.retryAction {
                Button(retryTitle) {
                    actionHandler.handle(retryAction)
                }
                .font(theme.typography.caption.weight(.semibold))
                .accessibilityLabel(retryTitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.horizontalContentPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayMessage: String {
        configuration.message ?? failure.message
    }

    private var accessibilityLabel: String {
        var parts = [configuration.title, displayMessage]
        if let retryTitle = configuration.retryTitle {
            parts.append(retryTitle)
        }
        return parts.joined(separator: ". ")
    }
}
