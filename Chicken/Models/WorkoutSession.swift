import Foundation
import Observation

@Observable
final class WorkoutSession {
    enum Phase {
        case workout
        case complete
    }

    let moves: [Move]
    private let startIndex: Int
    var currentIndex: Int
    var elapsed: TimeInterval
    var isPaused = false
    var phase: Phase = .workout

    private var ticker: Timer?
    private let startElapsed: TimeInterval = 4 * 60 + 38

    init(moves: [Move] = WorkoutCatalog.moves, startIndex: Int = 2) {
        self.moves = moves
        self.startIndex = min(max(startIndex, 0), max(moves.count - 1, 0))
        self.currentIndex = self.startIndex
        self.elapsed = startElapsed
        startTicking()
    }

    var currentMove: Move { moves[currentIndex] }
    var completedPipCount: Int { currentIndex + 1 }

    var timeLabel: String {
        let total = max(0, Int(elapsed.rounded(.towardZero)))
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }

    func togglePause() {
        isPaused.toggle()
    }

    func skipToNext() {
        guard phase == .workout else { return }
        if currentIndex + 1 < moves.count {
            currentIndex += 1
            isPaused = false
        } else {
            phase = .complete
            isPaused = true
            stopTicking()
        }
    }

    func restart() {
        currentIndex = startIndex
        elapsed = startElapsed
        isPaused = false
        phase = .workout
        startTicking()
    }

    private func startTicking() {
        stopTicking()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.tolerance = 0.05
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard phase == .workout, !isPaused else { return }
        elapsed += 0.25
    }

    deinit {
        stopTicking()
    }
}
