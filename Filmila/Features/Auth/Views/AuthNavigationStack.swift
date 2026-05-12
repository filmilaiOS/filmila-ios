import SwiftUI

struct AuthNavigationStack: View {
    var body: some View {
        NavigationStack {
            LandingView()
        }
    }
}

#if DEBUG
#Preview {
    AuthNavigationStack()
        .environment(\.container, PreviewContainer())
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}
#endif
