import SwiftUI

struct LoadingShimmer: View {
    var width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            GeometryReader { geo in
                let w = width ?? geo.size.width
                let band = w * 0.42
                let cycle = timeline.date.timeIntervalSinceReferenceDate / 1.35
                let phase = CGFloat(cycle - floor(cycle))
                let offsetX = -band + phase * (w + band * 2)

                ZStack(alignment: .leading) {
                    FilmilaColors.surfaceElevated
                    LinearGradient(
                        colors: [
                            FilmilaColors.shimmerBandLow,
                            FilmilaColors.shimmerBandMid,
                            FilmilaColors.shimmerBandLow
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: band)
                    .offset(x: offsetX)
                }
                .frame(width: w, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .frame(width: width, height: height)
    }
}

#if DEBUG
#Preview {
    LoadingShimmer(width: 200, height: 120, cornerRadius: 8)
        .padding()
        .background(FilmilaColors.background)
        .preferredColorScheme(.dark)
}
#endif
