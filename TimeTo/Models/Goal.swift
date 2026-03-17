import SwiftUI

struct Goal: Identifiable, Codable, Equatable, Hashable {
    var id: Int64
    var name: String
    var color: GoalColor
    var defaultTimer: Int      // seconds
    var timerPresets: [Int]    // seconds, shown as quick-start buttons
    var createdAt: Int64
    var isArchived: Bool = false

    static let noGoal = Goal(
        id: 1755429367,
        name: "No goal",
        color: GoalColor(r: 0.5, g: 0.5, b: 0.55, a: 1),
        defaultTimer: 600,
        timerPresets: [600],
        createdAt: 1755429367
    )
}

struct GoalColor: Codable, Equatable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    var color: Color { Color(red: r, green: g, blue: b, opacity: a) }

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    static let accent = GoalColor(r: 0, g: 0.48, b: 1, a: 1)
    static let green  = GoalColor(r: 0.20, g: 0.78, b: 0.35, a: 1)
    static let orange = GoalColor(r: 1, g: 0.58, b: 0, a: 1)
}
