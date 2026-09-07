import SwiftUI

extension FilmilaColors {
    static let textInverse = Color.white
}

struct FilmilaPrimaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(FilmilaColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FilmilaSecondaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(FilmilaColors.accentSubtle)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FilmilaColors.accent.opacity(0.65), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
