import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var store = TrainingStore()
    @State private var showSettings = false
    @State private var showEditTargets = false

    private let refreshTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    Text("我的進度(\(store.me.displayName))")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ProgressCard(
                        title: "爬樓梯",
                        subtitle: "每趟:爬 13 層樓梯 + 搭電梯下樓",
                        completed: store.today.completedReps,
                        target: store.today.targetReps,
                        color: .orange,
                        onIncrement: store.incrementStair,
                        onDecrement: store.decrementStair
                    )

                    ProgressCard(
                        title: "Cindy",
                        subtitle: "訓練組數",
                        completed: store.today.completedCindySets,
                        target: store.today.targetCindySets,
                        color: .blue,
                        onIncrement: store.incrementCindy,
                        onDecrement: store.decrementCindy
                    )

                    if let myPushError = store.myPushError {
                        Text("⚠️ 上傳失敗:\(myPushError)")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Divider()

                    partnerSection
                }
                .padding()
            }
            .refreshable {
                await store.refreshPartner()
            }
            .onReceive(refreshTimer) { _ in
                Task { await store.refreshPartner() }
            }
            .task {
                await store.pushMyProgress()
                await store.refreshPartner()
            }
            .navigationTitle("第 \(store.dayNumber) 天訓練")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showEditTargets = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(store: store)
            }
            .sheet(isPresented: $showEditTargets) {
                EditTargetsView(store: store)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date(), style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !store.sync.isConfigured {
                Text("尚未設定 Firebase 同步,請先到「設定」填入")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(store.me.partner.displayName)的進度")
                .font(.headline)

            if let partner = store.partnerProgress {
                PartnerRow(label: "爬樓梯", completed: partner.completedReps, target: partner.targetReps, color: .orange)
                PartnerRow(label: "Cindy", completed: partner.completedCindySets, target: partner.targetCindySets, color: .blue)
                Text("第 \(partner.dayNumber) 天 · 最後更新:\(store.partnerLastUpdated.map(relativeTime) ?? "-")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if store.sync.isConfigured {
                Text("尚未取得對方的資料,下拉可重新整理")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("設定好 Firebase 同步後,這裡會顯示對方的進度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let partnerError = store.partnerError {
                Text("⚠️ \(partnerError)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct PartnerRow: View {
    let label: String
    let completed: Int
    let target: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text("\(completed) / \(target)")
                    .fontWeight(.semibold)
            }
            ProgressView(value: target > 0 ? Double(completed) / Double(target) : 0)
                .tint(color)
        }
    }
}

private struct ProgressCard: View {
    let title: String
    let subtitle: String
    let completed: Int
    let target: Int
    let color: Color
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(title).font(.title2.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            Text("\(completed) / \(target)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            ProgressView(value: target > 0 ? Double(completed) / Double(target) : 0)
                .tint(color)

            HStack(spacing: 16) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(color)
                }
                .disabled(completed <= 0)

                Button(action: onIncrement) {
                    Label("完成一次", systemImage: "checkmark.circle.fill")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ContentView()
}
