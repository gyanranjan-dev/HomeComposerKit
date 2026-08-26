import SwiftUI

/// Social content section using a clean card layout. No social API integration.
public struct SocialSectionView: View {
    let section: ComposedHomeSection

    public init(section: ComposedHomeSection) {
        self.section = section
    }

    private var posts: [SocialPost] {
        guard case .social(let payload) = section.content else { return [] }
        let items = payload.posts
        if let limit = section.configuration?.limit {
            return Array(items.prefix(limit))
        }
        return items
    }

    private var spacing: CGFloat {
        CGFloat(section.configuration?.spacing ?? 12)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HomeSectionHeaderView(
                title: section.title,
                showTitle: shouldShowTitle
            )

            if posts.isEmpty {
                Text("No posts")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .accessibilityLabel("No social posts available")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(posts) { post in
                            socialCard(post)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var shouldShowTitle: Bool {
        !(section.title ?? "").isEmpty
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel(for: post)))
    }

    private func accessibilityLabel(for post: SocialPost) -> String {
        if let content = post.content {
            return "\(post.author): \(content)"
        }
        return post.author
    }
}
