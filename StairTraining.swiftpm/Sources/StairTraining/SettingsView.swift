import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: TrainingStore
    @Environment(\.dismiss) private var dismiss

    @State private var baseURL: String
    @State private var roomId: String
    @State private var testResultText: String?
    @State private var isTesting = false

    init(store: TrainingStore) {
        self.store = store
        _baseURL = State(initialValue: store.sync.baseURL)
        _roomId = State(initialValue: store.sync.roomId)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("我是誰") {
                    Picker("身分", selection: $store.me) {
                        ForEach(Person.allCases, id: \.self) { person in
                            Text(person.displayName).tag(person)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Firebase 同步設定") {
                    TextField("Database URL,例如 https://xxx-default-rtdb.firebaseio.com", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField("房間代碼(兩人要輸入一樣的)", text: $roomId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("測試") {
                    Button {
                        testConnection()
                    } label: {
                        if isTesting {
                            ProgressView()
                        } else {
                            Text("測試連線並上傳一次我的進度")
                        }
                    }
                    .disabled(isTesting || baseURL.isEmpty || roomId.isEmpty)

                    if let testResultText {
                        Text(testResultText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("兩支手機都要填『一樣的』Database URL 和房間代碼,但各自選自己的身分(老公 / 老婆)。設定方法請見專案裡的 README。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        save()
                        dismiss()
                    }
                }
            }
        }
    }

    private func save() {
        store.sync.baseURL = baseURL
        store.sync.roomId = roomId
    }

    private func testConnection() {
        save()
        isTesting = true
        testResultText = nil
        Task {
            await store.pushMyProgress()
            await store.refreshPartner()
            isTesting = false
            if let error = store.myPushError {
                testResultText = "❌ 上傳失敗:\(error)"
            } else {
                testResultText = "✅ 已成功上傳我的進度到 Firebase"
            }
        }
    }
}
