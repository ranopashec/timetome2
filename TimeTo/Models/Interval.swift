import Foundation

/// A single logged activity segment.
/// Duration is derived: nextInterval.id - thisInterval.id (or now - id for the current one).
struct Interval: Identifiable, Codable {
    /// Unix timestamp of when this segment started — also the unique ID.
    var id: Int64
    var goalId: Int64

    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(id)) }
}
