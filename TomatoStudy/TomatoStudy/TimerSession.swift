import Foundation

struct TimerSession: Codable, Sendable {
    var id: UUID
    var phase: TimerPhase
    var startDate: Date
    var endDate: Date?
    var duration: TimeInterval
}
