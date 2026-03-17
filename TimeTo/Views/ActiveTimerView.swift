import SwiftUI

struct ActiveTimerView: View {
    @Environment(AppStore.self) private var store

    private var remaining: Int { store.remainingSeconds }
    private var isOvertime: Bool { remaining < 0 }
    private var goal: Goal? { store.activeGoal }
    private var isNoGoal: Bool { store.activeGoalId == Goal.noGoal.id }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(goal?.color.color ?? .secondary)
                .frame(width: 8, height: 8)

            Text(isNoGoal ? "No goal" : (goal?.name ?? ""))
                .font(.callout)
                .foregroundStyle(goal?.color.color ?? .secondary)
                .lineLimit(1)

            Spacer()

            // Tap to log current segment and start 10-min no-goal break
            Button {
                store.startTimer(goalId: Goal.noGoal.id, duration: 10 * 60)
            } label: {
                Text(formatTime(Swift.abs(remaining)))
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                    .foregroundStyle(isOvertime ? Color.orange : Color.primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Tap to log break (10 min, no goal)")

            Button("+10") { store.extendTimer(by: 10 * 60) }
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
