import SwiftUI
import UIKit

/// Loops bundled JPEG frames. SwiftUI `Image` sizes reliably — unlike `AVPlayerLayer`.
struct LoopingVideoPlayer: View {
    let resourceName: String
    var isPlaying: Bool = true
    var frameInterval: TimeInterval = 1.0 / 10.0

    @State private var frames: [UIImage] = []
    @State private var index = 0

    var body: some View {
        TimelineView(.periodic(from: .now, by: frameInterval)) { context in
            Group {
                if frames.indices.contains(index) {
                    Image(uiImage: frames[index])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onChange(of: context.date) { _, _ in
                guard isPlaying, frames.count > 1 else { return }
                index = (index + 1) % frames.count
            }
        }
        .onAppear(perform: loadFrames)
        .onChange(of: resourceName) { _, _ in
            index = 0
            loadFrames()
        }
    }

    private func loadFrames() {
        let subdirectory = "Frames/\(resourceName)"
        let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: subdirectory)
            ?? Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: resourceName)
            ?? []
        frames = urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
        if index >= frames.count {
            index = 0
        }
    }
}
