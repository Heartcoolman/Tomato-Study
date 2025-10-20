import SwiftUI
import Combine
import UIKit

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var snapshot: TimerEngine.Snapshot
    @Published var isIdleTimerDisabled: Bool = false

    private let engine = TimerEngine.shared
    private let settingsStore = SettingsStore.shared
    private let statsStore = StatsStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var observeTask: Task<Void, Never>?

    private init() {
        snapshot = TimerEngine.placeholder()
        observe()
        Task { [weak self] in
            guard let self else { return }
            let value = await engine.snapshotValue()
            await MainActor.run {
                self.snapshot = value
            }
        }
        NotificationCenter.default.addObserver(forName: .timerEngineDidFinishPhase, object: nil, queue: .main) { [weak self] notification in
            guard let phase = notification.object as? TimerPhase else { return }
            self?.handleCompletion(for: phase)
        }
    }

    deinit {
        observeTask?.cancel()
    }

    func observe() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let self else { return }
            let stream = await engine.observe()
            for await snapshot in stream {
                await MainActor.run {
                    self.snapshot = snapshot
#if os(iOS)
                    UIApplication.shared.isIdleTimerDisabled = self.shouldDisableIdleTimer(for: snapshot)
#endif
                }
            }
        }
    }

    func start() {
        let settings = settingsStore.current
        Task {
            await engine.start(using: settings)
            if settings.enableNotifications {
                let snapshot = await engine.snapshotValue()
                if let endDate = snapshot.endDate {
                    NotificationManager.shared.clearNotifications()
                    NotificationManager.shared.scheduleNotification(at: endDate, phase: snapshot.phase)
                }
            }
        }
    }

    func pause() {
        Task { await engine.pause() }
        NotificationManager.shared.clearNotifications()
    }

    func reset() {
        let settings = settingsStore.current
        Task { await engine.reset(using: settings) }
        NotificationManager.shared.clearNotifications()
    }

    func skip() {
        let settings = settingsStore.current
        Task { await engine.jumpToNext(using: settings) }
        NotificationManager.shared.clearNotifications()
    }

    func extend(by minutes: Int) {
        let settings = settingsStore.current
        Task { await engine.extend(by: minutes, settings: settings) }
    }

    func advance() {
        let settings = settingsStore.current
        Task { await engine.advance(using: settings) }
    }

    func updatePhase(_ phase: TimerPhase) {
        let settings = settingsStore.current
        Task { await engine.setPhase(phase, settings: settings) }
    }

    private func handleCompletion(for phase: TimerPhase) {
        if settingsStore.current.enableSound {
            SoundManager.shared.playBeep()
        }
        if settingsStore.current.enableHaptics {
            HapticsManager.shared.success()
        }
        NotificationManager.shared.clearNotifications()
        statsStore.recordCompletion(for: phase, duration: phase.duration(using: settingsStore.current))
    }

    private func shouldDisableIdleTimer(for snapshot: TimerEngine.Snapshot) -> Bool {
#if os(iOS)
        settingsStore.current.keepScreenAwake && snapshot.isRunning
#else
        false
#endif
    }
}
