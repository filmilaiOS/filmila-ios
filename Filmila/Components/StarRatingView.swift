import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var maxStars: Int = 5
    var isInteractive: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxStars, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.filmilaIconRating)
                    .foregroundStyle(star <= rating ? FilmilaColors.accent : FilmilaColors.textMuted)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard isInteractive else { return }
                        rating = star
                    }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "detail_rating_accessibility")))
    }
}

#if DEBUG
#Preview {
    VStack {
        StarRatingView(rating: .constant(3), isInteractive: false)
        StarRatingView(rating: .constant(0), isInteractive: true)
    }
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
