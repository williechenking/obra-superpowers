import Foundation

enum LineNotifierError: LocalizedError {
    case missingCredentials
    case server(Int, String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "尚未在設定裡填入 Channel Access Token 與老婆的 userId"
        case .server(let code, let message):
            return "LINE 伺服器回應錯誤 (\(code)): \(message)"
        case .network(let error):
            return error.localizedDescription
        }
    }
}

/// Sends a push message to one LINE user via the Messaging API,
/// using a channel access token from a personal LINE Official Account.
/// (LINE Notify was discontinued in March 2025, so this replaces it.)
struct LineNotifier {
    private let tokenKey = "lineChannelAccessToken"
    private let userIdKey = "lineWifeUserId"

    var channelAccessToken: String {
        get { KeychainHelper.load(for: tokenKey) ?? "" }
        nonmutating set { KeychainHelper.save(newValue, for: tokenKey) }
    }

    var wifeUserId: String {
        get { KeychainHelper.load(for: userIdKey) ?? "" }
        nonmutating set { KeychainHelper.save(newValue, for: userIdKey) }
    }

    var hasCredentials: Bool {
        !channelAccessToken.isEmpty && !wifeUserId.isEmpty
    }

    func sendMessage(_ text: String) async -> Result<Void, LineNotifierError> {
        guard hasCredentials else { return .failure(.missingCredentials) }

        var request = URLRequest(url: URL(string: "https://api.line.me/v2/bot/message/push")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(channelAccessToken)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "to": wifeUserId,
            "messages": [["type": "text", "text": text]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.network(URLError(.badServerResponse)))
            }
            if (200...299).contains(httpResponse.statusCode) {
                return .success(())
            } else {
                let message = String(data: data, encoding: .utf8) ?? "未知錯誤"
                return .failure(.server(httpResponse.statusCode, message))
            }
        } catch {
            return .failure(.network(error))
        }
    }
}
