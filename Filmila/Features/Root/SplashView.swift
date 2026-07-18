import SwiftUI

struct SplashView: View {
    @State private var logoOpacity = 0.0

    private let logoWidth: CGFloat = 140

    var body: some View {
        ZStack {
            FilmilaColors.splashBackground.ignoresSafeArea()

            Image("FilmilaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logoWidth)
                .opacity(logoOpacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                logoOpacity = 1
            }
        }
    }
}

#if DEBUG
#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
#endif
