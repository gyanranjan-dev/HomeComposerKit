import Foundation

/// A social post displayed in a home page section.
public struct SocialPost: Codable, Identifiable, Equatable, Sendable {

    public let id: String
    public let author: String
    public let content: String?
    public let imageURL: URL?

    public init(
        id: String,
        author: String,
        content: String? = nil,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.imageURL = imageURL
    }
}

/// A social feed section containing a list of social posts.
public struct SocialSection: Codable, Equatable, Sendable {

    public let posts: [SocialPost]

    public init(posts: [SocialPost]) {
        self.posts = posts
    }
}
