import AVKit
import SwiftUI
import UIKit

struct VideoPlayerView: UIViewControllerRepresentable {
    @ObservedObject var service: HLSPlayerService

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        controller.videoGravity = .resizeAspect
        controller.delegate = context.coordinator
        controller.player = service.player
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== service.player {
            uiViewController.player = service.player
        }
    }

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {}
}

#if DEBUG
#Preview {
    let c = PreviewContainer()
    let service = HLSPlayerService(
        s3Service: c.s3Service,
        progressRepo: c.progressRepo,
        networkMonitor: c.networkMonitor
    )
    VideoPlayerView(service: service)
        .frame(height: 220)
        .environment(\.container, c)
}
#endif
