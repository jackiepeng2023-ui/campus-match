import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        TabView {
            HomeView().tabItem { Label("首頁", systemImage: "house.fill") }
            CasesView().tabItem { Label("案件", systemImage: "list.bullet.rectangle") }
            GrowthView().tabItem { Label("成長", systemImage: "chart.line.uptrend.xyaxis") }
            ProfileView().tabItem { Label("我的檔案", systemImage: "person.crop.circle") }
        }
    }
}
