import Foundation

/// Backend envelope for a home-page configuration response.
///
/// This is the public API-contract boundary between host networking and
/// HomeComposerKit. The host fetches JSON; this type decodes it.
///
/// Forward compatibility:
/// - Unknown JSON keys are ignored by `Codable`
/// - Unknown section `type` values decode as ``HomeSectionType/unknown(_:)``
/// - Optional version/metadata fields may be omitted
///
/// Typical host flow:
/// ```swift
/// let response = try HomeAPIResponseDecoder().decode(data)
/// let homePage = response.makeHomePage()
/// let context = HomeRenderContextBuilder().makeContext(
///     from: response,
///     contentBySectionID: resolvedContent
/// )
/// ```
public struct HomeAPIResponse: Codable, Sendable, Identifiable {

    /// Home / page identifier.
    public let id: String
    /// Legacy or document version. Optional for minimal payloads.
    public let version: String?
    public let title: String?
    public let schemaVersion: String?
    public let configurationVersion: String?
    public let sections: [HomeAPISection]
    public let metadata: HomeAPIMetadata?

    public init(
        id: String,
        version: String? = nil,
        title: String? = nil,
        schemaVersion: String? = nil,
        configurationVersion: String? = nil,
        sections: [HomeAPISection],
        metadata: HomeAPIMetadata? = nil
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.schemaVersion = schemaVersion
        self.configurationVersion = configurationVersion
        self.sections = sections
        self.metadata = metadata
    }

    /// Converts the API envelope into the existing ``HomePage`` model.
    ///
    /// - Parameter defaultVersion: Used when `version` is absent (minimal payloads).
    ///   ``configurationVersion`` is mapped independently and is not used as a
    ///   fallback for ``HomePage/version``.
    public func makeHomePage(defaultVersion: String = "1.0") -> HomePage {
        HomePage(
            id: id,
            version: version ?? defaultVersion,
            title: title,
            sections: sections.map { $0.makeHomeSection() },
            schemaVersion: schemaVersion,
            configurationVersion: configurationVersion
        )
    }

    /// Section content references keyed by section `id`.
    ///
    /// Hosts resolve these references into ``HomeSectionContent`` values using
    /// their own networking/cache layer.
    public var contentReferencesBySectionID: [String: String] {
        var result: [String: String] = [:]
        for section in sections {
            if let contentRef = section.contentRef {
                result[section.id] = contentRef
            }
        }
        return result
    }
}
