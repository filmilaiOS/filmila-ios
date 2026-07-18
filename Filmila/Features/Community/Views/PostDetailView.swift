import SwiftUI

struct PostDetailView: View {
    @StateObject private var vm: PostDetailViewModel

    init(postId: Int, container: AppContainer) {
        _vm = StateObject(wrappedValue: PostDetailViewModel(postId: postId, container: container))
    }

    var body: some View {
        Group {
            if let post = vm.post {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        postHeader(post)
                        postBody(post)
                        commentsSection
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            } else if vm.isLoading {
                ProgressView()
                    .tint(FilmilaColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.filmilaIconEmptyState)
                        .foregroundStyle(FilmilaColors.textMuted.opacity(0.3))
                    Text(vm.errorMessage ?? String(localized: "community_post_unavailable"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Spacing.lg)
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(vm.post?.title ?? String(localized: "community_post_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load()
        }
    }

    private func postHeader(_ post: ForumPost) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(post.displayCategoryName.uppercased())
                .font(.filmilaLabel)
                .foregroundStyle(FilmilaColors.accent)
                .tracking(1.2)

            HStack(spacing: Spacing.sm) {
                Text(post.displayAuthorName)
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)

                if let createdAt = post.createdAt {
                    Text("·")
                        .foregroundStyle(FilmilaColors.textMuted)
                    Text(CommunityDateFormatting.mediumDate(createdAt))
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }
            }

            HStack(spacing: Spacing.md) {
                Label("\(post.displayLikeCount)", systemImage: "heart")
                Label("\(post.displayCommentCount)", systemImage: "bubble.right")
            }
            .font(.filmilaCaptionMd)
            .foregroundStyle(FilmilaColors.textMuted)
        }
        .padding(.top, Spacing.md)
    }

    private func postBody(_ post: ForumPost) -> some View {
        Text(post.content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
             ? (post.content ?? "")
             : String(localized: "community_post_no_content"))
            .font(.filmilaBody)
            .foregroundStyle(FilmilaColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(4)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "community_comments_heading"))
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)

            if vm.comments.isEmpty {
                Text(String(localized: "community_comments_empty"))
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
            } else {
                ForEach(vm.comments) { comment in
                    ForumCommentRow(comment: comment)
                }
            }
        }
    }
}

private struct ForumCommentRow: View {
    let comment: ForumComment

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(comment.displayAuthorName)
                    .font(.filmilaBodyMedium)
                    .foregroundStyle(FilmilaColors.textPrimary)

                if let createdAt = comment.createdAt {
                    Text(CommunityDateFormatting.relativeDate(createdAt))
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textMuted)
                }
            }

            Text(comment.content)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private enum CommunityDateFormatting {
    private static let mediumFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    static func mediumDate(_ date: Date) -> String {
        mediumFormatter.string(from: date)
    }

    static func relativeDate(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PostDetailView(postId: 1, container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
