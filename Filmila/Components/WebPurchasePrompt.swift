import SwiftUI

struct WebPurchasePrompt: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "detail_web_purchase_title"))
                .font(.filmilaBodyMedium)
                .foregroundStyle(FilmilaColors.textPrimary)
            Link(destination: URL(string: "https://www.filmila.com")!) {
                Text(String(localized: "detail_web_purchase_link"))
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

#if DEBUG
#Preview {
    WebPurchasePrompt()
        .padding()
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
