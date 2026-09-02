import SwiftUI

private struct HomeSectionStatesKey: EnvironmentKey {
    static let defaultValue: [String: HomeSectionState] = [:]
}

private struct HomeSectionStateConfigurationKey: EnvironmentKey {
    static let defaultValue = HomeSectionStateConfiguration.default
}

extension EnvironmentValues {

    /// Host-provided presentation states keyed by section `id`.
    ///
    /// When a section id is absent, built-in renderers preserve legacy content
    /// rendering behavior.
    public var homeSectionStates: [String: HomeSectionState] {
        get { self[HomeSectionStatesKey.self] }
        set { self[HomeSectionStatesKey.self] = newValue }
    }

    /// Customizable loading, empty, and error presentation for sections.
    public var homeSectionStateConfiguration: HomeSectionStateConfiguration {
        get { self[HomeSectionStateConfigurationKey.self] }
        set { self[HomeSectionStateConfigurationKey.self] = newValue }
    }
}

extension View {

    /// Installs host-provided section presentation states.
    public func homeSectionStates(_ states: [String: HomeSectionState]) -> some View {
        environment(\.homeSectionStates, states)
    }

    /// Installs section state presentation configuration.
    public func homeSectionStateConfiguration(_ configuration: HomeSectionStateConfiguration) -> some View {
        environment(\.homeSectionStateConfiguration, configuration)
    }
}
