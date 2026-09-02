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

            if let message = configuration.message {
                Text(message)
                    .font(theme.typography.caption)
                    .foregroundStyle(.secondary)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let message = configuration.message {
            return "\(configuration.title). \(message)"
        }
        return configuration.title
    }
}
