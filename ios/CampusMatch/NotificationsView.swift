import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) var dismiss
    @State private var items: [NotificationItem] = []
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty { Text("沒有通知").foregroundStyle(.secondary) }
                ForEach(items) { n in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack { Text(n.title).font(.headline); Spacer(); Text(Fmt.time(n.createdAt)).font(.caption).foregroundStyle(.secondary) }
                        Text(n.body).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .listRowBackground(n.readAt == nil ? Color.accentColor.opacity(0.08) : nil)
                }
            }
            .navigationTitle("通知")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("關閉") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("全部已讀") { Task { _ = await app.run { _ = try await app.api.post("/me/notifications/read-all", as: EmptyResponse.self) }; app.unread = 0; await load() } } }
            }
            .task { await load() }
        }
    }
    func load() async {
        if let r = try? await app.api.get("/me/notifications", as: NotificationList.self) { items = r.items; app.unread = r.unread }
    }
}
