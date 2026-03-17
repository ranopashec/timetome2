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
    var activeTaskId: Int64?
    var timerTargetSeconds: Int = 0

    private var originalStartDate: Date?       // when the timer was first started (survives pauses)
    private var timerStartDate: Date?          // when the current running segment began
    private var accumulatedSeconds: TimeInterval = 0  // seconds from previous paused segments

    private(set) var currentElapsed: TimeInterval = 0
    private var ticker: Timer?

    // MARK: - Init

    private let dataStore = DataStore.shared

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

    var isTimerRunning: Bool { timerStartDate != nil }
    var isTimerPaused:  Bool { timerStartDate == nil && accumulatedSeconds > 0 && activeGoalId != nil }
    var isTimerActive:  Bool { activeGoalId != nil }

    var activeGoal: Goal? { goals.first { $0.id == activeGoalId } }
    var activeTask: Task? { tasks.first { $0.id == activeTaskId } }

    var elapsedSeconds: Int { Int(currentElapsed) }

    var elapsedLabel: String { formatTime(elapsedSeconds) }

    var activeTasks: [Task]     { tasks.filter { !$0.isCompleted } }
    var completedTasks: [Task]  { tasks.filter { $0.isCompleted } }

    func tasks(for goalId: Int64) -> [Task] {
        activeTasks.filter { $0.goalId == goalId }
    }

    // MARK: - Timer control

    func startTimer(goalId: Int64, taskId: Int64? = nil, duration: Int) {
        stopTimer(save: true)
        let now = Date()
        activeGoalId          = goalId
        activeTaskId          = taskId
        timerTargetSeconds    = duration
        accumulatedSeconds    = 0
        originalStartDate     = now
        timerStartDate        = now
        currentElapsed        = 0
        startTicker()
    }

    func pauseTimer() {
        guard isTimerRunning, let start = timerStartDate else { return }
        accumulatedSeconds += Date().timeIntervalSince(start)
        currentElapsed = accumulatedSeconds
        timerStartDate = nil
        stopTicker()
    }

    func resumeTimer() {
        guard isTimerPaused else { return }
        timerStartDate = Date()
        startTicker()
    }

    func stopTimer(save: Bool = false) {
        guard isTimerActive else { return }

        if save {
            let totalElapsed: Int
            if let start = timerStartDate {
                totalElapsed = Int(accumulatedSeconds + Date().timeIntervalSince(start))
            } else {
                totalElapsed = Int(accumulatedSeconds)
            }

            if totalElapsed > 0, let goalId = activeGoalId {
                let startTimestamp = Int64((originalStartDate ?? Date()).timeIntervalSince1970)
                let interval = Interval(
                    id: startTimestamp,
                    duration: totalElapsed,
                    note: activeTask?.text,
                    goalId: goalId,
                    timerDuration: timerTargetSeconds
                )
                intervals.insert(interval, at: 0)
                persist()
            }
        }

        clearTimer()
    }

    func extendTimer(by seconds: Int) {
        timerTargetSeconds += seconds
    }

    // MARK: - Goals

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        persist()
    }

    func updateGoal(_ goal: Goal) {
        guard let idx = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[idx] = goal
        persist()
    }

    func deleteGoal(id: Int64) {
        // Don't delete the "no goal" sentinel
        guard id != Goal.noGoal.id else { return }
        goals.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Tasks

    func addTask(_ task: Task) {
        tasks.insert(task, at: 0)
        persist()
    }

    func completeTask(id: Int64) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let t = tasks[idx]
        tasks[idx] = Task(
            id: t.id,
            text: t.text,
            goalId: t.goalId,
            isCompleted: !t.isCompleted,
            completedAt: t.isCompleted ? nil : Int64(Date().timeIntervalSince1970)
        )
        persist()
    }

    func deleteTask(id: Int64) {
        tasks.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Private helpers

    private func clearTimer() {
        stopTicker()
        activeGoalId       = nil
        activeTaskId       = nil
        originalStartDate  = nil
        timerStartDate     = nil
        accumulatedSeconds = 0
        currentElapsed     = 0
        timerTargetSeconds = 0
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard let start = timerStartDate else { return }
        currentElapsed = accumulatedSeconds + Date().timeIntervalSince(start)
    }

    private func persist() {
        dataStore.save(AppData(version: 1, goals: goals, intervals: intervals, tasks: tasks))
    }
}

// MARK: - Formatting

func formatTime(_ totalSeconds: Int) -> String {
    let h = totalSeconds / 3600
    let m = (totalSeconds % 3600) / 60
    let s = totalSeconds % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    return String(format: "%d:%02d", m, s)
}

func formatPreset(_ seconds: Int) -> String {
    if seconds < 3600 { return "\(seconds / 60)m" }
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    return m == 0 ? "\(h)h" : "\(h)h\(m)m"
}
