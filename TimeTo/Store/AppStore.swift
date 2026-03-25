import Foundation
import Observation
import AppKit

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
    private var overtimeSoundPlayed = false
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

        if let savedGoalId = data.activeGoalId, let savedStart = data.timerStartDate {
            // Restore previous session timer
            activeGoalId       = savedGoalId
            timerStartDate     = savedStart
            timerTargetSeconds = data.timerTargetSeconds
            overtimeSoundPlayed = (data.timerTargetSeconds - Int(Date().timeIntervalSince(savedStart))) < 0
            startTicker()
        } else {
            // No active timer — auto-start no-goal stopwatch
            activeGoalId       = Goal.noGoal.id
            timerStartDate     = Date()
            timerTargetSeconds = 0
            overtimeSoundPlayed = true // already at 0, suppress sound on launch
            startTicker()
            persist()
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
        activeGoalId        = goalId
        timerStartDate      = Date()
        timerTargetSeconds  = duration
        overtimeSoundPlayed = (duration == 0) // if starting at 0, suppress immediate sound
        startTicker()
        persist()
    }

    func extendTimer(by seconds: Int) {
        timerTargetSeconds += seconds
        persist()
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

    // MARK: - Intervals (history editing)

    func addInterval(_ interval: Interval) {
        intervals.removeAll { $0.id == interval.id }
        intervals.append(interval)
        persist()
    }

    func deleteInterval(id: Int64) {
        intervals.removeAll { $0.id == id }
        persist()
    }

    /// Change start time of a saved or currently active interval.
    func updateSegmentStart(oldId: Int64, newDate: Date) {
        if let activeStart = timerStartDate, Int64(activeStart.timeIntervalSince1970) == oldId {
            timerStartDate = newDate
            overtimeSoundPlayed = (timerTargetSeconds - Int(Date().timeIntervalSince(newDate))) <= 0
            persist()
            return
        }

        guard let existing = intervals.first(where: { $0.id == oldId }) else { return }
        let newId = Int64(newDate.timeIntervalSince1970)
        intervals.removeAll { $0.id == oldId }
        intervals.removeAll { $0.id == newId } // avoid duplicates if new time collides
        intervals.append(Interval(id: newId, goalId: existing.goalId))
        persist()
    }

    func exportBackup(to url: URL) throws {
        try dataStore.save(snapshot(), to: url)
    }

    func importBackup(from url: URL) throws {
        let data = try dataStore.load(from: url)
        apply(data)
    }

    // MARK: - Private helpers

    private func logCurrentSegment() {
        guard let goalId = activeGoalId, let start = timerStartDate else { return }
        intervals.insert(Interval(id: Int64(start.timeIntervalSince1970), goalId: goalId), at: 0)
    }

    private func startTicker() {
        stopTicker()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.tick += 1
                // Play sound exactly when crossing into overtime
                if !self.overtimeSoundPlayed && self.remainingSeconds <= 0 {
                    NSSound(named: .init("Tink"))?.play()
                    self.overtimeSoundPlayed = true
                }
            }
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func persist() {
        dataStore.save(snapshot())
    }

    private func snapshot() -> AppData {
        AppData(
            version: 1,
            goals: goals,
            intervals: intervals,
            tasks: tasks,
            activeGoalId: activeGoalId,
            timerStartDate: timerStartDate,
            timerTargetSeconds: timerTargetSeconds
        )
    }

    private func apply(_ data: AppData) {
        stopTicker()

        var importedGoals = data.goals.filter { $0.id != Goal.noGoal.id }
        importedGoals.insert(.noGoal, at: 0)

        goals = importedGoals
        intervals = data.intervals
        tasks = data.tasks

        let hasActiveGoal = data.activeGoalId.flatMap { goalId in
            importedGoals.contains { $0.id == goalId } ? goalId : nil
        }

        if let goalId = hasActiveGoal, let start = data.timerStartDate {
            activeGoalId = goalId
            timerStartDate = start
            timerTargetSeconds = data.timerTargetSeconds
            overtimeSoundPlayed = (timerTargetSeconds - Int(Date().timeIntervalSince(start))) <= 0
        } else {
            activeGoalId = Goal.noGoal.id
            timerStartDate = Date()
            timerTargetSeconds = 0
            overtimeSoundPlayed = true
        }

        startTicker()
        persist()
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
