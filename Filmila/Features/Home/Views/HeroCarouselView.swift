import SwiftUI
import UIKit

struct HeroCarouselView: View {
    let films: [Film]
    var isLoading: Bool = false

    @State private var currentIndex = 0
    @State private var autoScrollTimer: Timer?

    private var heroHeight: CGFloat {
        UIScreen.main.bounds.height * 0.70
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading && films.isEmpty {
                LoadingShimmer(width: nil, height: heroHeight, cornerRadius: 0)
                    .frame(height: heroHeight)
            } else if films.isEmpty {
                Color.clear.frame(height: 0)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(films.enumerated()), id: \.element.id) { index, film in
                        HeroFilmSlide(film: film)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: heroHeight)

                HStack(spacing: 6) {
                    ForEach(0..<films.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? FilmilaColors.accent : FilmilaColors.pageDotInactive)
                            .frame(width: i == currentIndex ? 6 : 4, height: i == currentIndex ? 6 : 4)
                    }
                }
                .padding(.bottom, Spacing.lg)
            }
        }
        .frame(height: films.isEmpty && !isLoading ? 0 : heroHeight)
        .onAppear {
            startTimerIfNeeded()
        }
        .onChange(of: films) { _ in
            if currentIndex >= films.count {
                currentIndex = max(0, films.count - 1)
            }
            restartTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimerIfNeeded() {
        stopTimer()
        guard films.count > 1 else { return }
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            Task { @MainActor in
                currentIndex = (currentIndex + 1) % films.count
            }
        }
        autoScrollTimer?.tolerance = 0.2
        if let timer = autoScrollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func restartTimer() {
        startTimerIfNeeded()
    }

    private func stopTimer() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
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
        ]
    )
    .preferredColorScheme(.dark)
}
#endif
