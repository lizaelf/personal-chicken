import AVFoundation
import SwiftUI
import UIKit

/// Loops a bundled video silently. Prefers H.264 `.mp4` so Simulator can play
/// clips; ProRes `.mov` is a fallback for devices that decode it.
///
/// Returns a plain `UIView` that SwiftUI sizes, then pins the player to its
/// edges. `UIViewRepresentable` otherwise leaves `AVPlayerLayer` at a tiny frame.
struct LoopingVideoPlayer: UIViewRepresentable {
    let resourceName: String
    var isPlaying: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.isOpaque = false
        container.backgroundColor = .clear
        container.clipsToBounds = true

        let player = PlayerView()
        player.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(player)
        NSLayoutConstraint.activate([
            player.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            player.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            player.topAnchor.constraint(equalTo: container.topAnchor),
            player.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        context.coordinator.player = player
        player.load(resourceName: resourceName)
        player.setPlaying(isPlaying)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let player = context.coordinator.player else { return }
        if player.resourceName != resourceName {
            player.load(resourceName: resourceName)
        }
        player.setPlaying(isPlaying)
        container.setNeedsLayout()
        player.setNeedsLayout()
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.player?.tearDown()
    }

    final class Coordinator {
        var player: PlayerView?
    }

    final class PlayerView: UIView {
        var resourceName: String?
        private let videoLayer = AVPlayerLayer()
        private var looper: AVPlayerLooper?
        private var queuePlayer: AVQueuePlayer?
        private var statusObserver: NSKeyValueObservation?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isOpaque = false
            backgroundColor = .clear
            clipsToBounds = true
            videoLayer.backgroundColor = UIColor.clear.cgColor
            videoLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(videoLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            videoLayer.frame = bounds
            CATransaction.commit()
        }

        func load(resourceName: String) {
            tearDown()
            self.resourceName = resourceName
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, options: .mixWithOthers)
            try? session.setActive(true)

            guard let url = Self.bundleURL(for: resourceName) else { return }
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            looper = AVPlayerLooper(player: player, templateItem: item)
            queuePlayer = player
            videoLayer.player = player
            setNeedsLayout()
            player.play()

            statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                guard item.status == .failed else { return }
                DispatchQueue.main.async {
                    self?.loadFallback(from: url, resourceName: resourceName)
                }
            }
        }

        func setPlaying(_ playing: Bool) {
            if playing { queuePlayer?.play() } else { queuePlayer?.pause() }
        }

        func tearDown() {
            statusObserver = nil
            queuePlayer?.pause()
            looper = nil
            queuePlayer = nil
            videoLayer.player = nil
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
            videoLayer.player = player
            setNeedsLayout()
            player.play()
        }

        static func bundleURL(for resourceName: String) -> URL? {
            bundleURLs(for: resourceName).first
        }

        static func bundleURLs(for resourceName: String) -> [URL] {
            let bundle = Bundle.main
            var urls: [URL] = []
            for ext in ["mp4", "m4v", "mov"] {
                if let url = bundle.url(forResource: resourceName, withExtension: ext)
                    ?? bundle.url(forResource: resourceName, withExtension: ext, subdirectory: "Videos") {
                    urls.append(url)
                }
            }
            return urls
        }
    }
}
