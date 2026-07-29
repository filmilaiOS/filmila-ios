import SwiftUI

struct FilmDetailView: View {
    private let container: AppContainer

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var vm: FilmDetailViewModel
    @State private var commentDraft = ""
    @State private var playbackFilm: Film?
    @State private var userStarBinding: Int = 0
    @State private var showRatingSheet = false

    init(filmId: Int, container: AppContainer) {
        self.container = container
        _vm = StateObject(wrappedValue: FilmDetailViewModel(filmId: filmId, container: container))
    }

    var body: some View {
        Group {
            if let film = vm.film {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        FilmHeroView(
                            film: film,
                            container: container,
                            averageRating: vm.averageRating,
                            ratingCount: vm.ratingCount,
                            filmmaker: vm.filmmakerProfile
                        )
                        actionButtons(film: film)
                        if let message = vm.errorMessage {
                            Text(message)
                                .font(.filmilaCaption)
                                .foregroundStyle(FilmilaColors.destructive)
                                .padding(.horizontal, Spacing.lg)
                        }
                        if let notice = vm.purchaseNotice {
                            Text(notice)
                                .font(.filmilaCaption)
                                .foregroundStyle(FilmilaColors.textSecondary)
                                .padding(.horizontal, Spacing.lg)
                        }
                        descriptionSection(film: film)
                        commentsSection
                    }
                    .padding(.bottom, Spacing.xxl)
                }
                .background(FilmilaColors.background.ignoresSafeArea())
                .fullScreenCover(item: $playbackFilm) { film in
                    PlayerContainerView(film: film, container: container, networkMonitor: networkMonitor)
                }
                .fullScreenCover(item: $vm.webCheckout) { checkout in
                    SafariCheckoutView(url: checkout.url) {
                        Task { await vm.completeWebCheckoutFlow() }
                    }
                    .ignoresSafeArea()
                }
                .sheet(isPresented: $showRatingSheet, onDismiss: {
                    vm.clearRatingFeedbackMessage()
                }) {
                    ratingSheet
                }
                .onChange(of: deepLinkHandler.pendingRoute) { route in
                    guard let route else { return }
                    switch route {
                    case let .paymentComplete(filmId):
                        deepLinkHandler.pendingRoute = nil
                        Task { await vm.handlePaymentCompleteDeepLink(filmId: filmId) }
                    case let .paymentCancelled(filmId):
                        deepLinkHandler.pendingRoute = nil
                        Task { await vm.handlePaymentCancelledDeepLink(filmId: filmId) }
                    default:
                        break
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    guard newPhase == .active else { return }
                    Task { await vm.recheckAccessAfterWebPurchase() }
                }
                .onReceive(vm.$userRating) { value in
                    userStarBinding = value ?? 0
                }
                .onAppear {
                    userStarBinding = vm.userRating ?? 0
                }
            } else if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tint(FilmilaColors.accent)
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "film")
                        .font(.filmilaIconHero)
                        .foregroundStyle(FilmilaColors.textMuted)
                    Text(String(localized: "detail_unavailable_title"))
                        .font(.filmilaTitleSm)
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Text(vm.errorMessage ?? String(localized: "detail_unavailable_body"))
                        .font(.filmilaBody)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(FilmilaColors.background.ignoresSafeArea())
        .navigationTitle(vm.film?.displayTitle ?? String(localized: "detail_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.load()
        }
    }

    @ViewBuilder
    private func actionButtons(film: Film) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let canWatch = vm.accessState == .free || vm.accessState == .purchased
            if canWatch {
                Button {
                    playbackFilm = film
                } label: {
                    Text(String(localized: "detail_watch"))
                        .font(.filmilaBodyMedium)
                }
                .buttonStyle(FilmilaPrimaryButtonStyle())
                .disabled(vm.accessState == .checking)
            } else if !film.isFree {
                Button {
                    vm.startWebPurchase()
                } label: {
                    Text(purchaseButtonTitle(for: film))
                        .font(.filmilaBodyMedium)
                }
                .buttonStyle(FilmilaPrimaryButtonStyle())
                .disabled(vm.accessState == .checking)
            }

            HStack(spacing: Spacing.sm) {
                Button {
                    Task { await vm.toggleWatchlist() }
                } label: {
                    Label(
                        vm.isInWatchlist ? String(localized: "detail_watchlist_remove") : String(localized: "detail_watchlist_add"),
                        systemImage: vm.isInWatchlist ? "checkmark.circle.fill" : "plus.circle"
                    )
                    .font(.filmilaCaptionMd)
                }
                .buttonStyle(.bordered)
                .tint(FilmilaColors.accent)

                Button {
                    showRatingSheet = true
                } label: {
                    Label(
                        String(localized: "detail_rate"),
                        systemImage: vm.userRating != nil ? "star.fill" : "star"
                    )
                    .font(.filmilaCaptionMd)
                }
                .buttonStyle(.bordered)
                .tint(FilmilaColors.accent)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var ratingSheet: some View {
        VStack(spacing: Spacing.lg) {
            Text(String(localized: "detail_rate"))
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)

            if let message = vm.ratingFeedbackMessage {
                Text(message)
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Text(String(localized: "detail_rating_yours"))
                    .font(.filmilaCaption)
                    .foregroundStyle(FilmilaColors.textSecondary)
            }

            StarRatingView(
                rating: Binding(
                    get: { userStarBinding },
                    set: { newValue in
                        userStarBinding = newValue
                        if newValue >= 1, newValue <= 5 {
                            Task { await vm.submitRating(newValue) }
                        }
                    }
                ),
                isInteractive: true
            )

            Button(String(localized: "common_done")) {
                showRatingSheet = false
            }
            .buttonStyle(.borderedProminent)
            .tint(FilmilaColors.accent)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func purchaseButtonTitle(for film: Film) -> String {
        let price = String(format: String(localized: "price_sar_format"), film.price)
        return "\(String(localized: "detail_purchase")) · \(price)"
    }

    private func descriptionSection(film: Film) -> some View {
        Group {
            if let desc = film.displayDescription, !desc.isEmpty {
                Text(desc)
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.textSecondary)
                    .padding(.horizontal, Spacing.lg)
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "detail_comments_heading"))
                .font(.filmilaTitleSm)
                .foregroundStyle(FilmilaColors.textPrimary)
                .padding(.horizontal, Spacing.lg)

            ForEach(vm.comments) { comment in
                CommentCell(comment: comment)
                    .padding(.horizontal, Spacing.lg)
            }

            HStack(alignment: .bottom, spacing: Spacing.sm) {
                TextField(String(localized: "detail_comment_placeholder"), text: $commentDraft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(Spacing.md)
                    .background(FilmilaColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .lineLimit(1 ... 4)

                Button {
                    let text = commentDraft
                    commentDraft = ""
                    Task { await vm.submitComment(text) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.filmilaIconDetail)
                        .foregroundStyle(FilmilaColors.accent)
                }
                .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }

}

#if DEBUG
#Preview {
    NavigationStack {
        FilmDetailView(filmId: 1, container: PreviewContainer())
            .environmentObject(NetworkMonitor())
            .environmentObject(PreviewContainer().deepLinkHandler)
    }
    .preferredColorScheme(.dark)
}
#endif
