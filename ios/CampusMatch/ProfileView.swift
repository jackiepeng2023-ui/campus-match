import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @State private var hours = 8
    @State private var showDelete = false
    @State private var showEvidence = false
    @State private var showGrowth = false
    @State private var expanded: Set<Int> = []

    var body: some View {
        NavigationStack {
            List {
                if let me = app.me {
                    basics(me)
                    skillSection(me)
                    credentialSection(me)
                    gradeSection(me)
                    awardSection(me)
                    availabilitySection(me)
                    consentSection(me)
                    accountSection
                }
            }
            .navigationTitle("我的檔案")
            .onAppear { hours = app.me?.availability?.hoursPerWeek ?? 8 }
            .refreshable { await app.reloadMe() }
            .sheet(isPresented: $showEvidence) { AddEvidenceView().environmentObject(app) }
            .sheet(isPresented: $showGrowth) { GrowthView().environmentObject(app) }
            .confirmationDialog("確定刪除帳號？", isPresented: $showDelete, titleVisibility: .visible) {
                Button("刪除", role: .destructive) { Task { if await app.run({ try await app.api.delete("/me") }) { app.logout() } } }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func basics(_ me: Me) -> some View {
        Section {
            LabeledContent("學號", value: me.studentNo)
            LabeledContent("系所", value: me.college + "／" + me.department)
            LabeledContent("學制", value: me.degreeLine)
            LabeledContent("預計畢業", value: me.expectedGraduation)
            NavigationLink("別人看到的我", destination: PublicProfileView(userId: me.id))
            Button { showGrowth = true } label: { Label("成長儀表板與知識圖譜", systemImage: "chart.line.uptrend.xyaxis") }
        }
    }

    // Skill Profile：能力盤點模組的輸出（技能／等級／證據），三個媒合 Agent 共用
    private func skillSection(_ me: Me) -> some View {
        Section {
            if me.skills.isEmpty { Text("還沒有任何證據。先填修課成績，或新增證照、作品集。").foregroundStyle(Color.secondary) }
            ForEach(me.skills) { s in
                VStack(alignment: .leading, spacing: 6) {
                    Button { toggle(s.skillId) } label: { SkillRow(skill: s) }.buttonStyle(.plain)
                    if expanded.contains(s.skillId) { ForEach(s.evidence ?? []) { e in EvidenceRow(evidence: e) } }
                }
            }
        } header: { Text("Skill Profile") } footer: { Text(me.skillFooter) }
    }

    private func credentialSection(_ me: Me) -> some View {
        Section {
            ForEach(me.credentials) { c in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title)
                        Text(c.subtitle).font(.caption).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Text("\(c.score)").monospacedDigit()
                    TrustBadge(label: c.trustLabel)
                }
            }
            .onDelete { idx in remove(idx.map { "/me/credentials/\(me.credentials[$0].id)" }) }
            Button { showEvidence = true } label: { Label("新增證照、作品集或自我評估", systemImage: "plus.circle") }
        } header: { Text("證照、作品集、自我評估") } footer: { Text("自己填的先標示「自述」；附上證明連結，管理員審核後變成「已驗證」。每筆最多對應 \(app.meta?.maxSkillsPerEvidence ?? 5) 個技能。") }
    }

    private func gradeSection(_ me: Me) -> some View {
        Section {
            ForEach(me.grades) { g in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(g.course)
                            if let r = g.requirement { Pill(text: Labels.requirement[r] ?? r, color: r == "REQUIRED" ? Color.accentColor : Color.secondary) }
                        }
                        Text(g.subtitle(myDepartment: me.department)).font(.caption).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    Text("\(g.score)").font(.headline).monospacedDigit()
                }
            }
            .onDelete { idx in remove(idx.map { "/me/grades/\(me.grades[$0].id)" }) }
            NavigationLink { CoursePickerView() } label: { Label(me.grades.isEmpty ? "從科目清單填分數" : "從科目清單新增／修改分數", systemImage: "list.bullet.rectangle") }
        } header: { Text("修課成績（只有你看得到）") } footer: { Text(me.gradeFooter) }
    }

    private func awardSection(_ me: Me) -> some View {
        Section("得獎紀錄") {
            if me.awards.isEmpty { Text("尚無得獎紀錄").foregroundStyle(Color.secondary) }
            ForEach(me.awards) { a in
                HStack {
                    VStack(alignment: .leading) {
                        Text(a.competition)
                        Text(a.subtitle).font(.caption).foregroundStyle(Color.secondary)
                    }
                    Spacer()
                    TrustBadge(label: a.trustLabel)
                }
            }
            .onDelete { idx in remove(idx.map { "/me/awards/\(me.awards[$0].id)" }) }
        }
    }

    private func availabilitySection(_ me: Me) -> some View {
        Section {
            Stepper("每週可投入 \(hours) 小時", value: $hours, in: 0...80)
            Button("儲存可投入時間") { Task { await saveAvailability(me) } }
        } header: { Text("可投入時間（時間閘門）") } footer: { Text(me.availabilityFooter) }
    }

    private func consentSection(_ me: Me) -> some View {
        Section {
            Toggle("同意使用 AI 助理", isOn: Binding(get: { me.aiConsent }, set: { v in Task { await setConsent(v) } }))
        } header: { Text("AI 助理的資料使用") } footer: {
            Text("同意後，你輸入給 AI 助理的訊息與技能檔（學制、系所、各技能的階級與可信狀態；不含姓名、學號、Email、原始成績與技能分數）會傳送到外部語言模型服務（Anthropic Claude API，由境外的服務商處理），其他學生以代號表示。未同意時 AI 助理以規則模式運作，不傳送任何資料。")
        }
    }

    private var accountSection: some View {
        Section {
            Button("登出") { app.logout() }
            Button("刪除帳號（立即去識別化並刪除本人資料）", role: .destructive) { showDelete = true }
        } footer: { Text("畢業 3 個月後去識別化、6 個月後刪除本人資料（含證據與 AI 助理對話）；去識別化的案件與評價紀錄保留供統計。") }
    }

    private func toggle(_ id: Int) { if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) } }

    private func remove(_ paths: [String]) {
        Task {
            for p in paths { _ = await app.run { try await app.api.delete(p) } }
            await app.reloadMe()
        }
    }

    private func saveAvailability(_ me: Me) async {
        let body = AvailabilityBody(hoursPerWeek: hours, availableFrom: me.availability?.availableFrom ?? "2026-01-01", availableTo: me.availability?.availableTo ?? "2027-06-30")
        _ = await app.run { app.me = try await app.api.put("/me/availability", body, as: Me.self) }
    }

    private func setConsent(_ agree: Bool) async {
        _ = await app.run { _ = try await app.api.post("/me/consents/ai", ConsentBody(agree: agree), as: EmptyResponse.self) }
        await app.reloadMe()
    }
}

