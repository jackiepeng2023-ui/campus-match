import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// REST 客戶端：與網頁共用同一套 /api/v1；token 存在 UserDefaults（Demo 用，正式版改 Keychain）
final class APIClient {
    static let shared = APIClient()
    private let defaults = UserDefaults.standard

    var baseURL: String {
        get { defaults.string(forKey: "apiBase") ?? "http://localhost:8080" }
        set { defaults.set(newValue, forKey: "apiBase") }
    }
    var token: String? {
        get { defaults.string(forKey: "token") }
        set { defaults.set(newValue, forKey: "token") }
    }

    struct RequestError: LocalizedError {
        let status: Int; let code: String; let message: String; let reasons: [String]
        var errorDescription: String? { reasons.isEmpty ? message : message + "：" + reasons.joined(separator: "；") }
    }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func request<T: Decodable>(_ method: String, _ path: String, body: Encodable? = nil, as type: T.Type) async throws -> T {
        let data = try await raw(method, path, body: body)
        if T.self == EmptyResponse.self { return EmptyResponse() as! T }
        do { return try decoder.decode(T.self, from: data) }
        catch { throw RequestError(status: 200, code: "DECODE", message: "資料格式解析失敗：\(error)", reasons: []) }
    }

    @discardableResult
    func raw(_ method: String, _ path: String, body: Encodable? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + "/api/v1" + path) else { throw RequestError(status: 0, code: "URL", message: "API 網址無效", reasons: []) }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer " + t, forHTTPHeaderField: "Authorization") }
        if let body = body { req.httpBody = try encoder.encode(AnyEncodable(body)) }
        let (data, response) = try await URLSession.shared.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status >= 400 {
            let err = try? decoder.decode(APIError.self, from: data)
            if status == 401 && !path.hasPrefix("/auth/") { token = nil; NotificationCenter.default.post(name: .sessionExpired, object: nil) }
            throw RequestError(status: status, code: err?.code ?? "HTTP_\(status)", message: err?.message ?? "HTTP \(status)", reasons: err?.reasons ?? [])
        }
        return data
    }

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T { try await request("GET", path, as: type) }
    func post<T: Decodable>(_ path: String, _ body: Encodable? = EmptyBody(), as type: T.Type) async throws -> T { try await request("POST", path, body: body, as: type) }
    func put<T: Decodable>(_ path: String, _ body: Encodable, as type: T.Type) async throws -> T { try await request("PUT", path, body: body, as: type) }
    func delete(_ path: String) async throws { _ = try await raw("DELETE", path) }
}

struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable { init() {} }

/// 讓任何 Encodable 都能被 JSONEncoder 編碼
struct AnyEncodable: Encodable {
    private let encodeFn: (Encoder) throws -> Void
    init(_ value: Encodable) { encodeFn = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFn(encoder) }
}

extension Notification.Name { static let sessionExpired = Notification.Name("sessionExpired") }

// 請求 body
struct LoginBody: Encodable { let account: String; let password: String }
struct EngagementBody: Encodable { let direction: String; let userId: Int?; let message: String }
struct CloseBody: Encodable { let result: String }
struct VoteBody: Encodable { let agree: Bool }
struct PromptBody: Encodable { let goal: String; let question: String }
struct SkillBody: Encodable { let skillId: Int; let level: Int }
struct GradeBody: Encodable { let courseId: Int; let score: Int; let semester: String?; let skillIds: [Int] }
struct AvailabilityBody: Encodable { let hoursPerWeek: Int; let availableFrom: String; let availableTo: String }
struct DeviceTokenBody: Encodable { let token: String }
struct AwardBody: Encodable { let competition: String; let level: String; let rank: String; let awardDate: String; let skillIds: [Int] }
