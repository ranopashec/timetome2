import SwiftUI

enum Panel {
    case main, addGoal, addTask
}

struct MenuBarContent: View {
    @Environment(AppStore.self) private var store
    @State private var panel: Panel = .main

    var body: some View {
        Group {
            switch panel {
            case .main:
                MainPanel(panel: $panel)
            case .addGoal:
                AddGoalView(panel: $panel)
            case .addTask:
                AddTaskView(panel: $panel)
            }
        }
        .frame(width: 340)
        .environment(store)
    }
}

private struct MainPanel: View {
    @Environment(AppStore.self) private var store
    @Binding var panel: Panel

    var body: some View {
        VStack(spacing: 0) {
            if store.isTimerActive {
                ActiveTimerView()
                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    GoalsSection(panel: $panel)
                        .padding(.bottom, 8)
                    Divider()
                    TasksSection(panel: $panel)
                        .padding(.top, 8)
                }
                .padding(12)
            }
        }
        .frame(width: 340, height: 500)
    }
}
