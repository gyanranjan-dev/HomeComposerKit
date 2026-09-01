import Foundation
import SwiftUI
import XCTest
@testable import HomeComposerKit

@MainActor
final class HomeContentProviderTests: XCTestCase {

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    // MARK: - HomeImageSource Codable

    func testRemoteURLImageSourceRoundTrip() throws {
        let source = HomeImageSource.remote(URL(string: "https://example.com/image.jpg")!)
        let decoded = try roundTrip(source)

        guard case .remote(let url) = decoded else {
            return XCTFail("Expected remote source")
        }
        XCTAssertEqual(url.absoluteString, "https://example.com/image.jpg")
    }

    func testAssetImageSourceRoundTrip() throws {
        let source = HomeImageSource.asset(name: "hero-banner")
        let decoded = try roundTrip(source)

        XCTAssertEqual(decoded, .asset(name: "hero-banner"))
    }

    func testSystemSymbolImageSourceRoundTrip() throws {
        let source = HomeImageSource.system(name: "photo")
        let decoded = try roundTrip(source)

        XCTAssertEqual(decoded, .system(name: "photo"))
    }

    func testNoneImageSourceRoundTrip() throws {
        let source = HomeImageSource.none
        let decoded = try roundTrip(source)

        XCTAssertEqual(decoded, .none)
    }

    func testUnknownImageSourceDecodingDoesNotCrash() throws {
        let decoded = try decodeSource("""
        { "type": "futureSource", "token": "abc" }
        """)

        XCTAssertEqual(decoded, .unknown("futureSource"))
        XCTAssertFalse(decoded.isKnown)
    }

    func testMalformedImageSourceFallsBackToNone() throws {
        XCTAssertEqual(try decodeSource("{}"), .none)
        XCTAssertEqual(try decodeSource("{ \"type\": \"remote\" }"), .none)
        XCTAssertEqual(try decodeSource("{ \"type\": \"asset\" }"), .none)
        XCTAssertEqual(try decodeSource("{ \"type\": \"system\" }"), .none)
        XCTAssertEqual(
            try decodeSource("{ \"type\": \"remote\", \"url\": \"not a url\" }"),
            .none
        )
    }

    func testURLInitializerMapsNilToNone() {
        XCTAssertEqual(HomeImageSource(url: nil), .none)
        XCTAssertEqual(
            HomeImageSource(url: URL(string: "https://example.com/a.png")),
            .remote(URL(string: "https://example.com/a.png")!)
        )
    }

    // MARK: - HomeImageProvider

    func testDefaultProviderDoesNotPerformNetworking() {
        XCTAssertFalse(frameworkSourcesContainNetworkingSymbols())
    }

    func testCustomImageProviderCanBeInjected() {
        let provider = HomeImageProvider { source, _ in
            Text(source.typeName)
        }

        _ = provider.image(
            for: .remote(URL(string: "https://example.com/x.png")!),
            contentMode: .fill
        )
    }

    func testDefaultProviderRendersSystemSymbolsLocally() {
        _ = HomeImageProvider.placeholder.image(
            for: .system(name: "photo"),
            contentMode: .fill
        )
    }

    // MARK: - Environment

    func testImageProviderEnvironmentIsAccessible() {
        var environment = EnvironmentValues()
        XCTAssertNotNil(environment.homeImageProvider)

        let custom = HomeImageProvider { _, _ in
            Text("custom")
        }
        environment.homeImageProvider = custom
        _ = environment.homeImageProvider.image(for: .none, contentMode: .fill)
    }

    func testContentProviderEnvironmentIsAccessible() async throws {
        var environment = EnvironmentValues()
        let content = try await environment.homeContentProvider.content(
            for: HomeContentRequest(reference: "content://products/1")
        )
        XCTAssertNil(content)

        environment.homeContentProvider = HomeContentProvider { _ in
            .products(ProductSection(products: []))
        }
        let resolved = try await environment.homeContentProvider.content(
            for: HomeContentRequest(reference: "content://products/1")
        )
        XCTAssertEqual(resolved, .products(ProductSection(products: [])))
    }

    // MARK: - HomeContentProvider

    func testCustomContentProviderReturnsHostContent() async throws {
        let expected = HomeSectionContent.products(
            ProductSection(products: [
                Product(
                    id: "prod-1",
                    name: "Sample",
                    price: 10,
                    currency: "USD"
                )
            ])
        )

        let provider = HomeContentProvider { request in
            XCTAssertEqual(request.reference, "content://products/1")
            return expected
        }

        let content = try await provider.content(
            for: HomeContentRequest(reference: "content://products/1")
        )
        XCTAssertEqual(content, expected)
    }

    // MARK: - Backward compatibility

    func testRemoteImageViewInitializerRemainsCompatibleWithURL() {
        _ = RemoteImageView(url: URL(string: "https://example.com/image.jpg"))
        _ = RemoteImageView(url: nil)
    }

    func testHomeComposerViewInitializerRemainsCompatibleWithoutProviders() {
        _ = HomeComposerView(homePage: MockHomePage.sample)
        _ = HomeComposerView(
            homePage: MockHomePage.sample,
            contentBySectionID: MockHomePage.sampleContent
        )
    }

    func testExistingModelDecodingRemainsUnchanged() throws {
        let product = try jsonDecoder.decode(
            Product.self,
            from: Data("""
            {
                "id": "prod-1",
                "name": "Headphones",
                "price": 199.99,
                "currency": "USD",
                "isFavorite": false,
                "imageURL": "https://example.com/headphones.jpg"
            }
            """.utf8)
        )

        XCTAssertEqual(product.imageURL?.absoluteString, "https://example.com/headphones.jpg")
        XCTAssertEqual(HomeImageSource(url: product.imageURL), .remote(product.imageURL!))
    }

    // MARK: - Helpers

    private func roundTrip(_ source: HomeImageSource) throws -> HomeImageSource {
        let data = try jsonEncoder.encode(source)
        return try jsonDecoder.decode(HomeImageSource.self, from: data)
    }

    private func decodeSource(_ json: String) throws -> HomeImageSource {
        try jsonDecoder.decode(HomeImageSource.self, from: Data(json.utf8))
    }

    private func frameworkSourcesContainNetworkingSymbols() -> Bool {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/HomeComposerKit")

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            return true
        }

        let bannedSymbols = ["URLSession", "AsyncImage"]
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
                continue
            }
            if bannedSymbols.contains(where: { contents.contains($0) }) {
                return true
            }
        }
        return false
    }
}
