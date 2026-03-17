import SwiftUI

struct GoalsSection: View {
    @Environment(AppStore.self) private var store
    @Binding var panel: Panel

    private var goals: [Goal] {
        store.goals.filter { $0.id != Goal.noGoal.id && !$0.isArchived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "GOALS") {
                panel = .addGoal
            }

            if goals.isEmpty {
                Text("No goals yet — tap + to add one")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(goals) { goal in
                    GoalRow(goal: goal)
                }
            }
        }
    }
}

struct GoalRow: View {
    @Environment(AppStore.self) private var store
    let goal: Goal

    private var isActive: Bool { store.activeGoalId == goal.id }
    private var taskCount: Int { store.tasks(for: goal.id).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(goal.emoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 1) {
                    Text(goal.name)
                        .font(.callout)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundStyle(isActive ? goal.color.color : .primary)
                    if taskCount > 0 {
                        Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                // Quick-start preset buttons (show up to 4)
                HStack(spacing: 4) {
                    ForEach(goal.timerPresets.prefix(4), id: \.self) { preset in
                        Button(formatPreset(preset)) {
                            store.startTimer(goalId: goal.id, duration: preset)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .tint(goal.color.color)
                    }
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(isActive ? goal.color.color.opacity(0.12) : Color.clear)
            .cornerRadius(8)
        }
    }
}
