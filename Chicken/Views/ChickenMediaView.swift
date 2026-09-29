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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .video(let name):
                LoopingVideoPlayer(
                    resourceName: name,
                    isPlaying: isPlaying,
                    frameInterval: media.frameInterval,
                    aspectRatio: media.aspectRatio
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityHidden(true)
    }
}
