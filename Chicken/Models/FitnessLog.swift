import Foundation
import Observation

struct WeightEntry: Codable, Equatable {
    /// Local calendar day, `yyyy-MM-dd`.
    let day: String
    let kg: Double
}

@Observable
final class FitnessLog {
    private(set) var weights: [WeightEntry]
    private(set) var workoutDays: Set<String>

    private let defaults: UserDefaults
    private static let weightsKey = "fitness.weights"
    private static let workoutsKey = "fitness.workoutDays"
    private static let weekdayIds = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.weightsKey),
           let saved = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            weights = saved.sorted { $0.day < $1.day }
        } else {
            weights = []
        }
        workoutDays = Set(defaults.stringArray(forKey: Self.workoutsKey) ?? [])
    }

    var latestWeight: WeightEntry? { weights.last }

    func logWeight(_ kg: Double, on date: Date = .now) {
        let day = Self.key(for: date)
        weights.removeAll { $0.day == day }
        weights.append(WeightEntry(day: day, kg: (kg * 10).rounded() / 10))
        weights.sort { $0.day < $1.day }
        if let data = try? JSONEncoder().encode(weights) {
            defaults.set(data, forKey: Self.weightsKey)
        }
    }

    func recordWorkout(on date: Date = .now) {
        workoutDays.insert(Self.key(for: date))
        defaults.set(workoutDays.sorted(), forKey: Self.workoutsKey)
    }

    func didWorkout(year: Int, month: Int, day: Int) -> Bool {
        workoutDays.contains(String(format: "%04d-%02d-%02d", year, month, day))
    }

    /// Latest weight minus the last entry logged at least 7 days before it.
    var weeklyWeightChange: Double? {
        guard let latest = weights.last,
              let latestDate = Self.date(from: latest.day),
              let weekAgo = Self.calendar.date(byAdding: .day, value: -7, to: latestDate) else { return nil }
        let cutoff = Self.key(for: weekAgo)
        guard let base = weights.last(where: { $0.day <= cutoff }) else { return nil }
        return latest.kg - base.kg
    }

    /// Entries from the last 12 weeks, oldest first.
    func recentWeights(weeks: Int = 12, today: Date = .now) -> [WeightEntry] {
        guard let start = Self.calendar.date(byAdding: .day, value: -7 * weeks, to: today) else { return weights }
        let cutoff = Self.key(for: start)
        return weights.filter { $0.day >= cutoff }
    }

    /// Consecutive workouts counted back from today. Days outside the training
    /// schedule and today (still open) never break the streak.
    func streak(trainingDays: Set<String>, today: Date = .now) -> Int {
        guard let first = workoutDays.min() else { return 0 }
        var count = 0
        var day = Self.calendar.startOfDay(for: today)
        var isToday = true
        while true {
            let key = Self.key(for: day)
            if key < first { break }
            if workoutDays.contains(key) {
                count += 1
            } else if !isToday && trainingDays.contains(Self.weekdayId(for: day)) {
                break
            }
            guard let previous = Self.calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
            isToday = false
        }
        return count
    }

    static func key(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func date(from key: String) -> Date? {
        dayFormatter.date(from: key)
    }

    static func weekdayId(for date: Date) -> String {
        weekdayIds[calendar.component(.weekday, from: date) - 1]
    }
}
