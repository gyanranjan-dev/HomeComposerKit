import Foundation

/// Host-implemented source of home page configuration.
///
/// HomeComposerKit never performs networking. The host application:
/// 1. Fetches JSON with its own networking / authentication stack
/// 2. Implements this protocol (or calls ``HomeRenderContextBuilder`` with `Data`)
/// 3. Lets the kit decode (if needed), compose, and render
///
/// ```text
/// Host App
///   → host networking
///   → Data / HomePage
///   → HomeComposerKit (decode → compose → SwiftUI)
/// ```
public protocol HomePageProviding: Sendable {
    /// Returns a decoded home page ready for composition.
    func makeHomePage() throws -> HomePage
}

/// Host-implemented source of raw home page JSON.
///
/// Prefer this when the host holds `Data` from a network response and wants
/// HomeComposerKit to perform decoding via ``HomePageDecoder``.
public protocol HomePageDataProviding: Sendable {
    /// Returns UTF-8 JSON bytes for a home page configuration.
    func makeHomePageData() throws -> Data
}

/// In-memory ``HomePageProviding`` for tests, previews, and static host fixtures.
public struct StaticHomePageProvider: HomePageProviding {
    private let homePage: HomePage

    public init(_ homePage: HomePage) {
        self.homePage = homePage
    }

    public func makeHomePage() throws -> HomePage {
        homePage
    }
}

/// In-memory ``HomePageDataProviding`` for tests and host fixtures.
public struct StaticHomePageDataProvider: HomePageDataProviding {
    private let data: Data

    public init(_ data: Data) {
        self.data = data
    }

    public func makeHomePageData() throws -> Data {
        data
    }
}
