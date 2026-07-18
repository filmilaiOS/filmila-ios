import SwiftUI
import UIKit

private struct PresentedFilm: Identifiable {
    let id: Int
}

private struct PresentedOrder: Identifiable {
    let orderId: String
    var id: String { orderId }
}

struct MainTabView: View {
    let container: AppContainer
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var selectedTab = 0
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

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(container: container)
            }
            .tabItem {
                Label(String(localized: "tab_home"), systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                SearchView(
                    container: container,
                    externalSearchQuery: Binding(
                        get: { externalSearchQuery },
                        set: { externalSearchQuery = $0 }
                    )
                )
            }
            .tabItem {
                Label(String(localized: "tab_search"), systemImage: "magnifyingglass")
            }
            .tag(1)

            NavigationStack {
                LibraryView(container: container)
            }
            .tabItem {
                Label(String(localized: "tab_library"), systemImage: "rectangle.stack.fill")
            }
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(String(localized: "tab_profile"), systemImage: "person.fill")
            }
            .tag(3)

            NavigationStack {
                CommunityFeedView(container: container)
            }
            .tabItem {
                Label(String(localized: "tab_community"), systemImage: "person.2.fill")
            }
            .tag(4)
        }
        .tint(FilmilaColors.accent)
        .environment(\.mainTabSelection, $selectedTab)
        .onChange(of: deepLinkHandler.pendingRoute) { route in
            guard let route else { return }
            switch route {
            case let .filmDetail(filmId):
                selectedTab = 0
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
                selectedTab = 3
                deepLinkHandler.pendingRoute = nil
            case let .search(query):
                selectedTab = 1
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
