import SwiftUI

/// Pink primary CTA (Watch Now) with optional play icon in label.
struct FilmilaAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(FilmilaColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Pink outline secondary CTA (In Watchlist / + My List).
struct FilmilaAccentOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FilmilaColors.accent, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Legacy aliases used across the app.
typealias FilmilaWhiteButtonStyle = FilmilaAccentButtonStyle
typealias FilmilaWhiteOutlineButtonStyle = FilmilaAccentOutlineButtonStyle
