import Foundation

struct DaySummary: Identifiable, Codable, Sendable {
    var date: Date
    var pomodoros: Int
    var minutes: Int

    var id: Date { date }
}

@MainActor
final class StatsStore: ObservableObject {
    static let shared = StatsStore()

    @Published private(set) var summaries: [DaySummary]
    @Published private(set) var streak: Int

    private let storageKey = "StatsStore.summaries"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode([DaySummary].self, from: data) {
            summaries = stored
        } else {
            summaries = []
        }
        streak = 0
        normalize()
        streak = computeStreak(asOf: Date())
    }

    func recordCompletion(for phase: TimerPhase, duration: TimeInterval) {
        guard phase == .work else { return }
        let today = Calendar.current.startOfDay(for: Date())
        if let index = summaries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            summaries[index].pomodoros += 1
            summaries[index].minutes += Int(duration / 60)
        } else {
            summaries.append(DaySummary(date: today, pomodoros: 1, minutes: Int(duration / 60)))
        }
        streak = computeStreak(asOf: Date())
        persist()
    }

    func weekTotalMinutes() -> Int {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: Date()) else { return totalMinutes(for: Date()) }
        return summaries.filter { $0.date >= Calendar.current.startOfDay(for: weekAgo) }
            .reduce(0) { $0 + $1.minutes }
    }

    func totalMinutes(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return summaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: start) })?.minutes ?? 0
    }

    func totalPomodoros(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return summaries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: start) })?.pomodoros ?? 0
    }

    func exportCSV() -> String {
        var rows = ["Date,Pomodoros,Minutes"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for summary in summaries.sorted(by: { $0.date < $1.date }) {
            let dateString = formatter.string(from: summary.date)
            rows.append("\(dateString),\(summary.pomodoros),\(summary.minutes)")
        }
        return rows.joined(separator: "\n")
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(summaries) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func normalize() {
        summaries = summaries.filter { $0.date <= Date() }
        if summaries.count > 60 {
            summaries = Array(summaries.suffix(60))
        }
        summaries.sort { $0.date < $1.date }
    }

    private func computeStreak(asOf date: Date) -> Int {
        let calendar = Calendar.current
        let unique = summaries.filter { $0.pomodoros > 0 }
        var streakCount = 0
        var cursor = calendar.startOfDay(for: date)
        while true {
            if unique.contains(where: { calendar.isDate($0.date, inSameDayAs: cursor) }) {
                streakCount += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previous
            } else {
                break
            }
        }
        return streakCount
    }
}
