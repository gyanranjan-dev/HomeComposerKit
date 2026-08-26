import SwiftUI

/// Horizontal social post cards.
public struct SocialSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var posts: [SocialPost] {
        if case .social(let payload) = section.content {
            return payload.posts
        }
        return []
    }

    public var body: some View {
        HomeSectionContainer(title: section.title) {
            if posts.isEmpty {
                Text("No posts")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(posts) { post in
                            socialCard(post)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func socialCard(_ post: SocialPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RemoteImageView(url: post.imageURL)
                .frame(width: 180, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(post.author)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let content = post.content {
                Text(content)
                    .font(.subheadline)
                    .lineLimit(3)
                    .frame(width: 180, alignment: .leading)
            }
        }
        .padding(10)
        .background(HomeUIColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

struct SocialSectionRenderer: HomeSectionRenderer {
    func canRender(_ type: HomeSectionType) -> Bool {
        type == .social
    }

    @MainActor
    func render(_ section: ComposedHomeSection) -> AnyView {
        AnyView(SocialSectionView(section: section))
    }
}
