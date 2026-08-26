import Foundation

/// A live stream item displayed in a home page section.
public struct LiveStream: Codable, Identifiable, Equatable, Sendable {

    public let id: String
    public let title: String
    public let streamURL: URL?
    public let thumbnailURL: URL?
    public let isLive: Bool

    public init(
        id: String,
        title: String,
        streamURL: URL? = nil,
        thumbnailURL: URL? = nil,
        isLive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.streamURL = streamURL
        self.thumbnailURL = thumbnailURL
        self.isLive = isLive
    }
}

/// A live stream section containing a list of live streams.
public struct LiveSection: Codable, Equatable, Sendable {

    public let streams: [LiveStream]

    public init(streams: [LiveStream]) {
        self.streams = streams
    }
}
