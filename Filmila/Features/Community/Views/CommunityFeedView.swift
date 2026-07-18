import SwiftUI

struct CommunityFeedView: View {
    @StateObject private var vm: CommunityFeedViewModel
    @Environment(\.container) private var container
    @Environment(\.locale) private var locale

    @State private var cachedPostCountsByCategory: [Int: Int] = [:]
    @State private var cachedAllPostsCount: Int = 0

    init(container: AppContainer) {
        _vm = StateObject(wrappedValue: CommunityFeedViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                communityHeader

                if vm.isLoading, vm.categories.isEmpty {
                    loadingState
                } else if let error = vm.errorMessage, vm.categories.isEmpty {
                    errorState(error)
                } else {
                    categoryRow
                    postsSection
                }
            }
            .padding(.bottom, Spacing.xxl)
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await vm.load()
        }
        .onChange(of: vm.posts) { _ in
            refreshCachedCountsIfNeeded()
        }
    }

    private var communityHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(communityLocalized("community_title"))
                .font(.custom("Georgia-Bold", size: 28))
                .foregroundStyle(FilmilaColors.textPrimary)
                .lineSpacing(4)

            Text(communityLocalized("community_header_subtitle"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                CommunityAllCategoryCard(
                    title: communityLocalized("community_filter_all"),
                    postCount: allPostsCount,
                    postsLabel: communityLocalized("community_posts_label"),
                    isSelected: vm.selectedCategoryId == nil
                ) {
                    Task { await vm.selectCategory(nil) }
                }

                ForEach(vm.categories) { category in
                    CommunityCategoryCard(
                        category: category,
                        postCount: postCount(for: category.id),
                        postsLabel: communityLocalized("community_posts_label"),
                        isSelected: vm.selectedCategoryId == category.id
                    ) {
                        Task { await vm.selectCategory(category.id) }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    @ViewBuilder
    private var postsSection: some View {
        if vm.isLoading, vm.posts.isEmpty {
            ProgressView()
                .tint(FilmilaColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.xl)
        } else if let error = vm.errorMessage, vm.posts.isEmpty {
            errorState(error)
        } else if vm.posts.isEmpty {
            VStack(spacing: Spacing.md) {
                Image(systemName: "text.bubble")
                    .font(.filmilaIconEmptyState)
                    .foregroundStyle(FilmilaColors.textMuted.opacity(0.3))
                Text(communityLocalized("community_empty_posts"))
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
        } else {
            LazyVStack(spacing: Spacing.md) {
                ForEach(vm.posts) { post in
                    NavigationLink {
                        PostDetailView(postId: post.id, container: container)
                    } label: {
                        CommunityPostCard(
                            post: post,
                            badgeColor: badgeColor(for: post)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

    private var loadingState: some View {
        ProgressView()
            .tint(FilmilaColors.accent)
            .frame(maxWidth: .infinity)
            .padding(.top, Spacing.xxl)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.filmilaIconEmptyState)
                .foregroundStyle(FilmilaColors.textMuted.opacity(0.3))
            Text(message)
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl)
    }

    private func communityLocalized(_ key: String) -> String {
        String(
            localized: String.LocalizationValue(key),
            bundle: .main,
            locale: locale
        )
    }

    private var allPostsCount: Int {
        vm.selectedCategoryId == nil ? vm.posts.count : cachedAllPostsCount
    }

    private func postCount(for categoryId: Int) -> Int {
        if vm.selectedCategoryId == categoryId {
            return vm.posts.count
        }
        return cachedPostCountsByCategory[categoryId] ?? 0
    }

    private func badgeColor(for post: ForumPost) -> Color {
        guard let categoryId = post.categoryId,
              let index = vm.categories.firstIndex(where: { $0.id == categoryId }) else {
            return FilmilaColors.accent
        }
        return vm.categories[index].displayColor
    }

    private func refreshCachedCountsIfNeeded() {
        guard vm.selectedCategoryId == nil, !vm.posts.isEmpty else { return }

        cachedAllPostsCount = vm.posts.count
        var counts: [Int: Int] = [:]
        for post in vm.posts {
            if let categoryId = post.categoryId {
                counts[categoryId, default: 0] += 1
            }
        }
        cachedPostCountsByCategory = counts
    }
}

// MARK: - Category cards

private enum CommunityCategoryImages {
    static let byName: [String: String] = [
        "General": "https://k.top4top.io/p_3721l13w43.png",
        "Filmmaking": "https://a.top4top.io/p_3721yjqim5.png",
        "Film Ideas": "https://j.top4top.io/p_37215xx6p2.png",
        "Screenwriting": "https://b.top4top.io/p_3721bxz2y6.png",
        "Film Analysis": "https://i.top4top.io/p_3721fssml1.png",
        "Acting & Casting": "https://l.top4top.io/p_3721m3w2u4.png",
        "Announcements": "https://k.top4top.io/p_3721l13w43.png",
        "Collaborations": "https://a.top4top.io/p_3721yjqim5.png",
        "Reviews": "https://i.top4top.io/p_3721fssml1.png"
    ]

    static func imageURL(for categoryName: String) -> String? {
        byName[categoryName]
    }
}

private struct CommunityAllCategoryCard: View {
    let title: String
    let postCount: Int
    let postsLabel: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        FilmilaColors.accent.opacity(isSelected ? 0.55 : 0.4),
                        FilmilaColors.accent.opacity(isSelected ? 0.25 : 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.filmilaBodyMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text("\(postCount) \(postsLabel)")
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
            }
            .frame(width: 160, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? FilmilaColors.accent : Color.clear,
                        lineWidth: 2
                    )
            }
            .shadow(color: Color.black.opacity(isSelected ? 0.45 : 0.35), radius: isSelected ? 10 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct CommunityCategoryCard: View {
    let category: ForumCategory
    let postCount: Int
    let postsLabel: String
    let isSelected: Bool
    let action: () -> Void

    private var backgroundImageURL: String? {
        CommunityCategoryImages.imageURL(for: category.name)
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if let backgroundImageURL {
                    CachedAsyncImage(url: backgroundImageURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    category.displayColor
                }

                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(isSelected ? 0.75 : 0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.filmilaBodyMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text("\(postCount) \(postsLabel)")
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
            }
            .frame(width: 160, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? FilmilaColors.accent : Color.clear,
                        lineWidth: 2
                    )
            }
            .shadow(color: Color.black.opacity(isSelected ? 0.45 : 0.35), radius: isSelected ? 10 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CommunityFeedView(container: PreviewContainer())
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
