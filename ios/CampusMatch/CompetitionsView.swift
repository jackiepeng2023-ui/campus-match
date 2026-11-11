import SwiftUI

/// 競賽：競賽 Agent 依 Skill Profile 推薦；進入詳情後可呼叫學生 Agent（互補隊友）、教師 Agent（指導老師），並起草組隊案件（待確認動作）
struct CompetitionsView: View {
    @EnvironmentObject var app: AppState
    @State private var rec: CompetitionRecommendation?
    @State private var all: [Competition] = []
    @State private var tab = 0

    private var open: [Competition] { all.filter { !$0.isClosed } }

    var body: some View {
        NavigationStack {
            List {
                Picker("範圍", selection: $tab) { Text("推薦給我").tag(0); Text("全部競賽").tag(1) }.pickerStyle(.segmented).listRowBackground(Color.clear)
                if tab == 0 { recommended } else { ForEach(open) { c in row(c) } }
            }
            .navigationTitle("競賽")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    @ViewBuilder private var recommended: some View {
        if let r = rec {
            Section {
                if r.recommended.isEmpty { Text("目前沒有符合資格、與你的技能相關且還能報名的競賽。").foregroundStyle(Color.secondary) }
                ForEach(r.recommended) { c in row(c) }
            } header: { Text("競賽 Agent・可報名 \(r.totalEligible) 筆") } footer: { Text("契合度 = 75% 涵蓋率（核心技能權重 2、輔助 1）+ 25% 證據強度。日期與資格以官方公告為準。") }
        } else { ProgressView() }
    }

    private func row(_ c: Competition) -> some View {
        NavigationLink(destination: CompetitionDetailView(id: c.id)) { CompetitionRow(c: c) }
    }

    private func load() async {
        _ = await app.run {
            rec = try await app.api.get("/agents/competitions?limit=10", as: CompetitionRecommendation.self)
            all = try await app.api.get("/competitions", as: [Competition].self)
        }
    }
}

struct CompetitionRow: View {
    let c: Competition
    private var fitColor: Color { c.eligible == false ? Color.secondary : Color.accentColor }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(c.shortName).font(.subheadline.weight(.semibold))
                Spacer()
                if c.fit != nil { Text(c.fitText).font(.headline).foregroundStyle(fitColor) }
            }
            Text(c.metaLine).font(.caption).foregroundStyle(Color.secondary)
            if let g = c.gapText { Text(g).font(.caption).foregroundStyle(Color.red) }
        }
    }
}

struct CompetitionDetailView: View {
    @EnvironmentObject var app: AppState
    let id: Int
    @State private var c: Competition?
    @State private var team: TeammatesResult?
    @State private var teachers: TeachersResult?
    @State private var invitees: Set<Int> = []
    @State private var advisor: Int?
    @State private var action: AssistantAction?
    @State private var busy = false

    var body: some View {
        List {
            if let c = c {
                info(c)
                Section("所需技能") { FlowLayout { ForEach(c.skills) { s in SkillChip(name: s.name, level: s.minLevel, required: s.importance == "CORE", atLeast: true) } } }
                if c.fit != nil {
                    fitSection(c)
                    if !c.isClosed { teamSection; teacherSection; if team != nil { draftSection } }
                }
            } else { ProgressView() }
        }
        .navigationTitle("競賽").navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func info(_ c: Competition) -> some View {
        Section {
            Text(c.name).font(.headline)
            LabeledContent("主辦", value: c.organizer ?? "—")
            LabeledContent("報名", value: c.deadlineText)
            LabeledContent("隊伍", value: c.teamText)
            if let d = c.description, !d.isEmpty { Text(d).font(.caption).foregroundStyle(Color.secondary) }
            if let n = c.eligibilityNote, !n.isEmpty { Text("資格：" + n).font(.caption).foregroundStyle(Color.secondary) }
            if let url = c.link { Link("官方網站", destination: url).font(.caption) }
        } footer: { Text(c.checkedText) }
    }

    private func fitSection(_ c: Competition) -> some View {
        Section("競賽 Agent・我的契合度") {
            LabeledContent("契合度", value: c.fitText)
            ForEach(c.blockedBy ?? [], id: \.self) { b in Text(b).font(.caption).foregroundStyle(Color.red) }
            if let s = c.strengthText { Text(s).font(.caption) }
            if let w = c.weaknessText { Text(w).font(.caption).foregroundStyle(Color.orange) }
            if let g = c.gapText { Text(g).font(.caption).foregroundStyle(Color.red) }
        }
    }

    private var teamSection: some View {
        Section("學生 Agent・互補隊友") {
            if let t = team {
                if let s = t.suggestionText { Text(s).font(.caption) }
                if t.candidates.isEmpty { Text("目前沒有能補上缺口、時間也配合得上的同學。").font(.caption).foregroundStyle(Color.secondary) }
                ForEach(t.candidates) { x in
                    Button { toggle(x.userId) } label: {
                        HStack(alignment: .top) {
                            Image(systemName: invitees.contains(x.userId) ? "checkmark.circle.fill" : "circle").foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(x.headline).foregroundStyle(Color.primary)
                                Text(x.why).font(.caption).foregroundStyle(Color.secondary)
                            }
                            Spacer()
                            Text(Fmt.score(x.score)).font(.subheadline.weight(.semibold)).foregroundStyle(Color.primary)
                        }
                    }
                }
            } else { Button("找技能互補的隊友") { Task { await findTeam() } }.disabled(busy) }
        }
    }

