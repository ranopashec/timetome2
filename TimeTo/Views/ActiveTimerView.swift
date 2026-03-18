import SwiftUI

struct ActiveTimerView: View {
    @Environment(AppStore.self) private var store
    @State private var showElapsed = false

    private var remaining: Int { store.remainingSeconds }
    private var elapsed: Int   { store.elapsedSeconds }
    private var isOvertime: Bool { remaining < 0 }
    private var goal: Goal? { store.activeGoal }
    private var isNoGoal: Bool { store.activeGoalId == Goal.noGoal.id }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(goal?.color.color ?? .secondary)
                .frame(width: 8, height: 8)

            Text(isNoGoal ? "No goal" : (goal?.name ?? ""))
                .font(.body)
                .foregroundStyle(goal?.color.color ?? .secondary)
                .lineLimit(1)

            Spacer()

            // ⓘ toggles between countdown and elapsed
            Button {
                showElapsed.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(showElapsed ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(showElapsed ? "Showing time invested — tap to show countdown" : "Tap to show time invested in this goal")

            // Tap to log break (10 min no-goal)
            Button {
                store.startTimer(goalId: Goal.noGoal.id, duration: 10 * 60)
            } label: {
                Group {
                    if showElapsed {
                        Text(formatTime(elapsed))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(formatTime(Swift.abs(remaining)))
                            .foregroundStyle(isOvertime ? Color.orange : Color.primary)
                    }
                }
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Tap to log break (10 min, no goal)")

            Button("+10") { store.extendTimer(by: 10 * 60) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
