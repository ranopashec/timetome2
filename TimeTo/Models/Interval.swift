import Foundation

struct Interval: Identifiable, Codable {
    /// Unix timestamp of when this interval started — also serves as unique ID.
    var id: Int64
    /// Actual duration recorded (seconds). May exceed timerDuration if prolonged.
    var duration: Int
    /// Optional label / task name for this interval.
    var note: String?
    /// Which goal this interval belongs to.
    var goalId: Int64
    /// The original countdown target (seconds). Nil if started without a timer.
    var timerDuration: Int?

    var startDate: Date {
        Date(timeIntervalSince1970: TimeInterval(id))
    }
}
