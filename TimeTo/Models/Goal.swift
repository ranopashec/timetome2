import SwiftUI

struct Goal: Identifiable, Codable, Equatable, Hashable {
    var id: Int64
    var name: String
    var emoji: String
    var color: GoalColor
    var defaultTimer: Int      // seconds
    var timerPresets: [Int]    // seconds, shown as quick-start buttons
    var createdAt: Int64
    var isArchived: Bool = false

    // The catch-all "no goal" used for breaks / untracked time
    static let noGoal = Goal(
        id: 1755429367,
        name: "no goal",
        emoji: "👍",
        color: GoalColor(r: 72 / 255, g: 72 / 255, b: 74 / 255, a: 1),
        defaultTimer: 60,
        timerPresets: [600, 900, 1800, 2700, 3600],
        createdAt: 1755429367
    )
}

struct GoalColor: Codable, Equatable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    var color: Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    // Construct from Android-style "r,g,b,a" string where values are 0-255
    init?(androidString: String) {
        let parts = androidString.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 4 else { return nil }
        r = parts[0] / 255
        g = parts[1] / 255
        b = parts[2] / 255
        a = parts[3] / 255
    }

    init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }

    static let accent = GoalColor(r: 0, g: 0.48, b: 1, a: 1)
    static let green  = GoalColor(r: 0.20, g: 0.78, b: 0.35, a: 1)
    static let orange = GoalColor(r: 1, g: 0.58, b: 0, a: 1)
}
