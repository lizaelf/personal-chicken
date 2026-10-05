import Foundation
import CoreGraphics

/// Visual for a move. Swap `.image` for `.video` when looping clips land in the bundle.
enum ChickenMedia: Equatable {
    case image(String)
    case video(String)

    var isVideo: Bool {
        if case .video = self { return true }
        return false
    }

    var nudgeX: CGFloat {
        switch self {
        case .video("Sequence01"): return -14
        case .video("Sequence04"): return -6
        default: return 0
        }
    }

    var displayScale: CGFloat {
        switch self {
        case .video("Sequence01"): return 1.14
        case .video("Sequence04"): return 1.22
        case .video("SequenceCharm"): return 1.5
        case .video("SequenceHome"): return 1.12
        default: return 1
        }
    }

    var frameInterval: TimeInterval {
        switch self {
        case .video("Sequence01"): return 1.0 / 9.0
        case .video("Sequence04"): return 1.0 / 14.0
        case .video("SequenceCharm"): return 1.0 / 10.0
        case .video("SequenceHome"): return 1.0 / 12.0
        default: return 1.0 / 10.0
        }
    }
}

struct Move: Identifiable, Equatable {
    let id: Int
    let name: String
    let duration: TimeInterval
    let repInterval: TimeInterval
    let media: ChickenMedia
}

enum WorkoutCatalog {
    static let moves: [Move] = [
        Move(id: 1, name: "ABS", duration: 20 * 5, repInterval: 5, media: .video("Sequence01")),
        Move(id: 2, name: "Dumbbell shoulder press", duration: 20 * 2, repInterval: 2, media: .video("Sequence04")),
    ]
}
