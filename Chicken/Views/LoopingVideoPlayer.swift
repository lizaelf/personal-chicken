import SwiftUI
import UIKit

/// Loops bundled JPEG frames. SwiftUI `Image` sizes reliably — unlike `AVPlayerLayer`.
/// Frame index is derived from the timeline date so we never mutate `@State`
/// during a view update (that crashed Simulator to a white launch screen).
struct LoopingVideoPlayer: View {
    let resourceName: String
    var isPlaying: Bool = true
    var frameInterval: TimeInterval = 1.0 / 10.0
    var aspectRatio: CGFloat = 1.45

    @State private var frames: [UIImage] = []

    var body: some View {
        GeometryReader { geo in
            let size = Self.containedSize(in: geo.size, aspectRatio: aspectRatio)
            TimelineView(.animation(minimumInterval: max(frameInterval, 0.04), paused: !isPlaying)) { context in
                resolvedImage(at: context.date)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .clipped()
        .task(id: resourceName) {
            frames = Self.loadJPEGs(named: resourceName)
        }
    }

    /// Fit the clip inside the slot without ever exceeding its width or height.
    private static func containedSize(in bounds: CGSize, aspectRatio: CGFloat) -> CGSize {
        let ratio = max(aspectRatio, 0.1)
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        let heightIfFullWidth = bounds.width / ratio
        if heightIfFullWidth <= bounds.height {
            return CGSize(width: bounds.width, height: heightIfFullWidth)
        }
        return CGSize(width: bounds.height * ratio, height: bounds.height)
    }

    private func resolvedImage(at date: Date) -> Image {
        if let image = image(at: date) {
            return Image(uiImage: image)
        }
        if let fallback {
            return Image(fallback)
        }
        return Image(systemName: "photo")
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
