import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct FilmilaColors {
    /// Premium cinematic background.
    static let splashBackground = Color(hex: "#07070F")
    static let background = Color(hex: "#07070F")
    static let surface = Color(hex: "#12121C")
    static let surfaceElevated = Color(hex: "#1C1C26")
    static let surfaceBright = Color(hex: "#262633")
    /// Filmila brand accent.
    static let accent = Color(hex: "#E91E8C")
    static let accentSubtle = Color(hex: "#E91E8C").opacity(0.14)
    static let accentBright = Color(hex: "#F04DA3")
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.62)
    static let textMuted = Color(white: 0.40)
    static let success = Color(hex: "#4ADE80")
    static let warning = Color(hex: "#FBBF24")
    static let destructive = Color(hex: "#F87171")

    static let playerChrome = Color.black
    static let overlayScrim = Color.black.opacity(0.50)
    static let networkBannerScrim = Color.black.opacity(0.85)
    static let pageDotInactive = Color.white.opacity(0.35)
    static let heroWatchButtonFill = Color(hex: "#E91E8C")
    static let heroWatchButtonForeground = Color.white
    static let posterBadgeBackdrop = Color.black.opacity(0.62)
    static let shimmerBandLow = Color.white.opacity(0.06)
    static let shimmerBandMid = Color.white.opacity(0.20)
    static let landingGradientBottom = Color(hex: "#0A0612")
    static let imageFadeScrimStrong = Color.black.opacity(0.82)
    static let imageFadeScrimMedium = Color.black.opacity(0.68)
    static let searchPosterShimmerHighlight = Color.white.opacity(0.10)
    static let cardBorder = Color.white.opacity(0.08)
    static let tabBarBackground = Color(hex: "#0A0A12")
}
