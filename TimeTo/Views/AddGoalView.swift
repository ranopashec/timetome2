import SwiftUI

struct AddGoalView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "⭐"
    @State private var color = GoalColor.accent
    @State private var defaultTimer = 1800
    @State private var presets: [Int] = [900, 1800, 3600]

    private let colorOptions: [(String, GoalColor)] = [
        ("Blue",   .accent),
        ("Green",  .green),
        ("Orange", .orange),
        ("Gray",   GoalColor(r: 0.5, g: 0.5, b: 0.55, a: 1)),
    ]

    private let timerOptions: [(String, Int)] = [
        ("15 min", 900),
        ("30 min", 1800),
        ("45 min", 2700),
        ("1 hour", 3600),
        ("2 hours", 7200),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Goal")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)

            // Emoji + Name
            HStack(spacing: 8) {
                TextField("", text: $emoji)
                    .frame(width: 40)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)

                TextField("Goal name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            // Color
            HStack(spacing: 8) {
                Text("Color")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
                ForEach(colorOptions, id: \.0) { label, c in
                    Circle()
                        .fill(c.color)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle().stroke(Color.primary.opacity(0.3), lineWidth: color == c ? 2 : 0)
                        )
                        .onTapGesture { color = c }
                }
            }

            // Default timer
            Picker("Default timer", selection: $defaultTimer) {
                ForEach(timerOptions, id: \.1) { label, val in
                    Text(label).tag(val)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Add Goal") {
                    guard !name.isEmpty else { return }
                    let goal = Goal(
                        id: Int64(Date().timeIntervalSince1970),
                        name: name,
                        emoji: String(emoji.prefix(2)),
                        color: color,
                        defaultTimer: defaultTimer,
                        timerPresets: [900, 1800, 3600],
                        createdAt: Int64(Date().timeIntervalSince1970)
                    )
                    store.addGoal(goal)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
