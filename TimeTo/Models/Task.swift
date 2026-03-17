import Foundation

struct Task: Identifiable, Codable {
    var id: Int64
    var text: String
    /// Every task MUST be attached to a goal. Cannot be nil.
    var goalId: Int64
    var isCompleted: Bool
    var completedAt: Int64?
}
