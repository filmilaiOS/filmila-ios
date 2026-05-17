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
    static let background = Color(hex: "#080810")
    static let surface = Color(hex: "#111118")
    static let surfaceElevated = Color(hex: "#1A1A24")
    static let surfaceBright = Color(hex: "#22222E")
    static let accent = Color(hex: "#C9A96E")
    static let accentSubtle = Color(hex: "#C9A96E").opacity(0.12)
    static let accentBright = Color(hex: "#E2C08A")
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.60)
    static let textMuted = Color(white: 0.36)
    static let success = Color(hex: "#4ADE80")
    static let warning = Color(hex: "#FBBF24")
    static let destructive = Color(hex: "#F87171")

    /// Full-screen player letterbox / chrome.
    static let playerChrome = Color.black
    /// Scrim over artwork (e.g. continue-watching thumb).
    static let overlayScrim = Color.black.opacity(0.45)
    /// Offline / status banner backdrop.
    static let networkBannerScrim = Color.black.opacity(0.8)
    /// Hero carousel inactive page dot (outline style drawn in views).
    static let pageDotInactive = Color.white.opacity(0.35)
    /// Hero “Watch” pill (light fill on dark hero).
    static let heroWatchButtonFill = Color.white
    static let heroWatchButtonForeground = Color(hex: "#0A0A0A")
    /// Poster duration / rating capsule backdrop.
    static let posterBadgeBackdrop = Color.black.opacity(0.55)
    /// Shimmer highlight band (low / mid for gradient).
    static let shimmerBandLow = Color.white.opacity(0.06)
    static let shimmerBandMid = Color.white.opacity(0.22)
    static let landingGradientBottom = Color(hex: "#0F051F")
    /// Bottom fade over hero / poster imagery.
    static let imageFadeScrimStrong = Color.black.opacity(0.75)
    static let imageFadeScrimMedium = Color.black.opacity(0.7)
    /// Subtle sweep on search poster placeholders.
    static let searchPosterShimmerHighlight = Color.white.opacity(0.12)
}
