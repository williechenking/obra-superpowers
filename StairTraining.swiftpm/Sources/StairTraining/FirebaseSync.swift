import Foundation

enum Person: String, Codable, CaseIterable {
    case husband
    case wife

    var displayName: String {
        switch self {
        case .husband: return "老公"
        case .wife: return "老婆"
        }
    }

    var partner: Person {
        switch self {
        case .husband: return .wife
        case .wife: return .husband
        }
    }
}

/// What gets written to / read from Firebase for one person.
struct RemoteProgress: Codable, Equatable {
    var dayNumber: Int
    var targetReps: Int
    var completedReps: Int
    var targetCindySets: Int
    var completedCindySets: Int
    var updatedAt: TimeInterval
}

enum SyncError: LocalizedError {
    case notConfigured
    case server(Int, String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "尚未在設定裡填入 Firebase 網址與房間代碼"
        case .server(let code, let message):
            return "Firebase 回應錯誤 (\(code)): \(message)"
        case .network(let error):
            return error.localizedDescription
        }
    }
}

/// Talks to a Firebase Realtime Database over plain HTTPS (its REST API),
/// so no Firebase SDK dependency is needed. Both phones point at the same
/// database URL + "room" id and each writes under their own role
/// (husband/wife), so the other phone can read it back.
struct FirebaseSync {
    private let baseURLKey = "firebaseBaseURL"
    private let roomKey = "firebaseRoomId"

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: baseURLKey) ?? "" }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    var roomId: String {
        get { UserDefaults.standard.string(forKey: roomKey) ?? "" }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: roomKey) }
    }

    var isConfigured: Bool { !baseURL.isEmpty && !roomId.isEmpty }

    private func url(for person: Person) -> URL? {
        guard isConfigured else { return nil }
        var trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        let encodedRoom = roomId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? roomId
        return URL(string: "\(trimmed)/couples/\(encodedRoom)/\(person.rawValue).json")
    }

    func push(_ progress: RemoteProgress, for person: Person) async -> Result<Void, SyncError> {
        guard let url = url(for: person) else { return .failure(.notConfigured) }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(progress)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.network(URLError(.badServerResponse)))
            }
            if (200...299).contains(http.statusCode) {
                return .success(())
            } else {
                return .failure(.server(http.statusCode, String(data: data, encoding: .utf8) ?? "未知錯誤"))
            }
        } catch {
            return .failure(.network(error))
        }
    }

    func fetch(for person: Person) async -> Result<RemoteProgress?, SyncError> {
        guard let url = url(for: person) else { return .failure(.notConfigured) }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                return .failure(.network(URLError(.badServerResponse)))
            }
            guard (200...299).contains(http.statusCode) else {
                return .failure(.server(http.statusCode, String(data: data, encoding: .utf8) ?? "未知錯誤"))
            }
            if let text = String(data: data, encoding: .utf8), text == "null" {
                return .success(nil)
            }
            let decoded = try JSONDecoder().decode(RemoteProgress.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(.network(error))
        }
    }
}
