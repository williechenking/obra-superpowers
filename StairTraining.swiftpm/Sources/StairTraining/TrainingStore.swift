import Foundation
import Combine

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

    @Published var me: Person {
        didSet {
            UserDefaults.standard.set(me.rawValue, forKey: personKey)
            Task { await refreshPartner() }
        }
    }

    @Published private(set) var partnerProgress: RemoteProgress?
    @Published private(set) var partnerLastUpdated: Date?
    @Published private(set) var partnerError: String?
    @Published private(set) var isSyncing = false
    @Published private(set) var myPushError: String?

    private var history: [String: DayRecord]
    private let historyKey = "stairTrainingHistory"
    private let dayNumberKey = "stairTrainingDayNumber"
    private let personKey = "stairTrainingPerson"

    let sync = FirebaseSync()

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([String: DayRecord].self, from: data) {
            history = decoded
        } else {
            history = [:]
        }

        if let rawPerson = defaults.string(forKey: personKey), let person = Person(rawValue: rawPerson) {
            me = person
        } else {
            me = .husband
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
        Task { await pushMyProgress() }
    }

    func incrementStair() {
        today.completedReps += 1
        persist()
        Task { await pushMyProgress() }
    }

    func decrementStair() {
        guard today.completedReps > 0 else { return }
        today.completedReps -= 1
        persist()
        Task { await pushMyProgress() }
    }

    func incrementCindy() {
        today.completedCindySets += 1
        persist()
        Task { await pushMyProgress() }
    }

    func decrementCindy() {
        guard today.completedCindySets > 0 else { return }
        today.completedCindySets -= 1
        persist()
        Task { await pushMyProgress() }
    }

    func pushMyProgress() async {
        guard sync.isConfigured else { return }
        isSyncing = true
        defer { isSyncing = false }

        let remote = RemoteProgress(
            dayNumber: dayNumber,
            targetReps: today.targetReps,
            completedReps: today.completedReps,
            targetCindySets: today.targetCindySets,
            completedCindySets: today.completedCindySets,
            updatedAt: Date().timeIntervalSince1970
        )

        let result = await sync.push(remote, for: me)
        switch result {
        case .success:
            myPushError = nil
        case .failure(let error):
            myPushError = error.localizedDescription
        }
    }

    func refreshPartner() async {
        guard sync.isConfigured else { return }
        isSyncing = true
        defer { isSyncing = false }

        let result = await sync.fetch(for: me.partner)
        switch result {
        case .success(let progress):
            partnerProgress = progress
            partnerLastUpdated = Date()
            partnerError = nil
        case .failure(let error):
            partnerError = error.localizedDescription
        }
    }
}
