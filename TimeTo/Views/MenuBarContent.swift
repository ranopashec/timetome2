import SwiftUI

enum Panel {
    case main, addGoal, addTask
}

enum AppTab {
    case timer, stats
}

struct MenuBarContent: View {
    @Environment(AppStore.self) private var store
    @State private var panel: Panel = .main
    @State private var tab: AppTab = .timer

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                TabButton(label: "Timer", systemImage: "timer", selected: tab == .timer) {
                    tab = .timer; panel = .main
                }
                TabButton(label: "Stats", systemImage: "chart.pie", selected: tab == .stats) {
                    tab = .stats
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            switch tab {
            case .timer:
                switch panel {
                case .main:    MainPanel(panel: $panel)
                case .addGoal: AddGoalView(panel: $panel)
                case .addTask: AddTaskView(panel: $panel)
                }
            case .stats:
                StatsView()
                    .frame(height: 480)
            }
        }
        .frame(width: 360)
        .environment(store)
    }
}

private struct TabButton: View {
    let label: String
    let systemImage: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage).font(.footnote)
                Text(label).font(.footnote.weight(.medium))
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 12)
            .background(selected ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
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
                        .padding(.bottom, 10)
                    Divider()
                    TasksSection(panel: $panel)
                        .padding(.top, 10)
                }
                .padding(14)
            }

            Divider()
            HStack {
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut("q", modifiers: .command)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .frame(width: 360, height: 500)
    }
}
