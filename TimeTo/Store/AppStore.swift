import Foundation
import Observation

@MainActor
@Observable
final class AppStore {

    // MARK: - Persisted state

    var goals: [Goal] = []
    var intervals: [Interval] = []
    var tasks: [Task] = []

    // MARK: - Active timer state

    var activeGoalId: Int64?
    var timerStartDate: Date?
    var timerTargetSeconds: Int = 0

    /// Incremented every second to drive UI refresh.
    private(set) var tick: Int = 0
    private var ticker: Timer?
    private let dataStore = DataStore.shared

    // MARK: - Init

    init() {
        let data = dataStore.load()
        goals     = data.goals
        intervals = data.intervals
        tasks     = data.tasks

        if goals.isEmpty {
            goals = [.noGoal]
        }
    }

    // MARK: - Computed

    var isTimerActive: Bool { activeGoalId != nil }
    var activeGoal: Goal? { goals.first { $0.id == activeGoalId } }

    /// Seconds remaining in the countdown. Negative = overtime.
    var remainingSeconds: Int {
        guard let start = timerStartDate else { return 0 }
        let _ = tick
        return timerTargetSeconds - Int(Date().timeIntervalSince(start))
    }

    /// Total seconds elapsed since current segment started.
    var elapsedSeconds: Int {
        guard let start = timerStartDate else { return 0 }
        let _ = tick
        return Int(Date().timeIntervalSince(start))
    }

    var activeTasks: [Task] { tasks.filter { !$0.isCompleted } }

    func tasks(for goalId: Int64) -> [Task] {
        activeTasks.filter { $0.goalId == goalId }
    }

    // MARK: - Timer control

    func startTimer(goalId: Int64, duration: Int) {
        logCurrentSegment()
        activeGoalId       = goalId
        timerStartDate     = Date()
        timerTargetSeconds = duration
        startTicker()
        persist()
    }

    func extendTimer(by seconds: Int) {
        timerTargetSeconds += seconds
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        persist()
    }

    func deleteGoal(id: Int64) {
        guard id != Goal.noGoal.id else { return }
        goals.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Tasks

    func addTask(_ task: Task) {
        tasks.insert(task, at: 0)
        persist()
    }

    /// Completing a task deletes it immediately — no completed list.
    func completeTask(id: Int64) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    func deleteTask(id: Int64) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Private helpers

    private func logCurrentSegment() {
        guard let goalId = activeGoalId, let start = timerStartDate else { return }
        intervals.insert(Interval(id: Int64(start.timeIntervalSince1970), goalId: goalId), at: 0)
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick += 1 }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func persist() {
        dataStore.save(AppData(version: 1, goals: goals, intervals: intervals, tasks: tasks))
    }
}

// MARK: - Formatting

func formatTime(_ totalSeconds: Int) -> String {
    let abs = Swift.abs(totalSeconds)
    let h = abs / 3600
    let m = (abs % 3600) / 60
    let s = abs % 60
    let sign = totalSeconds < 0 ? "+" : ""
    if h > 0 { return "\(sign)\(h):\(String(format: "%02d", m)):\(String(format: "%02d", s))" }
    return "\(sign)\(m):\(String(format: "%02d", s))"
}

func formatPreset(_ seconds: Int) -> String {
    if seconds < 3600 { return "\(seconds / 60)m" }
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    return m == 0 ? "\(h)h" : "\(h)h\(m)m"
}
