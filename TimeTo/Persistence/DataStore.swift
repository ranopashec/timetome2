import Foundation

struct AppData: Codable {
    var version: Int = 1
    var goals: [Goal]
    var intervals: [Interval]
    var tasks: [Task]
    // Active timer — optional so old saves decode cleanly
    var activeGoalId: Int64? = nil
    var timerStartDate: Date? = nil
    var timerTargetSeconds: Int = 0

    static let empty = AppData(goals: [], intervals: [], tasks: [])
}

final class DataStore: Sendable {
    static let shared = DataStore()

    let fileURL: URL

    private init() {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("TimeTo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("data.json")
    }

    func load() -> AppData {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(AppData.self, from: data)
        else {
            return .empty
        }
        return decoded
    }

    func save(_ appData: AppData) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(appData) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
