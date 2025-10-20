import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    struct Settings: Codable, Sendable {
        var workDuration: Int = 25
        var shortBreakDuration: Int = 5
        var longBreakDuration: Int = 15
        var enableNotifications: Bool = true
        var enableSound: Bool = true
        var enableHaptics: Bool = true
        var autoAdvance: Bool = true
        var keepScreenAwake: Bool = true
    }

    static let shared = SettingsStore()

    @Published private(set) var current: Settings

    private let storageKey = "SettingsStore.current"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode(Settings.self, from: data) {
            current = stored
        } else {
            current = Settings()
        }
    }

    func update(_ updateBlock: (inout Settings) -> Void) {
        updateBlock(&current)
        persist()
    }

    func persist() {
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
