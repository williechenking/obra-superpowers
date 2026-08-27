import SwiftUI

struct EditTargetsView: View {
    @ObservedObject var store: TrainingStore
    @Environment(\.dismiss) private var dismiss

    @State private var dayNumber: Int
    @State private var reps: Int
    @State private var completedReps: Int
    @State private var cindySets: Int
    @State private var completedCindySets: Int

    init(store: TrainingStore) {
        self.store = store
        _dayNumber = State(initialValue: store.dayNumber)
        _reps = State(initialValue: store.today.targetReps)
        _completedReps = State(initialValue: store.today.completedReps)
        _cindySets = State(initialValue: store.today.targetCindySets)
        _completedCindySets = State(initialValue: store.today.completedCindySets)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("第幾天") {
                    Stepper("第 \(dayNumber) 天", value: $dayNumber, in: 1...9999)
                }

                Section("爬樓梯") {
                    Stepper("目標:\(reps) 趟", value: $reps, in: 0...100)
                    Stepper("已完成:\(completedReps) 趟", value: $completedReps, in: 0...100)
                }

                Section("Cindy") {
                    Stepper("目標:\(cindySets) 組", value: $cindySets, in: 0...20)
                    Stepper("已完成:\(completedCindySets) 組", value: $completedCindySets, in: 0...20)
                }

                Section {
                    Text("這裡是手動校正今天的數字用的(例如第一次設定 App 時同步目前進度)，不會發送 LINE 訊息。明天開啟 App 時,爬樓梯目標會自動 +1。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("編輯今日進度")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.updateToday(
                            dayNumber: dayNumber,
                            targetReps: reps,
                            completedReps: completedReps,
                            targetCindySets: cindySets,
                            completedCindySets: completedCindySets
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
