import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        TabView {
            HomeView().tabItem { Label("首頁", systemImage: "house.fill") }
            AssistantView().tabItem { Label("AI 助理", systemImage: "sparkles") }
            CompetitionsView().tabItem { Label("競賽", systemImage: "trophy") }
            CasesView().tabItem { Label("案件", systemImage: "list.bullet.rectangle") }
            ProfileView().tabItem { Label("我的檔案", systemImage: "person.crop.circle") }
        }
    }
}
