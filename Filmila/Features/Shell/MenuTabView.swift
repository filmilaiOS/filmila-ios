import SwiftUI

/// Placeholder body for the Menu tab — drawer is opened by MainTabView when this tab is selected.
struct MenuTabView: View {
    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FilmilaColors.background.ignoresSafeArea())
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
    MenuTabView()
        .preferredColorScheme(.dark)
}
#endif
