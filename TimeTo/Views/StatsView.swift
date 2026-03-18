import SwiftUI
import Charts

// MARK: - Main view

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @State private var period: Period = .today
    @State private var offset: Int = 0
    @State private var showAddForm = false

    enum Period: String, CaseIterable {
        case today = "Day"
        case week  = "Week"
    }

    private var atPresent: Bool { offset == 0 }

    private var periodLabel: String {
        switch period {
        case .today:
            if offset == 0  { return "Today" }
            if offset == -1 { return "Yesterday" }
            guard let d = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return "" }
            return d.formatted(.dateTime.month(.abbreviated).day())
        case .week:
            if offset == 0  { return "This week" }
            if offset == -1 { return "Last week" }
            return "\(-offset) weeks ago"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Period + navigation
            HStack(spacing: 8) {
                Picker("", selection: $period) {
                    ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: period) { offset = 0 }

                Spacer()

                HStack(spacing: 2) {
                    Button { offset -= 1 } label: {
                        Image(systemName: "chevron.left").font(.footnote.weight(.semibold))
                    }
                    .buttonStyle(.plain)

                    Text(periodLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 80, alignment: .center)

                    Button { offset = min(offset + 1, 0) } label: {
                        Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                            .foregroundStyle(atPresent ? Color.secondary.opacity(0.25) : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .disabled(atPresent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: []) {
                    let stats = computeStats()

                    if !stats.isEmpty {
                        DonutChart(stats: stats)
                            .frame(height: 160)
                            .padding(.horizontal, 12)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            ForEach(stats) { stat in
                                HStack(spacing: 6) {
                                    Circle().fill(stat.goal.color.color).frame(width: 8, height: 8)
                                    Text(stat.goal.name).font(.callout).lineLimit(1)
                                    Spacer()
                                    Text(stat.percentLabel).font(.callout).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)

                        Divider()
                    }

                    // History
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("HISTORY")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                withAnimation { showAddForm.toggle() }
                            } label: {
                                Image(systemName: showAddForm ? "xmark" : "plus")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)

                        if showAddForm {
                            AddIntervalForm { showAddForm = false }
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                        }

                        let items = historyItems()
                        if items.isEmpty {
                            Text(showAddForm ? "" : "No records in this period")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                        } else {
                            ForEach(items) { item in
                                EditableHistoryRow(item: item)
                            }
                        }
                    }

                    if !showAddForm && computeStats().isEmpty {
                        Text("No activity recorded yet")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Date range

    /// Returns (start, exclusiveEnd) for the selected period+offset. Never crashes.
    private func dateRange() -> (Date, Date) {
        let cal = Calendar.current
        let now = Date()

        switch period {
        case .today:
            let base  = cal.date(byAdding: .day, value: offset, to: now) ?? now
            let start = cal.startOfDay(for: base)
            let end   = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
            return (start, end)

        case .week:
            let base      = cal.date(byAdding: .weekOfYear, value: offset, to: now) ?? now
            let start     = startOfWeek(for: base, cal: cal)
            let end       = cal.date(byAdding: .day, value: 7, to: start) ?? start.addingTimeInterval(7 * 86400)
            return (start, end)
        }
    }

    // MARK: - Computed

    private func computeStats() -> [GoalStat] {
        let items = historyItems()
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

    private func historyItems() -> [HistoryItem] {
        let (cutoff, ceiling) = dateRange()
        let now = Date()

        // Build timeline: all saved intervals + live segment sentinel
        var sorted = store.intervals.sorted { $0.id < $1.id }

        if atPresent, let goalId = store.activeGoalId, let start = store.timerStartDate {
            let activeStart = Int64(start.timeIntervalSince1970)
            // Avoid duplicate if already in sorted
            if sorted.last?.id != activeStart {
                sorted.append(Interval(id: activeStart, goalId: goalId))
            }
            // Sentinel marks end of current segment
            sorted.append(Interval(id: Int64(now.timeIntervalSince1970), goalId: goalId))
        }

        guard sorted.count >= 2 else { return [] }

        var items: [HistoryItem] = []
        for i in 0 ..< sorted.count - 1 {
            let cur   = sorted[i]
            let next  = sorted[i + 1]
            let start = cur.startDate
            guard start >= cutoff, start < ceiling else { continue }
            let dur   = max(0, Int(next.id - cur.id))
            let goal  = store.goals.first { $0.id == cur.goalId }
            items.append(HistoryItem(
                id: cur.id,
                goalId: cur.goalId,
                goalName: goal?.name ?? "Unknown",
                goalColor: goal?.color ?? .accent,
                startDate: start,
                durationSeconds: dur
            ))
        }
        return items.sorted { $0.id > $1.id }
    }
}

// MARK: - Week helper (no force unwraps)

private func startOfWeek(for date: Date, cal: Calendar) -> Date {
    let weekday     = cal.component(.weekday, from: date)
    let daysBack    = (weekday - cal.firstWeekday + 7) % 7
    let monday      = cal.date(byAdding: .day, value: -daysBack, to: date) ?? date
    return cal.startOfDay(for: monday)
}

// MARK: - Editable row

private struct EditableHistoryRow: View {
    @Environment(AppStore.self) private var store
    let item: HistoryItem

    @State private var editing  = false
    @State private var editDate = Date.now

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.timeStyle = .short; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(item.goalColor.color).frame(width: 7, height: 7)
                Text(item.goalName).font(.callout).lineLimit(1)
                Spacer()
                Text(durationLabel(item.durationSeconds))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    editDate = item.startDate
                    withAnimation { editing.toggle() }
                } label: {
                    Text(Self.timeFmt.string(from: item.startDate))
                        .font(.caption)
                        .foregroundStyle(editing ? Color.accentColor : Color.secondary)
                        .underline(editing)
                }
                .buttonStyle(.plain)
                .help("Tap to edit start time")
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)

            if editing {
                HStack(spacing: 8) {
                    DatePicker("", selection: $editDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .datePickerStyle(.stepperField)

                    Button("Save") {
                        store.updateIntervalStart(oldId: item.id, newDate: editDate)
                        editing = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Cancel") { editing = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .contextMenu {
            Button("Delete", role: .destructive) {
                store.deleteInterval(id: item.id)
            }
        }
    }
}

// MARK: - Add interval form

private struct AddIntervalForm: View {
    @Environment(AppStore.self) private var store
    let onDone: () -> Void

    @State private var selectedGoalId: Int64?
    @State private var startDate = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $selectedGoalId) {
                Text("Select goal…").tag(Int64?.none)
                ForEach(store.goals.filter { !$0.isArchived }) { goal in
                    Text(goal.name).tag(Int64?.some(goal.id))
                }
            }
            .labelsHidden()

            DatePicker("", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.stepperField)

            HStack {
                Button("Add") {
                    guard let goalId = selectedGoalId else { return }
                    store.addInterval(Interval(id: Int64(startDate.timeIntervalSince1970), goalId: goalId))
                    onDone()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(selectedGoalId == nil)

                Button("Cancel", action: onDone)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - Chart

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

// MARK: - Models

struct GoalStat: Identifiable {
    var id: Int64 { goal.id }
    let goal: Goal
    let totalSeconds: Int
    let percentage: Double
    var percentLabel: String { "\(Int(percentage * 100))%" }
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
