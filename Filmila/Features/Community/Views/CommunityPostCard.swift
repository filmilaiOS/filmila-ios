import SwiftUI

struct CommunityPostCard: View {
    let post: ForumPost
    let badgeColor: Color

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var hasImage: Bool {
        guard let imageUrl = post.imageUrl?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !imageUrl.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hasImage {
                CachedAsyncImage(url: post.imageUrl)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(post.title)
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .lineSpacing(2)

                HStack(spacing: Spacing.sm) {
                    Text(post.displayAuthorName)
                    if let createdAt = post.createdAt {
                        Text("·")
                        Text(Self.dateFormatter.string(from: createdAt))
                    }
                }
                .font(.filmilaCaption)
                .foregroundStyle(FilmilaColors.textSecondary)

                HStack(alignment: .center) {
                    Text(post.displayCategoryName)
                        .font(.filmilaCaptionMd)
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(badgeColor.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer(minLength: 0)

                    HStack(spacing: Spacing.md) {
                        Label("\(post.displayLikeCount)", systemImage: "heart")
                        Label("\(post.displayCommentCount)", systemImage: "bubble.right")
                    }
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textMuted)
                }
            }
            .padding(Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FilmilaColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(FilmilaColors.surfaceBright.opacity(0.35), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
