import SwiftUI

extension FilmilaColors {
    static let textInverse = Color(hex: "#080810")
}

struct FilmilaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.textInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(FilmilaColors.accent)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct FilmilaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(FilmilaColors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(FilmilaColors.accent, lineWidth: 1)
            )
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
