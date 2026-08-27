import Foundation

struct DayRecord: Codable {
    var targetReps: Int
    var completedReps: Int
    var targetCindySets: Int
    var completedCindySets: Int
}

@MainActor
final class TrainingStore: ObservableObject {
    @Published private(set) var today: DayRecord
    @Published private(set) var dayNumber: Int
    @Published private(set) var recentLogs: [String] = []

    private var history: [String: DayRecord]
    private let historyKey = "stairTrainingHistory"
    private let dayNumberKey = "stairTrainingDayNumber"

    let lineNotifier = LineNotifier()

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: DayRecord].self, from: data) {
            history = decoded
        } else {
            history = [:]
        }

        var storedDayNumber = defaults.integer(forKey: dayNumberKey)
        let todayKey = Self.todayKey()

        if let record = history[todayKey] {
            today = record
            dayNumber = storedDayNumber == 0 ? 1 : storedDayNumber
        } else {
            // A new calendar day: roll the stair target forward by 1,
            // keep the Cindy target the same as the most recent day.
            let previousRecord = history.keys.sorted().last.flatMap { history[$0] }
            let newTarget = (previousRecord?.targetReps ?? 0) + 1
            today = DayRecord(
                targetReps: max(newTarget, 1),
                completedReps: 0,
                targetCindySets: previousRecord?.targetCindySets ?? 4,
                completedCindySets: 0
            )
            storedDayNumber = previousRecord == nil ? max(storedDayNumber, 1) : storedDayNumber + 1
            dayNumber = storedDayNumber
            history[todayKey] = today
            defaults.set(dayNumber, forKey: dayNumberKey)
        }

        persist()
    }

    static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    private func persist() {
        history[Self.todayKey()] = today
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// Lets you correct today's numbers (and the day count) to match reality —
    /// handy the first time you set the app up mid-streak.
    func updateToday(dayNumber: Int, targetReps: Int, completedReps: Int, targetCindySets: Int, completedCindySets: Int) {
        self.dayNumber = max(dayNumber, 1)
        today = DayRecord(
            targetReps: max(targetReps, 0),
            completedReps: max(completedReps, 0),
            targetCindySets: max(targetCindySets, 0),
            completedCindySets: max(completedCindySets, 0)
        )
        UserDefaults.standard.set(self.dayNumber, forKey: dayNumberKey)
        persist()
    }

    func incrementStair() {
        today.completedReps += 1
        persist()
        Task { await sendStairUpdate() }
    }

    func decrementStair() {
        guard today.completedReps > 0 else { return }
        today.completedReps -= 1
        persist()
    }

    func incrementCindy() {
        today.completedCindySets += 1
        persist()
        Task { await sendCindyUpdate() }
    }

    func decrementCindy() {
        guard today.completedCindySets > 0 else { return }
        today.completedCindySets -= 1
        persist()
    }

    private func sendStairUpdate() async {
        let done = today.completedReps
        let target = today.targetReps
        let finishedAll = target > 0 && done >= target
        let text = finishedAll
            ? "🏆 第\(dayNumber)天爬樓梯訓練全部完成！共\(done)趟(每趟爬13層樓梯再搭電梯下樓)"
            : "🏃 第\(dayNumber)天爬樓梯進度:已完成第 \(done)/\(target) 趟"
        await send(text)
    }

    private func sendCindyUpdate() async {
        let done = today.completedCindySets
        let target = today.targetCindySets
        let finishedAll = target > 0 && done >= target
        let text = finishedAll
            ? "🏆 第\(dayNumber)天 Cindy 訓練全部完成！共\(done)組"
            : "💪 第\(dayNumber)天 Cindy 訓練進度:已完成第 \(done)/\(target) 組"
        await send(text)
    }

    func sendCustomMessage(_ text: String) async {
        await send(text)
    }

    private func send(_ text: String) async {
        let result = await lineNotifier.sendMessage(text)
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        switch result {
        case .success:
            recentLogs.insert("✅ [\(time)] \(text)", at: 0)
        case .failure(let error):
            recentLogs.insert("❌ [\(time)] 發送失敗:\(error.localizedDescription) — \(text)", at: 0)
        }
        if recentLogs.count > 20 {
            recentLogs.removeLast(recentLogs.count - 20)
        }
    }
}
