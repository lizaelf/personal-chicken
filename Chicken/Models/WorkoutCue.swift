import AVFoundation

enum WorkoutCue {
    private static var player: AVAudioPlayer?
    private static var ready = false

    static func prepare() {
        guard !ready else { return }
        ready = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    static func speakSet(_ number: Int) {
        play(resource: "\(number)", subdirectory: "sets")
    }

    static func speakDone() {
        play(resource: "done", subdirectory: "names")
    }

    static func speakName(_ name: String) async {
        prepare()
        let slug = slugify(name)
        guard let url = Bundle.main.url(forResource: slug, withExtension: "wav", subdirectory: "names") else {
            try? await Task.sleep(for: .milliseconds(350))
            return
        }
        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 1
        player?.play()
        let wait = max(player?.duration ?? 0.8, 0.4) + 0.15
        try? await Task.sleep(for: .seconds(wait))
    }

    private static func play(resource: String, subdirectory: String) {
        prepare()
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: subdirectory) else { return }
        player?.stop()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 1
        player?.play()
    }

    private static func slugify(_ name: String) -> String {
        name.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: "-")
    }
}
