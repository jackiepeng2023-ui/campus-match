import SwiftUI
import UserNotifications

@main
struct CampusMatchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if app.me != nil { RootTabView() } else { LoginView() }
            }
            .environmentObject(app)
            .task { await app.bootstrap() }
            .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in app.me = nil }
            .alert("錯誤", isPresented: Binding(get: { app.error != nil }, set: { if !$0 { app.error = nil } })) {
                Button("好", role: .cancel) {}
            } message: { Text(app.error ?? "") }
        }
    }
}

/// APNs（D44）：取得推播權限後，把 device token 註冊到後端
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { DispatchQueue.main.async { application.registerForRemoteNotifications() } }
        }
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: "deviceToken")
        Task { try? await APIClient.shared.post("/me/device-tokens", DeviceTokenBody(token: token), as: EmptyResponse.self) }
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 註冊失敗：\(error.localizedDescription)")
    }
    // App 在前景時也顯示橫幅
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
