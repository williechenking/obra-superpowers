import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var token: String = LineNotifier().channelAccessToken
    @State private var userId: String = LineNotifier().wifeUserId
    @State private var testMessage: String = "這是一則測試訊息 🙂"
    @State private var testResultText: String?
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            Form {
                Section("LINE 官方帳號設定") {
                    SecureField("Channel Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("老婆的 LINE userId", text: $userId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("測試") {
                    TextField("測試訊息內容", text: $testMessage)
                    Button {
                        sendTest()
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("發送測試訊息")
                        }
                    }
                    .disabled(isSending || token.isEmpty || userId.isEmpty)

                    if let testResultText {
                        Text(testResultText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("Token 與 userId 只會存在這台裝置的 Keychain 裡,不會上傳到任何地方,只有按「完成一次」或「發送測試訊息」時才會直接呼叫 LINE 官方 API。")
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
        let notifier = LineNotifier()
        notifier.channelAccessToken = token
        notifier.wifeUserId = userId
    }

    private func sendTest() {
        save()
        isSending = true
        testResultText = nil
        Task {
            let result = await LineNotifier().sendMessage(testMessage)
            isSending = false
            switch result {
            case .success:
                testResultText = "✅ 發送成功"
            case .failure(let error):
                testResultText = "❌ \(error.localizedDescription)"
            }
        }
    }
}
