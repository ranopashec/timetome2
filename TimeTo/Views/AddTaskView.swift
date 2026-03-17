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

            if selectableGoals.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text("Add a goal first. Tasks must belong to a goal.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal (required)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $selectedGoalId) {
                        Text("Select a goal…").tag(Int64?.none)
                        ForEach(selectableGoals) { goal in
                            Label(goal.name, systemImage: "")
                                .tag(Int64?.some(goal.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            HStack {
                Button("Cancel") { panel = .main }
                    .keyboardShortcut(.escape)
                Spacer()
                Button("Add Task") {
                    guard !text.isEmpty, let goalId = selectedGoalId else { return }
                    let task = Task(
                        id: Int64(Date().timeIntervalSince1970),
                        text: text,
                        goalId: goalId,
                        isCompleted: false
                    )
                    store.addTask(task)
                    panel = .main
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty || selectedGoalId == nil)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
