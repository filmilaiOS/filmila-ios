import SwiftUI

struct CategoryPostsView: View {
    @StateObject private var vm: CategoryPostsViewModel
    @Environment(\.container) private var container

    init(category: ForumCategory, container: AppContainer) {
        _vm = StateObject(wrappedValue: CategoryPostsViewModel(category: category, container: container))
    }

    var body: some View {
        Group {
            if vm.isLoading, vm.posts.isEmpty {
                ProgressView()
                    .tint(FilmilaColors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage, vm.posts.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.filmilaIconEmptyState)
                        .foregroundStyle(FilmilaColors.textMuted.opacity(0.3))
                    Text(error)
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.posts.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.filmilaIconEmptyState)
                        .foregroundStyle(FilmilaColors.textMuted.opacity(0.3))
                    Text(String(localized: "community_empty_posts"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, Spacing.lg)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(vm.posts) { post in
                            NavigationLink {
                                PostDetailView(postId: post.id, container: container)
                            } label: {
                                CommunityPostCard(
                                    post: post,
                                    badgeColor: vm.category.displayColor
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(vm.category.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await vm.load()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CategoryPostsView(
            category: ForumCategory(id: 1, name: "Discussions", color: "#EF4444"),
            container: PreviewContainer()
        )
    }
    .environment(\.container, PreviewContainer())
    .preferredColorScheme(.dark)
}
#endif