    private var teacherSection: some View {
        Section {
            if let t = teachers {
                if t.teachers.isEmpty { Text("目前沒有專長相符的老師。").font(.caption).foregroundStyle(Color.secondary) }
                ForEach(t.teachers) { x in
                    Button { advisor = (advisor == x.teacherId ? nil : x.teacherId) } label: {
                        HStack(alignment: .top) {
                            Image(systemName: advisor == x.teacherId ? "largecircle.fill.circle" : "circle").foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(x.headline).foregroundStyle(Color.primary)
                                Text(x.why).font(.caption).foregroundStyle(Color.secondary)
                                if let ct = x.confirmText { Text(ct).font(.caption).foregroundStyle(Color.orange) }
                            }
                            Spacer()
                            Text(Fmt.score(x.fit)).font(.subheadline.weight(.semibold)).foregroundStyle(Color.primary)
                        }
                    }
                }
            } else { Button("找指導老師") { Task { await findTeachers() } }.disabled(busy) }
        } header: { Text("教師 Agent・指導老師") } footer: { Text("教師資料來自系所公開網頁；平台不會替你聯絡老師，請自行聯絡並確認。") }
    }

    private var draftSection: some View {
        Section("組隊（待確認動作）") {
            if let a = action {
                ActionCardView(actionId: a.id, title: a.title, status: a.status, payload: a.payload, result: a.result, onChanged: { Task { await refreshAction() } })
            } else {
                Button(invitees.isEmpty ? "起草公開招募的組隊案件" : "用勾選的 \(invitees.count) 位起草組隊案件") { Task { await draft() } }.disabled(busy)
            }
        }
    }

    private func toggle(_ uid: Int) { if invitees.contains(uid) { invitees.remove(uid) } else { invitees.insert(uid) } }

    private func load() async { _ = await app.run { c = try await app.api.get("/competitions/\(id)", as: Competition.self) } }

    private func findTeam() async {
        busy = true
        _ = await app.run { team = try await app.api.post("/agents/teammates", AgentRequest(competitionId: id, limit: 8), as: TeammatesResult.self) }
        invitees = Set((team?.suggestedTeam.picks ?? []).map { $0.userId })
        busy = false
    }

    private func findTeachers() async {
        busy = true
        _ = await app.run { teachers = try await app.api.post("/agents/teachers", AgentRequest(competitionId: id, limit: 5), as: TeachersResult.self) }
        busy = false
    }

    private func draft() async {
        busy = true
        let body = DraftTeamBody(competitionId: id, inviteUserIds: Array(invitees), advisorTeacherId: advisor, hoursPerWeek: nil)
        _ = await app.run { action = try await app.api.post("/assistant/actions/draft-team", body, as: AssistantAction.self) }
        busy = false
    }

    private func refreshAction() async {
        guard let a = action else { return }
        _ = await app.run { action = try await app.api.get("/assistant/actions/\(a.id)", as: AssistantAction.self) }
    }
}
