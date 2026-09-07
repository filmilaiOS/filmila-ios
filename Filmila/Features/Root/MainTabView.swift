import SwiftUI
import UIKit

private struct PresentedFilm: Identifiable {
    let id: Int
}

private struct PresentedOrder: Identifiable {
    let orderId: String
    var id: String { orderId }
}

private enum MainTabTag {
    static let home = 0
    static let search = 1
    static let watchlist = 2
    static let profile = 3
}

struct MainTabView: View {
    let container: AppContainer
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var selectedTab = MainTabTag.home
    @State private var isDrawerOpen = false
    @State private var authSheet: AuthSheetDestination?
    @State private var homeBrowseTab: HomeBrowseTab = .films
    @State private var showCommunity = false
    @State private var comingSoonTitle: String?
    @State private var presentedFilm: PresentedFilm?
    @State private var paymentOrder: PresentedOrder?
    @State private var externalSearchQuery: String?

    init(container: AppContainer) {
        self.container = container
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FilmilaColors.tabBarBackground)
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.08)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(FilmilaColors.textMuted)
    }

    private var shellNavigation: ShellNavigationActions {
        ShellNavigationActions(
            openDrawer: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDrawerOpen = true
                }
            },
            closeDrawer: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDrawerOpen = false
                }
            },
            presentLogin: { authSheet = .login },
            presentRegister: { authSheet = .register },
            navigateBrowse: handleBrowseDestination
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                AppShellView(isDrawerOpen: $isDrawerOpen) {
                    HomeView(
                        container: container,
                        selectedBrowseTab: $homeBrowseTab,
                        onWatchlistAuthRequired: { authSheet = .login }
                    )
                }
            }
            .tabItem {
                Label(String(localized: "tab_home"), systemImage: "film.stack")
            }
            .tag(MainTabTag.home)

            NavigationStack {
                AppShellView(isDrawerOpen: $isDrawerOpen) {
                    SearchView(
                        container: container,
                        externalSearchQuery: Binding(
                            get: { externalSearchQuery },
                            set: { externalSearchQuery = $0 }
                        )
                    )
                }
            }
            .tabItem {
                Label(String(localized: "tab_search"), systemImage: "magnifyingglass")
            }
            .tag(MainTabTag.search)

            NavigationStack {
                AppShellView(isDrawerOpen: $isDrawerOpen) {
                    LibraryView(
                        container: container,
                        onCreateAccount: { authSheet = .register },
                        onLogIn: { authSheet = .login }
                    )
                }
            }
            .tabItem {
                Label(String(localized: "tab_watchlist"), systemImage: "bookmark")
            }
            .tag(MainTabTag.watchlist)

            NavigationStack {
                AppShellView(isDrawerOpen: $isDrawerOpen) {
                    ProfileTabContent(
                        onLogIn: { authSheet = .login },
                        onCreateAccount: { authSheet = .register }
                    )
                }
            }
            .tabItem {
                Label(String(localized: "tab_profile"), systemImage: "person")
            }
            .tag(MainTabTag.profile)
        }
        .tint(FilmilaColors.accent)
        .environment(\.mainTabSelection, $selectedTab)
        .environment(\.shellNavigation, shellNavigation)
        .environment(\.layoutDirection, AppLanguage.layoutDirection)
        .onChange(of: auth.session?.user.id) { userId in
            if userId != nil {
                authSheet = nil
            } else {
                selectedTab = MainTabTag.home
            }
        }
        .onChange(of: deepLinkHandler.pendingRoute) { route in
            guard let route else { return }
            switch route {
            case let .filmDetail(filmId):
                selectedTab = MainTabTag.home
                presentedFilm = PresentedFilm(id: filmId)
                deepLinkHandler.pendingRoute = nil
            case .paymentComplete:
                break
            case .paymentCancelled:
                break
            case let .paymentCallback(orderId):
                paymentOrder = PresentedOrder(orderId: orderId)
                deepLinkHandler.pendingRoute = nil
            case .profile:
                selectedTab = MainTabTag.profile
                deepLinkHandler.pendingRoute = nil
            case let .search(query):
                selectedTab = MainTabTag.search
                externalSearchQuery = query ?? ""
                deepLinkHandler.pendingRoute = nil
            }
        }
        .fullScreenCover(item: $presentedFilm) { film in
            NavigationStack {
                FilmDetailView(filmId: film.id, container: container)
                    .environmentObject(networkMonitor)
                    .environmentObject(deepLinkHandler)
            }
        }
        .sheet(item: $authSheet) { destination in
            NavigationStack {
                Group {
                    switch destination {
                    case .login:
                        LoginView(authService: auth)
                    case .register:
                        RegisterView(authService: auth)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "common_cancel")) {
                            authSheet = nil
                        }
                        .foregroundStyle(FilmilaColors.textSecondary)
                    }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCommunity) {
            NavigationStack {
                CommunityFeedView(container: container)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showCommunity = false
                                selectedTab = MainTabTag.home
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.backward")
                                    Text(String(localized: "tab_home"))
                                }
                                .font(.filmilaBodyMedium)
                                .foregroundStyle(FilmilaColors.textPrimary)
                            }
                        }
                    }
            }
        }
        .alert(
            comingSoonTitle ?? "",
            isPresented: Binding(
                get: { comingSoonTitle != nil },
                set: { if !$0 { comingSoonTitle = nil } }
            )
        ) {
            Button(String(localized: "detail_iap_close"), role: .cancel) {
                comingSoonTitle = nil
            }
        } message: {
            Text(String(localized: "shell_coming_soon_body"))
        }
        .sheet(item: $paymentOrder) { order in
            NavigationStack {
                VStack(spacing: Spacing.lg) {
                    Text(String(localized: "payment_callback_title"))
                        .font(.filmilaTitleSm)
                        .foregroundStyle(FilmilaColors.textPrimary)
                    Text(order.orderId)
                        .font(.filmilaCaption)
                        .foregroundStyle(FilmilaColors.textSecondary)
                        .textSelection(.enabled)
                    Button(String(localized: "detail_iap_close")) {
                        paymentOrder = nil
                    }
                    .buttonStyle(FilmilaPrimaryButtonStyle())
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FilmilaColors.background)
            }
            .presentationDetents([.medium])
        }
    }

    private func handleBrowseDestination(_ destination: BrowseMenuDestination) {
        switch destination {
        case .films:
            homeBrowseTab = .films
            selectedTab = MainTabTag.home
        case .collections:
            homeBrowseTab = .collections
            selectedTab = MainTabTag.home
        case .genres:
            homeBrowseTab = .genres
            selectedTab = MainTabTag.home
        case .moods:
            homeBrowseTab = .moods
            selectedTab = MainTabTag.home
        case .themes:
            comingSoonTitle = String(localized: "shell_browse_themes")
        case .myList:
            selectedTab = MainTabTag.watchlist
        case .community:
            showCommunity = true
        case .submitFilm:
            if let url = URL(string: "https://filmila.com/submit") {
                UIApplication.shared.open(url)
            }
        case .about:
            comingSoonTitle = String(localized: "shell_about_filmila")
        case .partners:
            comingSoonTitle = String(localized: "shell_partners")
        case .help:
            comingSoonTitle = String(localized: "shell_help_center")
        case .profile:
            selectedTab = MainTabTag.profile
        }
    }
}

