import AVFoundation
import SwiftUI
import UIKit

/// Loops a bundled video silently. Used when `ChickenMedia.video` is set.
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

    static func dismantleUIView(_ uiView: PlayerView, coordinator: ()) {
        uiView.tearDown()
    }

    final class PlayerView: UIView {
        var resourceName: String?
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private var looper: AVPlayerLooper?
        private var queuePlayer: AVQueuePlayer?

        func load(resourceName: String) {
            tearDown()
            self.resourceName = resourceName
            guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mov")
                    ?? Bundle.main.url(forResource: resourceName, withExtension: "mp4") else {
                return
            }
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            looper = AVPlayerLooper(player: player, templateItem: item)
            queuePlayer = player
            playerLayer.player = player
            player.play()
        }

        func setPlaying(_ playing: Bool) {
            if playing {
                queuePlayer?.play()
            } else {
                queuePlayer?.pause()
            }
        }

        func tearDown() {
            queuePlayer?.pause()
            looper = nil
            queuePlayer = nil
            playerLayer.player = nil
        }
    }
}
