import SwiftUI

struct ChickenMediaView: View {
    let media: ChickenMedia
    var isPlaying: Bool = true
    var fillsBounds: Bool = false
    var loops: Bool = true
    var contentAlignment: Alignment = .center

    var body: some View {
        Group {
            switch media {
            case .image(let name):
                Image(name)
                    .resizable()
                    .modifier(MediaFitModifier(fillsBounds: fillsBounds))
            case .video(let name):
                LoopingVideoPlayer(
                    resourceName: name,
                    isPlaying: isPlaying,
                    frameInterval: media.frameInterval,
                    loopPause: media.loopPause,
                    loops: loops,
                    fillsBounds: fillsBounds,
                    contentAlignment: contentAlignment
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct MediaFitModifier: ViewModifier {
    let fillsBounds: Bool

    func body(content: Content) -> some View {
        if fillsBounds {
            content.scaledToFill()
        } else {
            content.scaledToFit()
        }
    }
}