private struct ProfileTabContent: View {
    @EnvironmentObject private var auth: AuthService

    var onLogIn: () -> Void
    var onCreateAccount: () -> Void

    var body: some View {
        Group {
            if auth.session == nil {
                ProfileLoggedOutView(onLogIn: onLogIn, onCreateAccount: onCreateAccount)
            } else {
                ProfileView()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct ProfileLoggedOutView: View {
    var onLogIn: () -> Void
    var onCreateAccount: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: 0)

            Image(systemName: "person.crop.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(FilmilaColors.accent)

            Text(String(localized: "profile_logged_out_title"))
                .font(.filmilaTitle)
                .foregroundStyle(FilmilaColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "profile_logged_out_body"))
                .font(.filmilaBody)
                .foregroundStyle(FilmilaColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button(String(localized: "auth_sign_in"), action: onLogIn)
                .buttonStyle(FilmilaPrimaryButtonStyle())
                .padding(.horizontal, Spacing.lg)

            Button(String(localized: "auth_create_account"), action: onCreateAccount)
                .buttonStyle(FilmilaSecondaryButtonStyle())
                .padding(.horizontal, Spacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FilmilaColors.background.ignoresSafeArea())
    }
}

#if DEBUG
#Preview {
    let app = PreviewContainer()
    MainTabView(container: app)
        .environment(\.container, app)
        .environmentObject(PreviewContainer.makeSignedInAuthForPreviews())
        .environmentObject(app.pathMonitor)
        .environmentObject(app.deepLinkHandler)
        .preferredColorScheme(.dark)
}
#endif
