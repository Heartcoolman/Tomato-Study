import SwiftUI

@MainActor
struct TimerCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandMenu("Timer") {
            Button(appState.snapshot.isRunning ? "Pause" : "Start") {
                if appState.snapshot.isRunning {
                    appState.pause()
                } else {
                    appState.start()
                }
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Reset") { appState.reset() }
                .keyboardShortcut("r")

            Button("Work") { appState.updatePhase(.work) }
                .keyboardShortcut("1")
            Button("Short Break") { appState.updatePhase(.shortBreak) }
                .keyboardShortcut("2")
            Button("Long Break") { appState.updatePhase(.longBreak) }
                .keyboardShortcut("3")

            Button("Next") { appState.skip() }
                .keyboardShortcut("n")

            Button("+1 minute") { appState.extend(by: 1) }
                .keyboardShortcut(.upArrow, modifiers: [])
            Button("-1 minute") { appState.extend(by: -1) }
                .keyboardShortcut(.downArrow, modifiers: [])
        }
    }
}
