import SwiftUI

/// Reusable empty-state presentation for home sections.
public struct HomeSectionEmptyStateView: View {

    private let configuration: HomeSectionEmptyConfiguration

    @Environment(\.homeActionHandler) private var actionHandler
    @Environment(\.homeComposerTheme) private var theme

    public init(configuration: HomeSectionEmptyConfiguration) {
        self.configuration = configuration
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text(configuration.title)
                .font(theme.typography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isStaticText)

            if let message = configuration.message {
                Text(message)
                    .font(theme.typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle = configuration.actionTitle,
               let action = configuration.action {
                Button(actionTitle) {
                    actionHandler.handle(action)
                }
                .font(theme.typography.caption.weight(.semibold))
                .accessibilityLabel(actionTitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.horizontalContentPadding)
        .accessibilityElement(children: hasAction ? .contain : .combine)
        .accessibilityLabel(
            HomeAccessibilityLabels.emptyState(
                title: configuration.title,
                message: configuration.message
            )
        )
    }

    private var hasAction: Bool {
        configuration.actionTitle != nil && configuration.action != nil
    }
}
