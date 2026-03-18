import SwiftUI

struct TasksSection: View {
    @Environment(AppStore.self) private var store
    @Binding var panel: Panel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "TASKS") {
                panel = .addTask
            }

            if store.activeTasks.isEmpty {
                Text("No tasks — tap + to add one (requires a goal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.activeTasks) { task in
                    TaskRow(task: task)
                }
            }
        }
    }
}

struct TaskRow: View {
    @Environment(AppStore.self) private var store
    let task: Task

    private var goal: Goal? { store.goals.first { $0.id == task.goalId } }

    var body: some View {
        HStack(spacing: 8) {
            // Complete → deletes the task
            Button {
                store.completeTask(id: task.id)
            } label: {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(task.text)
                    .font(.body)
                    .lineLimit(2)

                if let goal {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(goal.color.color)
                            .frame(width: 6, height: 6)
                        Text(goal.name)
                            .font(.caption2)
                            .foregroundStyle(goal.color.color)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .cornerRadius(8)
        .contextMenu {
            Button("Delete", role: .destructive) {
                store.deleteTask(id: task.id)
            }
        }
    }
}
