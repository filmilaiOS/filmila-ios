import SwiftUI

struct AppShellView<Content: View>: View {
    var showsHeader: Bool = true
    @Binding var isDrawerOpen: Bool
    @ViewBuilder let content: () -> Content

    @Environment(\.shellNavigation) private var shellNavigation

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                if showsHeader {
                    AppHeaderView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDrawerOpen = true
                        }
                    }
                }

                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isDrawerOpen {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDrawerOpen = false
                        }
                    }
                    .transition(.opacity)

                HStack(spacing: 0) {
                    MenuDrawerView {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isDrawerOpen = false
                        }
                    }
                    .frame(width: min(320, UIScreen.main.bounds.width * 0.86))
                    .transition(.move(edge: .leading))

                    Spacer(minLength: 0)
                }
            }
        }
        .environment(\.layoutDirection, AppLanguage.layoutDirection)
    }
}

#if DEBUG
#Preview {
    AppShellView(isDrawerOpen: .constant(false)) {
        Text("Content")
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(FilmilaColors.background)
    .environmentObject(AuthService())
    .environment(\.shellNavigation, ShellNavigationActions())
    .preferredColorScheme(.dark)
}
#endif
