import SwiftUI

struct MenuBarContent: View {
    @Environment(AppStore.self) private var store
    @State private var showAddGoal = false
    @State private var showAddTask = false

    var body: some View {
        VStack(spacing: 0) {
            if store.isTimerActive {
                ActiveTimerView()
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GoalsSection(showAddGoal: $showAddGoal)
                        .padding(.bottom, 8)
                    Divider()
                    TasksSection(showAddTask: $showAddTask)
                        .padding(.top, 8)
                }
                .padding(12)
            }
        }
        .frame(width: 340, height: 500)
        .sheet(isPresented: $showAddGoal) {
            AddGoalView()
                .environment(store)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
                .environment(store)
        }
    }
}
