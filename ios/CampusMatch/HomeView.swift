import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var engagements: [Engagement] = []
    @State private var recommended: [RecommendedCase] = []
    @State private var mine: [CaseSummary] = []
    @State private var showNotifications = false

    var pending: [Engagement] { engagements.filter { $0.status == "PENDING" } }

    var body: some View {
        NavigationStack {
            List {
                if let me = app.me {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                StatTile(title: "隊友評價", value: Fmt.opt(me.stats.avgRating))
                                StatTile(title: "相符度", value: Fmt.opt(me.stats.avgMatch))
                                StatTile(title: "可信度", value: String(format: "%.1f", me.stats.credibility))
                                StatTile(title: "回應率", value: Fmt.pct(me.stats.responseRate))
                                StatTile(title: "完成", value: "\(me.stats.closedCases)")
                            }.frame(minWidth: 520)
                        }.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    } header: { Text("\(me.college)／\(me.department) · \(Labels.degree[me.degree] ?? me.degree)\(me.year)年級") }
                }
                Section("待我回覆") {
                    if pending.isEmpty { Text("目前沒有待回覆的申請或邀請").foregroundStyle(.secondary) }
                    ForEach(pending) { e in
                        VStack(alignment: .leading, spacing: 6) {
                            NavigationLink(destination: CaseDetailView(caseId: e.caseId)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.caseTitle).font(.headline)
                                    Text("\(e.direction == "INVITE" ? "邀請你擔任" : "你申請") \(e.roleName) · 發案方 \(e.ownerName)").font(.caption).foregroundStyle(.secondary)
                                    Text("\(Fmt.hoursLeft(e.dueAt)) 小時內回覆，逾時自動視為放棄").font(.caption).foregroundStyle(.orange)
                                }
                            }
                            HStack {
                                if e.direction == "INVITE" {
                                    Button("接受") { Task { await act(e.id, "accept") } }.buttonStyle(.borderedProminent).controlSize(.small)
                                    Button("拒絕") { Task { await act(e.id, "decline") } }.buttonStyle(.bordered).controlSize(.small)
                                } else {
                                    Button("撤回申請") { Task { await act(e.id, "withdraw") } }.buttonStyle(.bordered).controlSize(.small)
                                }
                            }
                        }
                    }
                }
                Section {
                    if recommended.isEmpty { Text("目前沒有通過閘門的招募中案件；補齊技能檔或可投入時間後再試").foregroundStyle(.secondary) }
                    ForEach(recommended) { r in
                        ScoreCard(title: r.caseTitle, subtitle: "\(Labels.type[r.caseType] ?? r.caseType) · \(r.roleName) · 名額 \(r.filled)/\(r.headcount)", score: r.score, breakdown: r.breakdown, reasons: r.reasons) {
                            NavigationLink(destination: CaseDetailView(caseId: r.caseId)) { Image(systemName: "chevron.right").foregroundStyle(.secondary) }.frame(width: 20)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)).listRowBackground(Color.clear)
                    }
                } header: { Text("推薦給我的案件") } footer: { Text("與發案方看到的推薦用同一組閘門與公式，只是方向相反。") }
                Section("我的案件") {
                    if mine.isEmpty { Text("還沒有參與任何案件").foregroundStyle(.secondary) }
                    ForEach(mine) { c in
                        NavigationLink(destination: CaseDetailView(caseId: c.id)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.title).font(.headline)
                                    Text("\(c.ownerId == app.me?.id ? "我發起" : "我是成員") · \(Labels.type[c.type] ?? c.type) · 名額 \(c.filled)/\(c.headcount)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Pill(text: Labels.status[c.status] ?? c.status, color: statusColor(c.status))
                            }
                        }
                    }
                }
            }
            .navigationTitle("你好，\(app.me?.name ?? "")")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showNotifications = true }) {
                        Image(systemName: app.unread > 0 ? "bell.badge.fill" : "bell").foregroundStyle(app.unread > 0 ? Color.red : Color.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    func load() async {
        await app.reloadMe()
        async let e = app.api.get("/me/engagements", as: [Engagement].self)
        async let r = app.api.get("/me/recommended-cases", as: [RecommendedCase].self)
        async let m = app.api.get("/cases?member=true", as: [CaseSummary].self)
        do { engagements = try await e; recommended = try await r; mine = try await m } catch { app.error = error.localizedDescription }
    }

    func act(_ id: Int, _ what: String) async {
        if await app.run({ _ = try await app.api.post("/engagements/\(id)/\(what)", as: CaseDetail.self) }) { await load() }
    }
}
