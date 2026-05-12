import SwiftUI

struct FilmPosterCard: View {
    let film: Film
    var width: CGFloat = 160

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: film.thumbnailUrl)
                .frame(width: width, height: width * 1.5)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            LinearGradient(
                colors: [.clear, FilmilaColors.imageFadeScrimMedium],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(film.displayTitle)
                    .font(.filmilaTitleSm)
                    .foregroundStyle(FilmilaColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !film.isFree {
                    Text(String(format: String(localized: "price_sar_format"), film.price))
                        .font(.filmilaLabel)
                        .foregroundStyle(FilmilaColors.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .frame(width: width, height: width * 1.5)
    }
}

#if DEBUG
#Preview {
    FilmPosterCard(
        film: Film(
            id: 1,
            title: "Sample",
            description: "Desc",
            thumbnailUrl: "https://picsum.photos/320/480",
            price: 19.99,
            status: .approved,
            viewCount: 0,
            createdAt: Date()
        ),
        width: 140
    )
    .padding()
    .background(FilmilaColors.background)
    .preferredColorScheme(.dark)
}
#endif
