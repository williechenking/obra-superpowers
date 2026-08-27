import SwiftUI

struct ContentView: View {
    @StateObject private var store = TrainingStore()
    @State private var showSettings = false
    @State private var showEditTargets = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

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

                    logSection
                }
                .padding()
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
                SettingsView()
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
            Text("按「完成一次」會自動傳 LINE 給老婆")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("發送紀錄")
                .font(.headline)
            if store.recentLogs.isEmpty {
                Text("尚未發送任何訊息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.recentLogs, id: \.self) { log in
                    Text(log)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
