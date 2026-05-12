import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        Group {
            if !monitor.isConnected {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "wifi.slash")
                        .font(.filmilaCaptionMd)
                    Text(String(localized: "network_no_connection"))
                        .font(.filmilaCaptionMd)
                }
                .foregroundStyle(FilmilaColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(FilmilaColors.networkBannerScrim)
                .clipShape(Capsule())
                .padding(.top, Spacing.md)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        FilmilaColors.surfaceElevated.ignoresSafeArea()
        NetworkStatusBanner(monitor: NetworkMonitor())
    }
}
#endif
