import SwiftUI
import UIKit

/// Loops bundled JPEG frames. SwiftUI `Image` sizes reliably — unlike `AVPlayerLayer`.
/// Frame index is derived from the timeline date so we never mutate `@State`
/// during a view update (that crashed Simulator to a white launch screen).
struct LoopingVideoPlayer: View {
    let resourceName: String
    var isPlaying: Bool = true
    var frameInterval: TimeInterval = 1.0 / 10.0

    @State private var frames: [UIImage] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: max(frameInterval, 0.04), paused: !isPlaying)) { context in
            if let image = image(at: context.date) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let fallback {
                Image(fallback)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: resourceName) {
            frames = Self.loadJPEGs(named: resourceName)
        }
    }

    private var fallback: String? {
        switch resourceName {
        case "Sequence01": return "ChickenOverheadPress"
        case "Sequence04": return "ChickenShoulderPress"
        case "SequenceCharm": return "ChickenCharm"
        default: return nil
        }
    }

    private func image(at date: Date) -> UIImage? {
        guard !frames.isEmpty else { return nil }
        let step = max(frameInterval, 0.04)
        let i = Int(date.timeIntervalSinceReferenceDate / step) % frames.count
        return frames[i]
    }

    private static func loadJPEGs(named resourceName: String) -> [UIImage] {
        let bundle = Bundle.main
        let subdirectories = [
            "Frames/\(resourceName)",
            resourceName,
            "Frames",
        ]
        for subdirectory in subdirectories {
            if let urls = bundle.urls(forResourcesWithExtension: "jpg", subdirectory: subdirectory),
               !urls.isEmpty {
                let filtered: [URL]
                if subdirectory == "Frames" {
                    filtered = urls.filter { $0.path.contains("/\(resourceName)/") }
                } else {
                    filtered = urls
                }
                let images = filtered
                    .sorted { $0.lastPathComponent < $1.lastPathComponent }
                    .compactMap { UIImage(contentsOfFile: $0.path) }
                if !images.isEmpty { return images }
            }
        }

        guard let root = bundle.resourceURL else { return [] }
        let folder = root.appendingPathComponent("Frames", isDirectory: true)
            .appendingPathComponent(resourceName, isDirectory: true)
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents
            .filter { $0.pathExtension.lowercased() == "jpg" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}
