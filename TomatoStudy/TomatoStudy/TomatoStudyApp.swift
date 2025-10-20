import SwiftUI
import UserNotifications

@main
struct TomatoStudyApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var settingsStore = SettingsStore.shared
    @StateObject private var statsStore = StatsStore.shared

    init() {
        Task { await NotificationManager.shared.requestAuthorization() }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsStore)
                .environmentObject(statsStore)
                .background(Color(red: 0.976, green: 0.976, blue: 0.960))
                .preferredColorScheme(.light)
        }
        .commands {
            TimerCommands(appState: appState)
        }
    }
}
