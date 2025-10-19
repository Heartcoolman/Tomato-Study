import Foundation

actor TimerEngine {
    struct Snapshot: Codable, Sendable {
        var phase: TimerPhase
        var isRunning: Bool
        var remaining: TimeInterval
        var endDate: Date?
        var cycleCount: Int
        var sessionID: UUID
        var completedWorkSessions: Int
    }

    enum Event: Sendable {
        case finished(TimerPhase)
    }

    static let shared = TimerEngine()

    static func placeholder() -> Snapshot {
        let settings = loadSettings()
        return Snapshot(phase: .work,
                        isRunning: false,
                        remaining: TimeInterval(settings.workDuration * 60),
                        endDate: nil,
                        cycleCount: 0,
                        sessionID: UUID(),
                        completedWorkSessions: 0)
    }

    private static func loadSettings() -> SettingsStore.Settings {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "SettingsStore.current"),
           let decoded = try? JSONDecoder().decode(SettingsStore.Settings.self, from: data) {
            return decoded
        }
        return SettingsStore.Settings()
    }

    private let defaults: UserDefaults
    private let storageKey = "TimerEngine.snapshot"
    private let eventCenter = NotificationCenter.default
    private var snapshot: Snapshot
    private var tickTask: Task<Void, Never>?
    private var targetInstant: ContinuousClock.Instant?
    private var observers: [UUID: AsyncStream<Snapshot>.Continuation] = [:]
    private let clock = ContinuousClock()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = stored
            restoreRemaining()
        } else {
        snapshot = TimerEngine.placeholder()
        }
    }

    func observe() -> AsyncStream<Snapshot> {
        AsyncStream { continuation in
            let id = UUID()
            observers[id] = continuation
            continuation.yield(snapshot)
            continuation.onTermination = { [self] _ in
                Task { await self.removeObserver(id) }
            }
        }
    }

    private func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    func snapshotValue() -> Snapshot { snapshot }

    func start(using settings: SettingsStore.Settings) {
        guard !snapshot.isRunning else { return }
        if snapshot.endDate == nil && snapshot.remaining <= 0 {
            let duration = snapshot.phase.duration(using: settings)
            snapshot.remaining = duration
        }
        resumeCountdown(settings: settings)
    }

    func pause() {
        guard snapshot.isRunning else { return }
        if let targetInstant {
            let remaining = seconds(from: targetInstant.duration(from: clock.now))
            snapshot.remaining = max(0, remaining)
        }
        snapshot.isRunning = false
        snapshot.endDate = nil
        targetInstant = nil
        invalidateTick()
        persist()
        notify()
    }

    func reset(using settings: SettingsStore.Settings) {
        snapshot = Snapshot(phase: .work,
                            isRunning: false,
                            remaining: TimerPhase.work.duration(using: settings),
                            endDate: nil,
                            cycleCount: 0,
                            sessionID: UUID(),
                            completedWorkSessions: 0)
        targetInstant = nil
        invalidateTick()
        persist()
        notify()
    }

    func jumpToNext(using settings: SettingsStore.Settings) {
        completeCurrentSession(settings: settings, autoAdvance: true)
    }

    func extend(by minutes: Int, settings: SettingsStore.Settings) {
        snapshot.remaining = max(0, snapshot.remaining + TimeInterval(minutes * 60))
        if snapshot.isRunning {
            resumeCountdown(settings: settings, preserve: true)
        } else {
            persist()
            notify()
        }
    }

    func setPhase(_ phase: TimerPhase, settings: SettingsStore.Settings) {
        snapshot.phase = phase
        snapshot.isRunning = false
        snapshot.remaining = phase.duration(using: settings)
        snapshot.endDate = nil
        targetInstant = nil
        persist()
        notify()
    }

    private func resumeCountdown(settings: SettingsStore.Settings, preserve: Bool = false) {
        snapshot.isRunning = true
        if !preserve {
            snapshot.sessionID = UUID()
        }
        let duration = snapshot.remaining
        let now = clock.now
        targetInstant = now.advanced(by: .seconds(duration))
        snapshot.endDate = Date().addingTimeInterval(duration)
        persist()
        notify()
        scheduleTick()
    }

    private func scheduleTick() {
        invalidateTick()
        tickTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await clock.sleep(until: clock.now.advanced(by: .seconds(1)), tolerance: .milliseconds(30))
                await self.evaluateProgress()
            }
        }
    }

    private func evaluateProgress() {
        guard snapshot.isRunning, let targetInstant else { return }
        let now = clock.now
        let remainingDuration = targetInstant.duration(from: now)
        let remaining = max(0, seconds(from: remainingDuration))
        snapshot.remaining = remaining
        if remaining <= 0.5 {
            let latestSettings = TimerEngine.loadSettings()
            completeCurrentSession(settings: latestSettings, autoAdvance: latestSettings.autoAdvance)
        } else {
            notify()
        }
    }

    private func completeCurrentSession(settings: SettingsStore.Settings, autoAdvance: Bool) {
        let finishedPhase = snapshot.phase
        snapshot.isRunning = false
        snapshot.remaining = 0
        snapshot.endDate = nil
        targetInstant = nil
        invalidateTick()
        persist()
        notify()
        eventCenter.post(name: .timerEngineDidFinishPhase, object: finishedPhase)
        if autoAdvance {
            advance(using: settings)
        }
    }

    func advance(using settings: SettingsStore.Settings) {
        switch snapshot.phase {
        case .work:
            snapshot.completedWorkSessions += 1
            if snapshot.completedWorkSessions % 4 == 0 {
                snapshot.phase = .longBreak
                snapshot.cycleCount += 1
            } else {
                snapshot.phase = .shortBreak
            }
        case .shortBreak, .longBreak:
            snapshot.phase = .work
        }
        snapshot.isRunning = false
        snapshot.remaining = snapshot.phase.duration(using: settings)
        snapshot.endDate = nil
        targetInstant = nil
        persist()
        notify()
    }

    private func restoreRemaining() {
        guard snapshot.isRunning, let endDate = snapshot.endDate else { return }
        let remaining = max(0, endDate.timeIntervalSinceNow)
        snapshot.remaining = remaining
        snapshot.isRunning = remaining > 0
        if snapshot.isRunning {
            targetInstant = clock.now.advanced(by: .seconds(remaining))
            scheduleTick()
        } else {
            snapshot.endDate = nil
            persist()
        }
    }

    private func notify() {
        let snapshot = snapshot
        for continuation in observers.values {
            continuation.yield(snapshot)
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func invalidateTick() {
        tickTask?.cancel()
        tickTask = nil
    }
}

extension Notification.Name {
    static let timerEngineDidFinishPhase = Notification.Name("timerEngineDidFinishPhase")
}

fileprivate func seconds(from duration: Duration) -> TimeInterval {
    let components = duration.components
    return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
}
