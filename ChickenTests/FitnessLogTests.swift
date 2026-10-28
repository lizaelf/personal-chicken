import XCTest
@testable import Chicken

final class FitnessLogTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private let cal = FitnessLog.calendar
    /// Wednesday, 21 Oct 2026.
    private var today: Date { date("2026-10-21") }
    private let everyOtherDay: Set<String> = ["Mo", "We", "Fr"]

    override func setUp() {
        suite = "FitnessLogTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    private func date(_ key: String) -> Date { FitnessLog.date(from: key)! }

    private func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: today)! }

    // MARK: Weight

    func testWeightPersistsAcrossLaunches() {
        FitnessLog(defaults: defaults).logWeight(70.46, on: today)
        let reopened = FitnessLog(defaults: defaults)
        XCTAssertEqual(reopened.latestWeight, WeightEntry(day: "2026-10-21", kg: 70.5))
    }

    func testSameDayWeightReplacesPrevious() {
        let log = FitnessLog(defaults: defaults)
        log.logWeight(70, on: today)
        log.logWeight(69.4, on: today)
        XCTAssertEqual(log.weights.count, 1)
        XCTAssertEqual(log.latestWeight?.kg, 69.4)
    }

    func testEntriesStaySortedWhenLoggedOutOfOrder() {
        let log = FitnessLog(defaults: defaults)
        log.logWeight(68, on: today)
        log.logWeight(70, on: daysAgo(3))
        XCTAssertEqual(log.weights.map(\.day), ["2026-10-18", "2026-10-21"])
        XCTAssertEqual(log.latestWeight?.kg, 68)
    }

    func testWeeklyChangeNeedsEntryAWeekOld() {
        let log = FitnessLog(defaults: defaults)
        XCTAssertNil(log.weeklyWeightChange)
        log.logWeight(70, on: daysAgo(3))
        log.logWeight(69.5, on: today)
        XCTAssertNil(log.weeklyWeightChange, "3 days is not a week")
        log.logWeight(71, on: daysAgo(7))
        XCTAssertEqual(log.weeklyWeightChange!, -1.5, accuracy: 0.001)
    }

    func testWeeklyChangeUsesLatestEntryBeforeCutoff() {
        let log = FitnessLog(defaults: defaults)
        log.logWeight(75, on: daysAgo(20))
        log.logWeight(72, on: daysAgo(9))
        log.logWeight(71, on: today)
        XCTAssertEqual(log.weeklyWeightChange!, -1, accuracy: 0.001)
    }

    func testRecentWeightsLimitedToTwelveWeeks() {
        let log = FitnessLog(defaults: defaults)
        log.logWeight(80, on: daysAgo(100))
        log.logWeight(75, on: daysAgo(30))
        log.logWeight(74, on: today)
        XCTAssertEqual(log.recentWeights(today: today).map(\.kg), [75, 74])
    }

    // MARK: Streak

    func testNoWorkoutsMeansZeroStreak() {
        XCTAssertEqual(FitnessLog(defaults: defaults).streak(trainingDays: everyOtherDay, today: today), 0)
    }

    func testWorkoutsPersistAcrossLaunches() {
        FitnessLog(defaults: defaults).recordWorkout(on: today)
        XCTAssertEqual(FitnessLog(defaults: defaults).streak(trainingDays: everyOtherDay, today: today), 1)
    }

    func testUnfinishedTodayDoesNotBreakStreak() {
        let log = FitnessLog(defaults: defaults)
        log.recordWorkout(on: daysAgo(2)) // Mon
        XCTAssertEqual(log.streak(trainingDays: everyOtherDay, today: today), 1)
    }

    func testRestDaysAreSkipped() {
        let log = FitnessLog(defaults: defaults)
        ["2026-10-12", "2026-10-14", "2026-10-16", "2026-10-19", "2026-10-21"].forEach { log.recordWorkout(on: date($0)) }
        XCTAssertEqual(log.streak(trainingDays: everyOtherDay, today: today), 5)
    }

    func testMissedTrainingDayBreaksStreak() {
        let log = FitnessLog(defaults: defaults)
        ["2026-10-12", "2026-10-14", "2026-10-19", "2026-10-21"].forEach { log.recordWorkout(on: date($0)) }
        XCTAssertEqual(log.streak(trainingDays: everyOtherDay, today: today), 2, "Fri 16th was skipped")
    }

    func testExtraWorkoutOnRestDayCounts() {
        let log = FitnessLog(defaults: defaults)
        ["2026-10-19", "2026-10-20", "2026-10-21"].forEach { log.recordWorkout(on: date($0)) }
        XCTAssertEqual(log.streak(trainingDays: everyOtherDay, today: today), 3)
    }

    func testSameDayWorkoutCountsOnce() {
        let log = FitnessLog(defaults: defaults)
        log.recordWorkout(on: today)
        log.recordWorkout(on: today.addingTimeInterval(3600))
        XCTAssertEqual(log.streak(trainingDays: everyOtherDay, today: today), 1)
    }

    func testDailyScheduleBreaksOnAnyMissedDay() {
        let log = FitnessLog(defaults: defaults)
        let daily: Set<String> = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        [daysAgo(4), daysAgo(1), today].forEach { log.recordWorkout(on: $0) }
        XCTAssertEqual(log.streak(trainingDays: daily, today: today), 2)
    }

    func testCalendarMarksWorkoutDays() {
        let log = FitnessLog(defaults: defaults)
        log.recordWorkout(on: today)
        XCTAssertTrue(log.didWorkout(year: 2026, month: 10, day: 21))
        XCTAssertFalse(log.didWorkout(year: 2026, month: 10, day: 20))
    }
}
