import Foundation
import Observation

@Observable
final class WorkoutSession {
    enum Phase {
        case home
        case countdown
        case workout
        case complete
    }

    let moves: [Move]
    private let startIndex: Int
    var currentIndex: Int
    var elapsed: TimeInterval
    var isPaused = false
    var isAnnouncing = false
    var soundsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundsEnabled, forKey: Self.soundsKey)
            if !soundsEnabled {
                WorkoutCue.stop()
            }
        }
    }
    var phase: Phase = .home

    private var ticker: Timer?
    private var lastRepBucket = -1
    private let startElapsed: TimeInterval = 0
    private var repInterval: TimeInterval { currentMove.repInterval }
    private static let soundsKey = "soundsEnabled"

    init(moves: [Move] = WorkoutCatalog.moves, startIndex: Int = 0) {
        self.moves = moves
        self.startIndex = min(max(startIndex, 0), max(moves.count - 1, 0))
        self.currentIndex = self.startIndex
        self.elapsed = startElapsed
        if UserDefaults.standard.object(forKey: Self.soundsKey) == nil {
            self.soundsEnabled = true
        } else {
            self.soundsEnabled = UserDefaults.standard.bool(forKey: Self.soundsKey)
        }
    }

    func toggleSounds() {
        soundsEnabled.toggle()
    }

    var currentMove: Move { moves[currentIndex] }
    var completedPipCount: Int { currentIndex + 1 }

    var currentSet: Int {
        let total = 20
        return max(1, total - Int(elapsed / repInterval))
    }

    var remainingClock: String {
        let remaining = max(0, currentMove.duration - elapsed)
        let seconds = Int(remaining.rounded(.down))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    func togglePause() {
        isPaused.toggle()
    }

    func beginCountdown() {
        currentIndex = startIndex
        elapsed = startElapsed
        isPaused = true
        isAnnouncing = false
        lastRepBucket = -1
        phase = .countdown
        stopTicking()
        WorkoutCue.prepare()
    }

    func startWorkout() {
        currentIndex = startIndex
        elapsed = startElapsed
        isPaused = true
        isAnnouncing = true
        lastRepBucket = -1
        phase = .workout
        stopTicking()
        Task { await introduceCurrentMove() }
    }

    func goTo(_ target: Int) {
        guard phase == .workout else { return }
        guard target >= 0, target < currentIndex else { return }
        currentIndex = target
        elapsed = startElapsed
        lastRepBucket = -1
        isPaused = true
        isAnnouncing = true
        stopTicking()
        Task { await introduceCurrentMove() }
    }

    func skipToPrevious() {
        guard phase == .workout, currentIndex > 0 else { return }
        goTo(currentIndex - 1)
    }

    func skipToNext() {
        guard phase == .workout else { return }
        if currentIndex + 1 < moves.count {
            currentIndex += 1
            elapsed = startElapsed
            lastRepBucket = -1
            isPaused = true
            isAnnouncing = true
            stopTicking()
            Task { await introduceCurrentMove() }
        } else {
            phase = .complete
            isPaused = true
            isAnnouncing = false
            stopTicking()
            if soundsEnabled {
                WorkoutCue.speakDone()
            }
        }
    }

    private func introduceCurrentMove() async {
        isAnnouncing = true
        if soundsEnabled {
            await WorkoutCue.speakName(currentMove.name)
        } else {
            try? await Task.sleep(for: .milliseconds(350))
        }
        guard phase == .workout else {
            isAnnouncing = false
            return
        }
        isAnnouncing = false
        isPaused = false
        lastRepBucket = -1
        startTicking()
        cueRep()
    }

    func restart() {
        currentIndex = startIndex
        elapsed = startElapsed
        isPaused = false
        isAnnouncing = false
        phase = .home
        stopTicking()
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
        if elapsed >= currentMove.duration {
            skipToNext()
            return
        }
        cueRep()
    }

    private func cueRep() {
        let firstCueDelay: TimeInterval = currentIndex == 0 ? 1.5 : 0
        guard elapsed >= firstCueDelay else { return }
        let bucket = Int(elapsed / repInterval)
        guard bucket != lastRepBucket else { return }
        lastRepBucket = bucket
        guard soundsEnabled else { return }
        WorkoutCue.speakSet(currentSet)
    }

    deinit {
        stopTicking()
    }
}
