import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var app: AppState
    @State private var hours = 8
    @State private var newSkillId = 0
    @State private var newSkillLevel = 3
    @State private var showDelete = false

    var body: some View {
        NavigationStack {
            List {
                if let me = app.me {
                    Section {
                        LabeledContent("學號", value: me.studentNo)
                        LabeledContent("系所", value: "\(me.college)／\(me.department)")
                        LabeledContent("學制", value: "\(Labels.degree[me.degree] ?? me.degree) \(me.year) 年級" + (me.entryYear.map { "（\($0) 學年度入學）" } ?? ""))
                        LabeledContent("預計畢業", value: me.expectedGraduation)
                        NavigationLink("別人看到的我", destination: PublicProfileView(userId: me.id))
                    }
                    Section {
                        Stepper("每週可投入 \(hours) 小時", value: $hours, in: 0...80)
                        Button("儲存可投入時間") { Task { await save(AvailabilityBody(hoursPerWeek: hours, availableFrom: me.availability?.availableFrom ?? "2026-01-01", availableTo: me.availability?.availableTo ?? "2027-06-30"), to: "/me/availability") } }
                    } header: { Text("可投入時間（時間閘門）") } footer: { Text("可用期間 \(me.availability?.availableFrom ?? "—") ～ \(me.availability?.availableTo ?? "—")") }
                    Section {
                        ForEach(me.skills) { s in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(s.name)
                                    Text("\(s.category) · 預設 \(s.defaultLevel.map(String.init) ?? "—") · \(s.source == "GRADE" ? (s.level != s.defaultLevel ? "自評上調" : "成績換算") : "自填")").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Picker("", selection: Binding(get: { s.level }, set: { v in Task { await put("/me/skills", [SkillBody(skillId: s.skillId, level: v)]) } })) {
                                    ForEach(1...5, id: \.self) { Text("\($0) 級").tag($0) }
                                }.labelsHidden().frame(width: 90)
                            }
                        }
                        .onDelete { idx in Task { for i in idx { _ = await app.run { try await app.api.delete("/me/skills/\(me.skills[i].skillId)") } }; await app.reloadMe() } }
                        if let meta = app.meta {
                            HStack {
                                Picker("技能", selection: $newSkillId) { ForEach(meta.skills) { Text("\($0.category)｜\($0.name)").tag($0.id) } }.labelsHidden()
                                Picker("", selection: $newSkillLevel) { ForEach(1...5, id: \.self) { Text("\($0) 級").tag($0) } }.labelsHidden().frame(width: 90)
                                Button("自填") { Task { await put("/me/skills", [SkillBody(skillId: newSkillId, level: newSkillLevel)]) } }.buttonStyle(.bordered).controlSize(.small)
                            }
                        }
                    } header: { Text("技能檔") } footer: { Text("預設等級來自成績；你可以調整，幅度會被記錄，由結案互評的「相符度」檢驗。對外只顯示等級。") }
                    Section {
                        ForEach(me.grades) { g in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) { Text(g.course); if let r = g.requirement { Text(Labels.requirement[r] ?? r).font(.caption2.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2).background(r == "REQUIRED" ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.12)).clipShape(Capsule()) } }
                                    Text("\(g.semester)" + (g.skills.map { " → " + $0 } ?? "") + (g.pendingSkills.map { "（待核准：\($0)）" } ?? "") + ((g.department != nil && g.department != me.department) ? " · \(g.department!)" : "")).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(); Text("\(g.score)").font(.headline).monospacedDigit()
                            }
                        }
                        .onDelete { idx in Task { for i in idx { _ = await app.run { try await app.api.delete("/me/grades/\(me.grades[i].id)") } }; await app.reloadMe() } }
                        NavigationLink { CoursePickerView() } label: {
                            Label(me.grades.isEmpty ? "從科目清單填分數" : "從科目清單新增／修改分數", systemImage: "list.bullet.rectangle")
                        }
                    } header: { Text("修課成績（只有你看得到）") } footer: { Text("科目清單來自學校公告的各系所必修科目表／應修學分表（\(me.entryYear.map { "\($0) 學年度入學" } ?? "依年級推算")）。" + (me.degree == "BACHELOR" ? "學士換算：90→5、80→4、70→3、60→2" : "碩博士換算：90→5、85→4、80→3、70→2")) }
                    Section("得獎紀錄") {
                        if me.awards.isEmpty { Text("尚無得獎紀錄").foregroundStyle(.secondary) }
                        ForEach(me.awards) { a in
                            HStack {
                                VStack(alignment: .leading) { Text(a.competition); Text("\(Labels.level[a.level] ?? a.level)・\(Labels.rank[a.rank] ?? a.rank) · \(a.awardDate)").font(.caption).foregroundStyle(.secondary) }
                                Spacer(); Text("+\(String(format: "%.2f", a.score))").foregroundStyle(Color.accentColor).font(.subheadline.weight(.semibold))
                            }
                        }
                        .onDelete { idx in Task { for i in idx { _ = await app.run { try await app.api.delete("/me/awards/\(me.awards[i].id)") } }; await app.reloadMe() } }
                    }
                    Section {
                        Button("登出") { app.logout() }
                        Button("刪除帳號（立即去識別化並刪除本人資料）", role: .destructive) { showDelete = true }
                    } footer: { Text("畢業 3 個月後去識別化、6 個月後刪除本人資料；去識別化的案件與評價紀錄保留供統計。") }
                }
            }
            .navigationTitle("我的檔案")
            .onAppear { hours = app.me?.availability?.hoursPerWeek ?? 8; if newSkillId == 0 { newSkillId = app.meta?.skills.first?.id ?? 0 } }
            .refreshable { await app.reloadMe() }
            .confirmationDialog("確定刪除帳號？", isPresented: $showDelete, titleVisibility: .visible) {
                Button("刪除", role: .destructive) { Task { if await app.run({ try await app.api.delete("/me") }) { app.logout() } } }
                Button("取消", role: .cancel) {}
            }
        }
    }

    func put(_ path: String, _ body: Encodable) async {
        if await app.run({ app.me = try await app.api.put(path, body, as: Me.self) }) {}
    }
    func save(_ body: Encodable, to path: String) async { await put(path, body) }
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
                Section { FlowLayout { ForEach(u.skills) { s in SkillChip(name: s.name, level: s.level) } } } header: { Text("技能等級") } footer: { Text("只顯示等級，不顯示成績。") }
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
