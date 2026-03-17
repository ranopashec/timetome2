import SwiftUI

struct ActiveTimerView: View {
    @Environment(AppStore.self) private var store

    private var elapsed: Int { store.elapsedSeconds }
    private var target: Int  { store.timerTargetSeconds }
    private var isOvertime: Bool { target > 0 && elapsed > target }
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(elapsed) / Double(target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Goal + task labels
            HStack {
                if let goal = store.activeGoal {
                    Text(goal.emoji)
                    Text(goal.name)
                        .font(.headline)
                        .foregroundStyle(goal.color.color)
                }
                Spacer()
                if store.isTimerPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let task = store.activeTask {
                Text(task.text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Time display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formatTime(elapsed))
                    .font(.system(.title, design: .monospaced, weight: .semibold))
                    .foregroundStyle(isOvertime ? Color.orange : Color.primary)

                if target > 0 {
                    Text("/ \(formatTime(target))")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 4)
                    Capsule()
                        .fill(isOvertime ? Color.orange : (store.activeGoal?.color.color ?? .accentColor))
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            // Controls
            HStack(spacing: 6) {
                Button(store.isTimerPaused ? "Resume" : "Pause") {
                    store.isTimerPaused ? store.resumeTimer() : store.pauseTimer()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Stop & Save") {
                    store.stopTimer(save: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(.red)

                Spacer()

                Button("+15m") { store.extendTimer(by: 15 * 60) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("+30m") { store.extendTimer(by: 30 * 60) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(12)
    }
}
