import XCTest

final class ChickenUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start"].firstMatch.waitForExistence(timeout: 10), "Home did not appear after splash")
    }

    func testLaunchShowsHome() {
        XCTAssertTrue(app.staticTexts["Abs & Glutes"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Add weight"].exists)
        XCTAssertTrue(app.buttons["Settings"].firstMatch.exists)
        for tab in ["Home", "Workouts", "Statistics"] {
            XCTAssertTrue(app.buttons[tab].exists, "Missing tab \(tab)")
        }
    }

    func testTabNavigation() {
        app.buttons["Workouts"].tap()
        XCTAssertTrue(app.staticTexts["Extra workouts"].waitForExistence(timeout: 3))

        app.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Calories burned"].firstMatch.waitForExistence(timeout: 3))

        app.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["Start"].firstMatch.waitForExistence(timeout: 3))
    }

    func testSettingsSoundsToggleAndNotifications() {
        app.buttons["Settings"].firstMatch.tap()
        let sounds = app.switches["Sounds"].firstMatch
        XCTAssertTrue(sounds.waitForExistence(timeout: 3))

        let before = sounds.value as? String
        flip(sounds)
        XCTAssertNotEqual(sounds.value as? String, before, "Sounds toggle did not change")
        flip(sounds)
        XCTAssertEqual(sounds.value as? String, before)

        XCTAssertTrue(app.staticTexts["Version"].exists)
        XCTAssertFalse(app.staticTexts["beta"].exists, "Beta label must not ship to the App Store")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Notifications'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Notifications"].firstMatch.waitForExistence(timeout: 3))
    }

    func testLogWeight() {
        app.buttons["Add weight"].tap()
        let log = app.buttons["Log weight"]
        XCTAssertTrue(log.waitForExistence(timeout: 3))

        let wheels = app.pickerWheels
        XCTAssertEqual(wheels.count, 2)
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: "70")
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: "5")
        log.tap()

        XCTAssertTrue(log.waitForNonExistence(timeout: 3), "Weight sheet did not close")
        let logged = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '70.5'")).firstMatch
        XCTAssertTrue(logged.waitForExistence(timeout: 3), "Logged weight is not shown on Home")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Start"].firstMatch.waitForExistence(timeout: 10))
        let restored = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '70.5'")).firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 3), "Weight was not saved across launches")
    }

    func testWeightSheetDismissesByDrag() {
        app.buttons["Add weight"].tap()
        let title = app.staticTexts["Your current weight"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.press(forDuration: 0.05, thenDragTo: app.buttons["Home"])
        XCTAssertTrue(app.buttons["Log weight"].waitForNonExistence(timeout: 3), "Sheet did not close on drag")
    }

    func testFullWorkoutFlow() {
        app.buttons["Start"].firstMatch.tap()
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 8), "Workout did not start after countdown")
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5) || app.buttons["Resume"].exists)

        next.tap()
        XCTAssertTrue(app.buttons["Previous"].waitForExistence(timeout: 3))
        next.tap()

        let charm = app.buttons["I’ll charm you into coming back! Tap to start again."]
        let reachedEnd = charm.waitForExistence(timeout: 5)
            || app.otherElements["I’ll charm you into coming back! Tap to start again."].exists
        XCTAssertTrue(reachedEnd, "Completion screen did not appear")
        XCTAssertTrue(app.buttons["Start"].firstMatch.waitForExistence(timeout: 8), "Did not return Home after completion")
        XCTAssertGreaterThanOrEqual(streak(), 1, "Finished workout did not count towards the streak")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Start"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(streak(), 1, "Streak was not saved across launches")
    }

    private func streak() -> Int {
        let label = app.buttons.matching(NSPredicate(format: "label ENDSWITH 'streak'")).firstMatch.label
        return Int(label.split(separator: " ").first ?? "") ?? -1
    }

    func testAccessibilityAudit() throws {
        var issues: [String] = []
        let screens: [(String, () -> Void)] = [
            ("Home", {}),
            ("Workouts", { self.app.buttons["Workouts"].tap() }),
            ("Statistics", { self.app.buttons["Statistics"].tap() }),
            ("Settings", { self.app.buttons["Home"].tap(); self.app.buttons["Settings"].firstMatch.tap() }),
        ]
        for (name, open) in screens {
            open()
            sleep(1)
            try app.performAccessibilityAudit(for: .all) { issue in
                let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)'" } ?? "—"
                issues.append("[\(name)] \(issue.compactDescription) → \(element)")
                return true
            }
        }
        print("ACCESSIBILITY ISSUES (\(issues.count)):\n" + issues.joined(separator: "\n"))
        XCTAssertTrue(issues.isEmpty, "\(issues.count) accessibility issues:\n" + issues.joined(separator: "\n"))
    }

    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testFreshInstallHasNoFakeData() throws {
        app.terminate()
        let fresh = XCUIApplication()
        fresh.launchArguments += ["-fitness.weights", "", "-fitness.workoutDays", "()"]
        fresh.launch()
        XCTAssertTrue(fresh.buttons["Start"].firstMatch.waitForExistence(timeout: 10))
        let streak = fresh.buttons.matching(NSPredicate(format: "label ENDSWITH 'streak'")).firstMatch
        XCTAssertTrue(streak.waitForExistence(timeout: 3), "Streak badge should show the calendar count")
        XCTAssertFalse(streak.label.hasPrefix("4 "), "Streak must follow the statistics calendar, not a fixed sample")
        XCTAssertTrue(fresh.staticTexts["Log your first weigh-in."].exists, "Weight must start empty")
        XCTAssertFalse(fresh.staticTexts["62.4 kg"].exists)
    }

    private func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    }
}
