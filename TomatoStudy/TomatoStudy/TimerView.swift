import SwiftUI
import UIKit

struct TimerView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var stats: StatsStore
    @State private var selectedPhase: TimerPhase = .work

    private var palette = Palette()

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                CircularTimerView(progress: progress, remaining: formattedRemaining, phase: appState.snapshot.phase)
                    .frame(width: 320, height: 320)
                    .padding(.top, 32)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Remaining time"))
                    .accessibilityValue(Text(formattedRemaining))

                segmentedControl

                HStack(spacing: 16) {
                    primaryButton
                    secondaryButtons
                }
                .padding(.horizontal)

                toggles

                statsSection
            }
            .padding()
        }
        .background(palette.background.ignoresSafeArea())
        .onChange(of: appState.snapshot.phase) { _, newValue in
            selectedPhase = newValue
        }
        .onAppear {
            selectedPhase = appState.snapshot.phase
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("+5") { appState.extend(by: 5) }
                Button("Skip") { appState.skip() }
            }
        }
    }

    private var progress: Double {
        let duration = selectedPhase.duration(using: settings.current)
        guard duration > 0 else { return 0 }
        return max(0, min(1, 1 - (appState.snapshot.remaining / duration)))
    }

    private var formattedRemaining: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: appState.snapshot.remaining) ?? "00:00"
    }

    private var segmentedControl: some View {
        Picker("Phase", selection: $selectedPhase) {
            ForEach(TimerPhase.allCases) { phase in
                Text(phase.title).tag(phase)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPhase) { _, newPhase in
            UIAccessibility.post(notification: .announcement, argument: newPhase.title)
            appState.updatePhase(newPhase)
        }
        .accessibilityLabel(Text("Timer Mode"))
    }

    private var primaryButton: some View {
        Button {
            if appState.snapshot.isRunning {
                appState.pause()
            } else {
                appState.start()
            }
        } label: {
            Text(appState.snapshot.isRunning ? "Pause" : "Start")
                .font(.headline)
                .foregroundStyle(Color(palette.text))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(palette.primary))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(palette.primary).opacity(0.2), radius: 8, y: 6)
        }
        .accessibilityHint(Text(appState.snapshot.isRunning ? "Pause the timer" : "Start the timer"))
    }

    private var secondaryButtons: some View {
        VStack(spacing: 12) {
            Button("Reset") { appState.reset() }
                .buttonStyle(.bordered)
            Button("+5 min") { appState.extend(by: 5) }
                .buttonStyle(.borderedProminent)
            Button("Next") { appState.skip() }
                .buttonStyle(.bordered)
        }
    }

    private var toggles: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Notifications", isOn: Binding(
                get: { settings.current.enableNotifications },
                set: { value in settings.update { $0.enableNotifications = value } }
            ))
            Toggle("Beeps", isOn: Binding(
                get: { settings.current.enableSound },
                set: { value in settings.update { $0.enableSound = value } }
            ))
            Toggle("Haptics", isOn: Binding(
                get: { settings.current.enableHaptics },
                set: { value in settings.update { $0.enableHaptics = value } }
            ))
            Toggle("Auto advance", isOn: Binding(
                get: { settings.current.autoAdvance },
                set: { value in settings.update { $0.autoAdvance = value } }
            ))
            Toggle("Keep awake", isOn: Binding(
                get: { settings.current.keepScreenAwake },
                set: { value in settings.update { $0.keepScreenAwake = value } }
            ))
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(palette.primary)))
        .padding()
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.9)))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.title3).bold()
            HStack(spacing: 16) {
                StatCard(title: "Pomodoros", value: "\(stats.totalPomodoros(for: Date()))", accent: Color(palette.primary))
                StatCard(title: "Minutes", value: "\(stats.totalMinutes(for: Date()))", accent: Color(palette.primary))
                StatCard(title: "Streak", value: "\(stats.streak)", accent: Color(palette.primary))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.white.opacity(0.9)))
    }
}

struct Palette {
    let primary = UIColor(red: 0.71, green: 0.17, blue: 0.18, alpha: 1.0)
    let background = Color(red: 0.976, green: 0.976, blue: 0.960)
    let text = UIColor(red: 0.168, green: 0.168, blue: 0.168, alpha: 1.0)
}

#Preview {
    TimerView()
        .environmentObject(AppState.shared)
        .environmentObject(SettingsStore.shared)
        .environmentObject(StatsStore.shared)
}
