import SwiftUI

/// 全域狀態：登入者、參考資料、錯誤訊息
@MainActor
final class AppState: ObservableObject {
    @Published var me: Me?
    @Published var meta: Meta?
    @Published var error: String?
    @Published var unread = 0
    let api = APIClient.shared

    func bootstrap() async {
        if api.token != nil { await reloadMe() }
        if meta == nil { meta = try? await api.get("/meta", as: Meta.self) }
    }

    func reloadMe() async {
        do { me = try await api.get("/me", as: Me.self); unread = me?.unreadNotifications ?? 0 }
        catch { me = nil }
    }

    func login(account: String, password: String) async -> Bool {
        do {
            let res = try await api.post("/auth/login", LoginBody(account: account, password: password), as: AuthResponse.self)
            api.token = res.token; me = res.user; unread = res.user.unreadNotifications
            if let t = UserDefaults.standard.string(forKey: "deviceToken") {
                _ = try? await api.post("/me/device-tokens", DeviceTokenBody(token: t), as: EmptyResponse.self)
            }
            if meta == nil { meta = try? await api.get("/meta", as: Meta.self) }
            return true
        } catch { self.error = error.localizedDescription; return false }
    }

    func logout() { api.token = nil; me = nil }

    /// 統一處理 API 動作：成功回傳 true，失敗顯示錯誤
    func run(_ work: () async throws -> Void) async -> Bool {
        do { try await work(); return true } catch { self.error = error.localizedDescription; return false }
    }
}
