import SwiftUI
import Charts

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @State private var period: Period = .today

    enum Period: String, CaseIterable {
        case today = "Today"
        case week  = "Week"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Period picker
            Picker("", selection: $period) {
                ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let stats = computeStats(period: period)

                    if stats.isEmpty {
                        Text("No activity recorded yet")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else {
                        // Donut chart
                        DonutChart(stats: stats)
                            .frame(height: 180)
                            .padding(.horizontal, 12)

                        // Legend
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(stats) { stat in
                                HStack(spacing: 6) {
                                    Circle().fill(stat.goal.color.color).frame(width: 8, height: 8)
                                    Text(stat.goal.name)
                                        .font(.callout)
                                        .lineLimit(1)
                                    Spacer()
                                    Text(stat.percentLabel)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)

                        Divider()

                        // History list
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HISTORY")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)

                            ForEach(historyItems(period: period)) { item in
                                HistoryRow(item: item)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Computed

    private func computeStats(period: Period) -> [GoalStat] {
        let items = historyItems(period: period)
        var totals: [Int64: Int] = [:]
        for item in items { totals[item.goalId, default: 0] += item.durationSeconds }
        let grandTotal = totals.values.reduce(0, +)
        guard grandTotal > 0 else { return [] }
        return totals.compactMap { goalId, secs -> GoalStat? in
            guard let goal = store.goals.first(where: { $0.id == goalId }) else { return nil }
            return GoalStat(goal: goal, totalSeconds: secs, percentage: Double(secs) / Double(grandTotal))
        }
        .sorted { $0.totalSeconds > $1.totalSeconds }
    }

    private func historyItems(period: Period) -> [HistoryItem] {
        let cutoff: Date = period == .today
            ? Calendar.current.startOfDay(for: Date())
            : Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // Sorted oldest→newest for duration math
        var sorted = store.intervals.sorted { $0.id < $1.id }

        // Append synthetic "current" interval if timer is active
        if let goalId = store.activeGoalId, let start = store.timerStartDate {
            sorted.append(Interval(id: Int64(Date().timeIntervalSince1970), goalId: goalId))
            // the real active interval start
            let activeStart = Int64(start.timeIntervalSince1970)
            // replace placeholder with actual start
            if let lastReal = sorted.dropLast().last, lastReal.id != activeStart {
                sorted.insert(Interval(id: activeStart, goalId: goalId), at: sorted.count - 1)
            }
        }

        var items: [HistoryItem] = []
        for i in 0..<sorted.count - 1 {
            let cur  = sorted[i]
            let next = sorted[i + 1]
            let start = cur.startDate
            guard start >= cutoff else { continue }
            let dur = max(0, Int(next.id - cur.id))
            items.append(HistoryItem(
                id: cur.id,
                goalId: cur.goalId,
                goalName: store.goals.first(where: { $0.id == cur.goalId })?.name ?? "Unknown",
                goalColor: store.goals.first(where: { $0.id == cur.goalId })?.color ?? .accent,
                startDate: start,
                durationSeconds: dur
            ))
        }
        return items.sorted { $0.id > $1.id } // newest first for display
    }
}

// MARK: - Sub-views

private struct DonutChart: View {
    let stats: [GoalStat]

    var body: some View {
        Chart(stats) { stat in
            SectorMark(
                angle: .value("Time", stat.totalSeconds),
                innerRadius: .ratio(0.58),
                angularInset: 2
            )
            .cornerRadius(4)
            .foregroundStyle(stat.goal.color.color)
        }
    }
}

private struct HistoryRow: View {
    let item: HistoryItem

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(item.goalColor.color).frame(width: 7, height: 7)
            Text(item.goalName)
                .font(.callout)
                .lineLimit(1)
            Spacer()
            Text(durationLabel(item.durationSeconds))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(Self.timeFmt.string(from: item.startDate))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
    }
}

// MARK: - Models

struct GoalStat: Identifiable {
    var id: Int64 { goal.id }
    let goal: Goal
    let totalSeconds: Int
    let percentage: Double

    var percentLabel: String { "\(Int(percentage * 100))%" }
    var durationLabel: String { formatTime(totalSeconds) }
}

struct HistoryItem: Identifiable {
    let id: Int64
    let goalId: Int64
    let goalName: String
    let goalColor: GoalColor
    let startDate: Date
    let durationSeconds: Int
}

private func durationLabel(_ s: Int) -> String {
    let h = s / 3600; let m = (s % 3600) / 60; let sec = s % 60
    if h > 0 { return "\(h)h \(m)m" }
    if m > 0 { return "\(m)m \(sec)s" }
    return "\(sec)s"
}
