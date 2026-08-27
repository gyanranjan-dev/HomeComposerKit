import Foundation

/// Receives ``HomeAction`` values emitted by the home UI layer.
///
/// The host application implements navigation and business behavior; the kit
/// only describes what the user interacted with.
public protocol HomeActionHandling {
    func handle(_ action: HomeAction)
}

/// Closure-backed action handler for ergonomic host integration.
public struct HomeActionHandler: HomeActionHandling, @unchecked Sendable {

    private let handler: (HomeAction) -> Void

    /// Creates a handler from a closure.
    public init(_ handler: @escaping (HomeAction) -> Void) {
        self.handler = handler
    }

    /// Creates a handler from any ``HomeActionHandling`` implementation.
    public init<H: HomeActionHandling>(_ handler: H) {
        self.handler = { handler.handle($0) }
    }

    public func handle(_ action: HomeAction) {
        handler(action)
    }

    /// A handler that ignores all actions.
    public static let noop = HomeActionHandler { _ in }
}

/// Captures actions in tests or diagnostics.
public final class HomeActionRecorder: HomeActionHandling {
    private var storedActions: [HomeAction] = []

    public init() {}

    public var actions: [HomeAction] {
        storedActions
    }

    public func handle(_ action: HomeAction) {
        storedActions.append(action)
    }

    public func reset() {
        storedActions.removeAll()
    }
}