private struct SkillRow: View {
    let skill: UserSkill
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name).foregroundStyle(Color.primary)
                Text(skill.subtitle).font(.caption).foregroundStyle(Color.secondary)
            }
            Spacer()
            Text("\(skill.score)").font(.headline).monospacedDigit().foregroundStyle(Color.primary)
            Text(skill.tier).font(.caption.weight(.bold)).foregroundStyle(Color.accentColor)
            TrustBadge(label: skill.trustLabel)
        }
    }
}

private struct EvidenceRow: View {
    let evidence: Evidence
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(evidence.typeLabel).font(.caption2.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2).background(Color(.systemFill)).clipShape(Capsule())
            VStack(alignment: .leading) {
                Text(evidence.headline).font(.caption)
                if !evidence.subline.isEmpty { Text(evidence.subline).font(.caption2).foregroundStyle(Color.secondary) }
            }
            Spacer()
            TrustBadge(label: evidence.trustLabel)
        }
    }
}

/// 新增證據：證照（對照表或自填）、作品集、自我評估；每筆從 Skill 資料庫選 1–N 個技能
struct AddEvidenceView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var type = "CERTIFICATE"
    @State private var catalogId = 0
    @State private var title = ""
    @State private var tier = 2
    @State private var proofUrl = ""
    @State private var skillIds: Set<Int> = []

    private var maxSkills: Int { type == "SELF" ? 1 : (app.meta?.maxSkillsPerEvidence ?? 5) }
    private var fromCatalog: Bool { type == "CERTIFICATE" && catalogId != 0 }
    private var titleOK: Bool { type == "SELF" || !title.trimmingCharacters(in: .whitespaces).isEmpty }
    private var valid: Bool { fromCatalog || (!skillIds.isEmpty && skillIds.count <= maxSkills && titleOK) }
    private var catalog: [CatalogCertificate] { app.meta?.certificateCatalog ?? [] }
    private var allSkills: [MetaSkill] { app.meta?.skills ?? [] }

    var body: some View {
        NavigationStack {
            Form {
                Picker("類型", selection: $type) { Text("證照").tag("CERTIFICATE"); Text("作品集").tag("PORTFOLIO"); Text("自我評估").tag("SELF") }.pickerStyle(.segmented)
                if type == "CERTIFICATE" { catalogSection }
                if !fromCatalog { manualSections }
                if type != "SELF" { proofSection }
            }
            .navigationTitle("新增證據").navigationBarTitleDisplayMode(.inline)
            .onChange(of: type) { _, _ in skillIds = []; catalogId = 0 }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("新增") { Task { await save() } }.disabled(!valid) }
            }
        }
    }

    private var catalogSection: some View {
        Section {
            Picker("證照對照表", selection: $catalogId) {
                Text("不在對照表內（自行填寫）").tag(0)
                ForEach(catalog) { c in Text(c.optionLabel).tag(c.id) }
            }
        } footer: { Text(fromCatalog ? "對照表內的證照：技能與分數由對照表決定。" : "對照表沒有的證照可以自行填寫名稱與對應技能。") }
    }

    @ViewBuilder private var manualSections: some View {
        if type != "SELF" { Section { TextField(type == "CERTIFICATE" ? "證照名稱" : "作品名稱", text: $title) } }
        Section {
            Picker("我認為達到", selection: $tier) { ForEach(1...3, id: \.self) { t in Text(Labels.tierName(t)).tag(t) } }
        } footer: { Text("以該階的代表分數計入，並標示為「自述」。") }
        Section("對應技能（\(skillIds.count)／\(maxSkills)）") {
            ForEach(allSkills) { s in
                Button { toggle(s.id) } label: {
                    HStack {
                        Text(s.optionLabel).foregroundStyle(Color.primary)
                        Spacer()
                        if skillIds.contains(s.id) { Image(systemName: "checkmark").foregroundStyle(Color.accentColor) }
                    }
                }
            }
        }
    }

    private var proofSection: some View {
        Section {
            TextField("證明連結（選填，https://…）", text: $proofUrl).keyboardType(.URL).textInputAutocapitalization(.never)
        } footer: { Text("附上連結後，管理員審核通過即變成「已驗證」。") }
    }

    private func toggle(_ id: Int) {
        if skillIds.contains(id) { skillIds.remove(id) } else if skillIds.count < maxSkills { skillIds.insert(id) }
    }

    private func save() async {
        var ok = false
        if type == "SELF" {
            let body = skillIds.map { SkillBody(skillId: $0, level: tier) }
            ok = await app.run { app.me = try await app.api.put("/me/skills", body, as: Me.self) }
        } else {
            let body = CredentialBody(type: type, title: fromCatalog ? nil : title, issuer: nil, obtainedOn: nil, catalogId: fromCatalog ? catalogId : nil,
                                      tier: fromCatalog ? nil : tier, proofUrl: proofUrl.isEmpty ? nil : proofUrl, skillIds: Array(skillIds))
            ok = await app.run { app.me = try await app.api.post("/me/credentials", body, as: Me.self) }
        }
        if ok { dismiss() }
    }
}

