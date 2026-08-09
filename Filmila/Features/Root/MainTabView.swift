import SwiftUI
import UIKit

private struct PresentedFilm: Identifiable {
    let id: Int
}

private struct PresentedOrder: Identifiable {
    let orderId: String
    var id: String { orderId }
}

private enum MenuTabTag {
    static let home = 0
    static let search = 1
    static let myList = 2
    static let menu = 3
}

struct MainTabView: View {
    let container: AppContainer
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var selectedTab = MenuTabTag.home
    @State private var lastNonMenuTab = MenuTabTag.home
    @State private var isDrawerOpen = false
    @State private var authSheet: AuthSheetDestination?
    @State private var homeBrowseTab: HomeBrowseTab = .films
    @State private var showProfile = false
    @State private var showCommunity = false
    @State private var comingSoonTitle: String?
    @State private var presentedFilm: PresentedFilm?
    @State private var paymentOrder: PresentedOrder?
    @State private var externalSearchQuery: String?

    init(container: AppContainer) {
        self.container = container
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FilmilaColors.surface)
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
                Label(String(localized: "tab_home"), systemImage: "house.fill")
            }
            .tag(MenuTabTag.home)

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
            .tag(MenuTabTag.search)

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
                Label(String(localized: "tab_my_list"), systemImage: "rectangle.stack.fill")
            }
            .tag(MenuTabTag.myList)

            NavigationStack {
                AppShellView(showsHeader: true, isDrawerOpen: $isDrawerOpen) {
                    MenuTabView()
                }
            }
            .tabItem {
                Label(String(localized: "tab_menu"), systemImage: "line.3.horizontal")
            }
            .tag(MenuTabTag.menu)
        }
        .tint(FilmilaColors.accent)
        .environment(\.mainTabSelection, $selectedTab)
        .environment(\.shellNavigation, shellNavigation)
        .environment(\.layoutDirection, AppLanguage.layoutDirection)
        .onChange(of: selectedTab) { newValue in
            if newValue == MenuTabTag.menu {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDrawerOpen = true
                }
                selectedTab = lastNonMenuTab
            } else {
                lastNonMenuTab = newValue
            }
        }
        .onChange(of: deepLinkHandler.pendingRoute) { route in
            guard let route else { return }
            switch route {
            case let .filmDetail(filmId):
                selectedTab = MenuTabTag.home
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
                showProfile = true
                deepLinkHandler.pendingRoute = nil
            case let .search(query):
                selectedTab = MenuTabTag.search
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
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(String(localized: "detail_iap_close")) {
                                showProfile = false
                            }
                            .foregroundStyle(FilmilaColors.textSecondary)
                        }
                    }
            }
        }
        .sheet(isPresented: $showCommunity) {
            NavigationStack {
                CommunityFeedView(container: container)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showCommunity = false
                                selectedTab = MenuTabTag.home
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
            selectedTab = MenuTabTag.home
        case .collections:
            homeBrowseTab = .collections
            selectedTab = MenuTabTag.home
        case .genres:
            homeBrowseTab = .genres
            selectedTab = MenuTabTag.home
        case .moods:
            homeBrowseTab = .moods
            selectedTab = MenuTabTag.home
        case .themes:
            comingSoonTitle = String(localized: "shell_browse_themes")
        case .myList:
            selectedTab = MenuTabTag.myList
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
            showProfile = true
        }
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
