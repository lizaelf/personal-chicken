import SwiftUI

struct ChickenMediaView: View {
    let media: ChickenMedia
    var isPlaying: Bool = true

    var body: some View {
        Group {
            switch media {
            case .image(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            case .video(let name):
                LoopingVideoPlayer(
                    resourceName: name,
                    isPlaying: isPlaying,
                    frameInterval: media.frameInterval,
                    displayScale: media.displayScale,
                    aspectRatio: media.aspectRatio
                )
            }
        }
        .accessibilityHidden(true)
    }
}
