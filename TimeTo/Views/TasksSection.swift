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

            if !store.completedTasks.isEmpty {
                CompletedTasksRow(tasks: store.completedTasks)
            }
        }
    }
}

struct TaskRow: View {
    @Environment(AppStore.self) private var store
    let task: Task

    private var goal: Goal? { store.goals.first { $0.id == task.goalId } }
    private var isRunning: Bool { store.activeTaskId == task.id }

    var body: some View {
        HStack(spacing: 8) {
            // Complete checkbox
            Button {
                store.completeTask(id: task.id)
            } label: {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 1) {
                Text(task.text)
                    .font(.callout)
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

            // Start timer for this task
            Button {
                let duration = goal?.defaultTimer ?? 1800
                store.startTimer(goalId: task.goalId, taskId: task.id, duration: duration)
            } label: {
                Image(systemName: isRunning ? "timer.circle.fill" : "play.circle")
                    .font(.title3)
                    .foregroundStyle(isRunning ? Color.orange : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(isRunning ? "Timer running" : "Start timer for this task")
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(isRunning ? Color.orange.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .contextMenu {
            Button("Delete", role: .destructive) {
                store.deleteTask(id: task.id)
            }
        }
    }
}

struct CompletedTasksRow: View {
    let tasks: [Task]
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                expanded.toggle()
            } label: {
                HStack {
                    Text("Completed (\(tasks.count))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            if expanded {
                ForEach(tasks) { task in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.callout)
                        Text(task.text)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
    }
}
