import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Section(header: Text("Durations")) {
                durationStepper(title: "Work", value: durationBinding(for: \.$workDuration), range: 15...60)
                durationStepper(title: "Short Break", value: durationBinding(for: \.$shortBreakDuration), range: 3...15)
                durationStepper(title: "Long Break", value: durationBinding(for: \.$longBreakDuration), range: 10...30)
            }

            Section(header: Text("Preferences")) {
                Toggle("Notifications", isOn: binding(for: \.$enableNotifications))
                Toggle("Sound", isOn: binding(for: \.$enableSound))
                Toggle("Haptics", isOn: binding(for: \.$enableHaptics))
                Toggle("Auto advance", isOn: binding(for: \.$autoAdvance))
                Toggle("Keep screen awake", isOn: binding(for: \.$keepScreenAwake))
            }
        }
        .navigationTitle("Settings")
    }

    private func durationStepper(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value.animation(), in: range, step: 1) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue) min")
            }
        }
    }

    private func binding(for keyPath: WritableKeyPath<SettingsStore.Settings, Bool>) -> Binding<Bool> {
        Binding<Bool>(
            get: { settings.current[keyPath: keyPath] },
            set: { newValue in
                settings.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }

    private func durationBinding(for keyPath: WritableKeyPath<SettingsStore.Settings, Int>) -> Binding<Int> {
        Binding<Int>(
            get: { settings.current[keyPath: keyPath] },
            set: { newValue in
                settings.update { $0[keyPath: keyPath] = newValue }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore.shared)
}
