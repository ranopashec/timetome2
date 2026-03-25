import SwiftUI

struct AddTaskView: View {
    @Environment(AppStore.self) private var store
    @Binding var panel: Panel

    @State private var text = ""
    @State private var selectedGoalId: Int64? = nil

    private var selectableGoals: [Goal] {
        store.goals.filter { $0.id != Goal.noGoal.id && !$0.isArchived }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Task")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)

            TextField("What needs to be done?", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Goal (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("", selection: $selectedGoalId) {
                    Text("No goal").tag(Int64?.none)
                    ForEach(selectableGoals) { goal in
                        Text(goal.name).tag(Int64?.some(goal.id))
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()

                Text("If no goal is selected, the task is stored under No goal.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancel") { panel = .main }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Add Task") {
                    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmedText.isEmpty else { return }
                    let task = Task(
                        id: Int64(Date().timeIntervalSince1970),
                        text: trimmedText,
                        goalId: selectedGoalId ?? Goal.noGoal.id,
                        isCompleted: false
                    )
                    store.addTask(task)
                    panel = .main
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
