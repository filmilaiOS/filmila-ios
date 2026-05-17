import SwiftUI
import UIKit

struct HeroCarouselView: View {
    let films: [Film]
    var isLoading: Bool = false
    var averageRatingByFilmId: [Int: Double] = [:]

    @State private var currentIndex = 0

    private var heroImageHeight: CGFloat {
        UIScreen.main.bounds.height * 0.65
    }

    private var showsCarousel: Bool {
        !films.isEmpty || isLoading
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            if isLoading && films.isEmpty {
                LoadingShimmer(width: nil, height: heroImageHeight, cornerRadius: 0)
                    .frame(height: heroImageHeight)
            } else if films.isEmpty {
                Color.clear.frame(height: 0)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(films.enumerated()), id: \.element.id) { index, film in
                        HeroFilmSlide(
                            film: film,
                            averageRating: averageRatingByFilmId[film.id]
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: heroImageHeight)

                pageIndicator
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: showsCarousel ? heroImageHeight + (films.isEmpty ? 0 : 22) : 0)
        .task(id: films.map(\.id)) {
            guard films.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        currentIndex = (currentIndex + 1) % films.count
                    }
                }
            }
        }
        .onChange(of: films.count) { newCount in
            if currentIndex >= newCount {
                currentIndex = max(0, newCount - 1)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(0..<films.count, id: \.self) { i in
                if i == currentIndex {
                    Circle()
                        .fill(FilmilaColors.textPrimary)
                        .frame(width: 7, height: 7)
                } else {
                    Circle()
                        .stroke(FilmilaColors.textPrimary.opacity(0.9), lineWidth: 1.5)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Spacing.xs)
    }
}

#if DEBUG
#Preview {
    HeroCarouselView(
        films: [
            Film(
                id: 1,
                title: "One",
                description: "First",
                thumbnailUrl: "https://picsum.photos/seed/a/800/1200",
                price: 0,
                status: .approved,
                genre: "Drama",
                viewCount: 1,
                createdAt: Date()
            ),
            Film(
                id: 2,
                title: "Two",
                description: "Second",
                thumbnailUrl: "https://picsum.photos/seed/b/800/1200",
                price: 15,
                status: .approved,
                genre: "Action",
                viewCount: 2,
                createdAt: Date()
            )
        ],
        averageRatingByFilmId: [1: 4.2, 2: 3.9]
    )
    .preferredColorScheme(.dark)
}
#endif
