#if DEBUG
import SwiftUI

struct WebPurchasePrompt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Checkout")
                .font(.filmilaBodyMedium)
                .foregroundStyle(FilmilaColors.textPrimary)
            Link(destination: URL(string: "https://www.filmila.com")!) {
                Text("filmila.com")
                    .font(.filmilaBody)
                    .foregroundStyle(FilmilaColors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(FilmilaColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    WebPurchasePrompt()
        .padding()
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
