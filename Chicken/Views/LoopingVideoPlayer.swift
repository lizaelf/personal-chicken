import AVFoundation
import SwiftUI
import UIKit

/// Loops a bundled video silently. Prefers H.264 `.mp4` so Simulator can play
/// clips; ProRes `.mov` is a fallback for devices that decode it.
struct LoopingVideoPlayer: UIViewRepresentable {
    let resourceName: String
    var isPlaying: Bool = true

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.isOpaque = false
        view.backgroundColor = .clear
        view.playerLayer.isOpaque = false
        view.playerLayer.backgroundColor = UIColor.clear.cgColor
        view.playerLayer.videoGravity = .resizeAspect
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.load(resourceName: resourceName)
        view.setPlaying(isPlaying)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.resourceName != resourceName {
            uiView.load(resourceName: resourceName)
        }
        uiView.setPlaying(isPlaying)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlayerView, context: Context) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 402, height: 280))
    }

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.tearDown()
    }

    final class PlayerView: UIView {
        var resourceName: String?
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private var looper: AVPlayerLooper?
        private var queuePlayer: AVQueuePlayer?
        private var statusObserver: NSKeyValueObservation?

        func load(resourceName: String) {
            tearDown()
            self.resourceName = resourceName
            configureAudioSession()
            guard let url = Self.bundleURL(for: resourceName) else {
                return
            }
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            looper = AVPlayerLooper(player: player, templateItem: item)
            queuePlayer = player
            playerLayer.player = player
            player.play()

            statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                guard item.status == .failed else { return }
                DispatchQueue.main.async {
                    self?.loadFallback(from: url, resourceName: resourceName)
                }
            }
        }

        func setPlaying(_ playing: Bool) {
            if playing {
                queuePlayer?.play()
            } else {
                queuePlayer?.pause()
            }
        }

        func tearDown() {
            statusObserver = nil
            queuePlayer?.pause()
            looper = nil
            queuePlayer = nil
            playerLayer.player = nil
        }

        private func loadFallback(from failedURL: URL, resourceName: String) {
            let fallbacks = Self.bundleURLs(for: resourceName).filter { $0 != failedURL }
            guard let url = fallbacks.first else { return }
            tearDown()
            self.resourceName = resourceName
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            looper = AVPlayerLooper(player: player, templateItem: item)
            queuePlayer = player
            playerLayer.player = player
            player.play()
        }

        private func configureAudioSession() {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, options: .mixWithOthers)
            try? session.setActive(true)
        }

        static func bundleURL(for resourceName: String) -> URL? {
            bundleURLs(for: resourceName).first
        }

        static func bundleURLs(for resourceName: String) -> [URL] {
            let bundle = Bundle.main
            let extensions = ["mp4", "m4v", "mov"]
            var urls: [URL] = []
            for ext in extensions {
                if let url = bundle.url(forResource: resourceName, withExtension: ext)
                    ?? bundle.url(forResource: resourceName, withExtension: ext, subdirectory: "Videos") {
                    urls.append(url)
                }
            }
            return urls
        }
    }
}
