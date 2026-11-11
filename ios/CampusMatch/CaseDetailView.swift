import SwiftUI

struct CaseDetailView: View {
    @EnvironmentObject var app: AppState
    let caseId: Int
    @State private var c: CaseDetail?
    @State private var recs: [Int: RecommendationResponse] = [:]
    @State private var showClose = false

    var body: some View {
        Group {
            if let c = c { content(c) } else { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .navigationTitle(c?.title ?? "案件").navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    func myEngagement(_ c: CaseDetail, _ roleId: Int) -> MyEngagement? {
        c.myEngagements.first { $0.roleId == roleId && ($0.status == "PENDING" || $0.status == "ACCEPTED") } ?? c.myEngagements.first { $0.roleId == roleId }
    }

    @ViewBuilder
    func content(_ c: CaseDetail) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Pill(text: Labels.status[c.status] ?? c.status, color: statusColor(c.status))
                        Pill(text: Labels.type[c.type] ?? c.type)
                        if let a = c.attribution { Pill(text: "成果歸屬：" + (Labels.attribution[a] ?? a), color: .purple) }
                    }
                    Text(c.title).font(.title2.weight(.bold))
                    Text("發案方 \(c.ownerName)（\(c.ownerCollege)／\(c.ownerDepartment)） · 每隊 \(c.teamSize) 人").font(.caption).foregroundStyle(.secondary)
                    Text("申請截止 \(Fmt.time(c.applyDeadline)) · 期間 \(c.startDate) ～ \(c.endDate)").font(.caption).foregroundStyle(.secondary)
                    if !c.description.isEmpty { Text(c.description).font(.subheadline).padding(.top, 4) }
                }
            }
            if c.isOwner { ownerActions(c) }
            if let cr = c.closeRequest, cr.status == "OPEN" { closeVoting(c, cr) }
            if c.status == "CLOSED" {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("已結案（\(c.closeResult == "COMPLETED" ? "完成" : "未完成")）").font(.headline)
                            Text("雙盲互評：雙方都送出或 72 小時到期才同時公開").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if c.pendingReviews > 0 { NavigationLink("完成互評（\(c.pendingReviews)）", destination: ReviewView(caseId: c.id)).buttonStyle(.borderedProminent).controlSize(.small) }
                        else if c.isMember { Pill(text: "你已完成互評", color: .green) }
                    }
                }
            }
            ForEach(c.roles) { r in roleSection(c, r) }
            Section("成員（\(c.members.count)/\(c.teamSize)）") {
                ForEach(c.members) { m in
                    HStack {
                        NavigationLink(destination: PublicProfileView(userId: m.userId)) {
                            VStack(alignment: .leading) { Text(m.name); Text("\(m.college)／\(m.department)").font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Pill(text: m.isOwner ? "發案方" : (m.roleName ?? "成員"), color: m.isOwner ? .blue : .secondary)
                    }
                }
            }
            if c.isOwner, let engs = c.engagements { engagementsSection(engs) }
        }
        .confirmationDialog("提出結案（成員 72 小時內過半確認，未回應視為同意）", isPresented: $showClose, titleVisibility: .visible) {
            Button("完成結案") { Task { await post("/cases/\(c.id)/close-requests", CloseBody(result: "COMPLETED")) } }
            Button("未完成（中途解散）", role: .destructive) { Task { await post("/cases/\(c.id)/close-requests", CloseBody(result: "INCOMPLETE")) } }
            Button("取消", role: .cancel) {}
        }
    }

    @ViewBuilder
    func ownerActions(_ c: CaseDetail) -> some View {
        Section("發案方操作") {
            if c.status == "DRAFT" { Button("發布案件") { Task { await post("/cases/\(c.id)/publish") } } }
            if c.status == "FORMED" { Button("開始執行") { Task { await post("/cases/\(c.id)/start") } } }
            if c.status == "FORMED" || c.status == "IN_PROGRESS" { Button("提出結案") { showClose = true } }
            if ["DRAFT", "OPEN", "FORMED"].contains(c.status) { Button("取消案件", role: .destructive) { Task { await post("/cases/\(c.id)/cancel") } } }
        }
    }

    @ViewBuilder
    func closeVoting(_ c: CaseDetail, _ cr: CloseRequest) -> some View {
        Section("結案確認中") {
            Text("發案方提出「\(cr.result == "COMPLETED" ? "完成" : "未完成")」結案，期限 \(Fmt.time(cr.dueAt))；已投票 \(cr.votes.count) 人").font(.subheadline)
            if c.isMember && !c.isOwner && cr.myVote == nil {
                HStack {
                    Button("同意結案") { Task { await post("/close-requests/\(cr.id)/votes", VoteBody(agree: true)) } }.buttonStyle(.borderedProminent)
                    Button("不同意") { Task { await post("/close-requests/\(cr.id)/votes", VoteBody(agree: false)) } }.buttonStyle(.bordered)
                }
            } else if let v = cr.myVote { Text("你已投票：\(v.agree ? "同意" : "不同意")").font(.caption).foregroundStyle(.secondary) }
        }
    }

    @ViewBuilder
    func roleSection(_ c: CaseDetail, _ r: CaseRole) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(r.roleName).font(.headline)
                        Text("名額 \(r.filledCount)/\(r.headcount) · 每週 \(r.hoursPerWeek) 小時" + (c.isOwner ? " · 可邀請 \(r.invitable)" : "")).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !c.isOwner && c.status == "OPEN" {
                        if let e = myEngagement(c, r.id) { Pill(text: "\(e.direction == "INVITE" ? "邀請" : "申請")：\(Labels.eng[e.status] ?? e.status)", color: statusColor(e.status)) }
                        else if !c.isMember && r.filledCount < r.headcount {
                            Button("申請") { Task { await apply(r.id) } }.buttonStyle(.borderedProminent).controlSize(.small)
                        }
                    }
                }
                FlowLayout { ForEach(r.skills) { s in SkillChip(name: s.name, level: s.minLevel, required: s.isRequired, atLeast: true) } }
                if let e = myEngagement(c, r.id), e.status == "PENDING" {
                    HStack {
                        Text("\(Fmt.hoursLeft(e.dueAt)) 小時內需回覆").font(.caption).foregroundStyle(.orange)
                        Spacer()
                        if e.direction == "INVITE" {
                            Button("接受邀請") { Task { await post("/engagements/\(e.id)/accept") } }.buttonStyle(.borderedProminent).controlSize(.small)
                            Button("拒絕") { Task { await post("/engagements/\(e.id)/decline") } }.buttonStyle(.bordered).controlSize(.small)
                        } else {
                            Button("撤回申請") { Task { await post("/engagements/\(e.id)/withdraw") } }.buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                }
                if c.isOwner && c.status == "OPEN" {
                    Button(recs[r.id] == nil ? "查看推薦人選" : "重新整理推薦") { Task { await loadRec(r.id) } }.buttonStyle(.bordered).controlSize(.small)
                }
            }
            if let rec = recs[r.id] {
                if rec.recommended.isEmpty { Text("沒有人通過閘門").foregroundStyle(.secondary) }
                ForEach(rec.recommended) { p in
                    ScoreCard(title: p.name, subtitle: "\(p.college) \(p.dept) · \(Labels.degree[p.degree] ?? "")\(p.year)年級", score: p.score, breakdown: p.breakdown, reasons: p.reasons) {
                        Button("邀請") { Task { await invite(r.id, p.userId) } }.buttonStyle(.borderedProminent).controlSize(.small).disabled(rec.role.invitable <= 0)
                    }.listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)).listRowBackground(Color.clear)
                }
                if !rec.blocked.isEmpty {
                    DisclosureGroup("技能符合但被閘門擋下的 \(rec.blocked.count) 人") {
                        ForEach(rec.blocked) { p in
                            ScoreCard(title: p.name, subtitle: "\(p.college) \(p.dept)", score: p.score, breakdown: p.breakdown, reasons: p.reasons, blockedBy: p.blockedBy) { EmptyView() }
                        }
                    }
                }
            }
        } header: { Text("角色：\(r.roleName)") }
    }

    @ViewBuilder
    func engagementsSection(_ engs: [CaseEngagement]) -> some View {
        Section("申請與邀請") {
            if engs.isEmpty { Text("還沒有申請或邀請").foregroundStyle(.secondary) }
            ForEach(engs) { e in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(e.name).font(.headline)
                            Text("\(e.direction == "APPLY" ? "申請" : "你邀請") \(e.roleName) · \(e.department) · 分數 \(Fmt.opt(e.score))").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Pill(text: Labels.eng[e.status] ?? e.status, color: statusColor(e.status))
                    }
                    if e.status == "PENDING" {
                        HStack {
                            Text("\(Fmt.hoursLeft(e.dueAt)) 小時後逾時").font(.caption).foregroundStyle(.orange)
                            Spacer()
                            if e.direction == "APPLY" {
                                Button("核准") { Task { await post("/engagements/\(e.id)/accept") } }.buttonStyle(.borderedProminent).controlSize(.small)
                                Button("拒絕") { Task { await post("/engagements/\(e.id)/decline") } }.buttonStyle(.bordered).controlSize(.small)
                            } else {
                                Button("撤回邀請") { Task { await post("/engagements/\(e.id)/withdraw") } }.buttonStyle(.bordered).controlSize(.small)
                            }
                        }
                    }
                }
            }
        }
    }

    func load() async {
        do { c = try await app.api.get("/cases/\(caseId)", as: CaseDetail.self) } catch { app.error = error.localizedDescription }
    }
    func loadRec(_ roleId: Int) async {
        if await app.run({ recs[roleId] = try await app.api.get("/roles/\(roleId)/recommendations", as: RecommendationResponse.self) }) {}
    }
    func post(_ path: String, _ body: Encodable = EmptyBody()) async {
        if await app.run({ _ = try await app.api.post(path, body, as: CaseDetail.self) }) { await load() }
    }
    func apply(_ roleId: Int) async {
        if await app.run({ _ = try await app.api.post("/roles/\(roleId)/engagements", EngagementBody(direction: "APPLY", userId: nil, message: ""), as: EngagementCreated.self) }) { await load() }
    }
    func invite(_ roleId: Int, _ userId: Int) async {
        if await app.run({ _ = try await app.api.post("/roles/\(roleId)/engagements", EngagementBody(direction: "INVITE", userId: userId, message: ""), as: EngagementCreated.self) }) { await load(); await loadRec(roleId) }
    }
}
