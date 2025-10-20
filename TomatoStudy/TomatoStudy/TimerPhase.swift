import Foundation

enum TimerPhase: String, CaseIterable, Identifiable, Codable, Sendable {
    case work
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: return NSLocalizedString("Work", comment: "Work phase")
        case .shortBreak: return NSLocalizedString("Short Break", comment: "Short break phase")
        case .longBreak: return NSLocalizedString("Long Break", comment: "Long break phase")
        }
    }

    var systemImageName: String {
        switch self {
        case .work: return "timer"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }

    func duration(using settings: SettingsStore.Settings) -> TimeInterval {
        switch self {
        case .work:
            return TimeInterval(settings.workDuration * 60)
        case .shortBreak:
            return TimeInterval(settings.shortBreakDuration * 60)
        case .longBreak:
            return TimeInterval(settings.longBreakDuration * 60)
        }
    }
}