struct PublicProfileView: View {
    @EnvironmentObject var app: AppState
    let userId: Int
    @State private var u: PublicProfile?
    var body: some View {
        List {
            if let u = u {
                Section {
                    Text(u.name).font(.title2.weight(.bold))
                    Text("\(u.college)／\(u.department) · \(Labels.degree[u.degree] ?? u.degree)\(u.year)年級 · 每週可投入 \(u.availability?.hoursPerWeek ?? 0) 小時").font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatTile(title: "隊友評價", value: Fmt.opt(u.stats.avgRating))
                            StatTile(title: "相符度", value: Fmt.opt(u.stats.avgMatch))
                            StatTile(title: "可信度", value: String(format: "%.1f", u.stats.credibility))
                            StatTile(title: "回應率", value: Fmt.pct(u.stats.responseRate))
                            StatTile(title: "完成", value: "\(u.stats.closedCases)")
                        }.frame(minWidth: 520)
                    }.listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                Section { FlowLayout { ForEach(u.skills) { s in SkillChip(name: s.name, level: s.level, trust: s.trustLabel) } } } header: { Text("技能") } footer: { Text("只顯示階級與可信狀態，不顯示分數與成績。") }
                Section("得獎紀錄") {
                    if u.awards.isEmpty { Text("無").foregroundStyle(.secondary) }
                    ForEach(u.awards) { a in VStack(alignment: .leading) { Text(a.competition); Text("\(Labels.level[a.level] ?? a.level)・\(Labels.rank[a.rank] ?? a.rank) · \(a.awardDate)").font(.caption).foregroundStyle(.secondary) } }
                }
            } else { ProgressView() }
        }
        .navigationTitle("公開檔案").navigationBarTitleDisplayMode(.inline)
        .task { u = try? await app.api.get("/users/\(userId)", as: PublicProfile.self) }
    }
}
