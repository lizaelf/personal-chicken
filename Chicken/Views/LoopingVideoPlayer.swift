import SwiftUI
import UIKit

/// Loops bundled JPEG frames. SwiftUI `Image` sizes reliably — unlike `AVPlayerLayer`.
/// Frame index is derived from the timeline date so we never mutate `@State`
/// during a view update (that crashed Simulator to a white launch screen).
struct LoopingVideoPlayer: View {
    let resourceName: String
    var isPlaying: Bool = true
    var frameInterval: TimeInterval = 1.0 / 10.0
    var loopPause: TimeInterval = 0
    var loops: Bool = true
    var fillsBounds: Bool = false
    var contentAlignment: Alignment = .center

    @State private var frames: [UIImage] = []
    @State private var startedAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: max(frameInterval, 0.04), paused: !isPlaying)) { context in
            Group {
                if fillsBounds {
                    resolvedImage(at: context.date)
                        .resizable()
                        .scaledToFill()
                } else {
                    resolvedImage(at: context.date)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: contentAlignment)
        }
        .task(id: resourceName) {
            frames = Self.loadJPEGs(named: resourceName)
            startedAt = Date()
        }
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
        case "Sequence01": return "ChickenAbs"
        case "SequenceAbs": return "ChickenAbs"
        case "Sequence04": return "ChickenShoulderPress"
        case "SequenceCharm": return "ChickenCharm"
        case "SequenceHome": return "ChickenCharm"
        case "SequenceFreeDay": return "ChickenFreeDay"
        default: return nil
        }
    }

    private func image(at date: Date) -> UIImage? {
        guard !frames.isEmpty else { return nil }
        let step = max(frameInterval, 0.04)
        let playDuration = step * Double(frames.count)
        if !loops {
            let elapsed = max(0, date.timeIntervalSince(startedAt ?? date))
            let i = min(Int(elapsed / step), frames.count - 1)
            return frames[i]
        }
        let cycle = playDuration + max(loopPause, 0)
        let t = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle)
        let i = t >= playDuration ? frames.count - 1 : min(Int(t / step), frames.count - 1)
        return frames[i]
    }

    private static func loadJPEGs(named resourceName: String) -> [UIImage] {
        let bundle = Bundle.main
        let subdirectories = [
            "Frames/\(resourceName)",
            resourceName,
            "Frames",
        ]
        let extensions = ["png", "jpg", "jpeg"]
        for subdirectory in subdirectories {
            for ext in extensions {
                if let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: subdirectory),
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
        }

        guard let root = bundle.resourceURL else { return [] }
        let folder = root.appendingPathComponent("Frames", isDirectory: true)
            .appendingPathComponent(resourceName, isDirectory: true)
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents
            .filter { ["png", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { UIImage(contentsOfFile: $0.path) }
    }
}
