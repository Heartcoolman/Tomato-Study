import XCTest
@testable import TomatoStudy

final class TimerEngineTests: XCTestCase {
    override func setUp() async throws {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "TimerEngine.snapshot")
        defaults.removeObject(forKey: "SettingsStore.current")
    }

    func testLongBreakAfterFourWorkSessions() async throws {
        let engine = TimerEngine.shared
        let settings = SettingsStore.Settings(workDuration: 1, shortBreakDuration: 1, longBreakDuration: 1, enableNotifications: false, enableSound: false, enableHaptics: false, autoAdvance: true, keepScreenAwake: false)
        await engine.setPhase(.work, settings: settings)
        await engine.reset(using: settings)

        for index in 1...4 {
            await engine.advance(using: settings)
            let breakSnapshot = await engine.snapshotValue()
            if index < 4 {
                XCTAssertEqual(breakSnapshot.phase, .shortBreak)
            } else {
                XCTAssertEqual(breakSnapshot.phase, .longBreak)
            }
            await engine.advance(using: settings)
            let workSnapshot = await engine.snapshotValue()
            XCTAssertEqual(workSnapshot.phase, .work)
        }
    }

    func testExtendClampsToZero() async throws {
        let engine = TimerEngine.shared
        let settings = SettingsStore.Settings(workDuration: 1, shortBreakDuration: 1, longBreakDuration: 1, enableNotifications: false, enableSound: false, enableHaptics: false, autoAdvance: true, keepScreenAwake: false)
        await engine.setPhase(.work, settings: settings)
        await engine.extend(by: -100, settings: settings)
        let snapshot = await engine.snapshotValue()
        XCTAssertGreaterThanOrEqual(snapshot.remaining, 0)
    }
}
