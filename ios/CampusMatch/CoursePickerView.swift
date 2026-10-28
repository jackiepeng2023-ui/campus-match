import SwiftUI

/// 從正式科目表點選科目、填入分數：系所（預設本系）× 學制 × 入學學年度 → 必修／選修／校共同·通識／搜尋全校
struct CoursePickerView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var departmentId = 0
    @State private var degree = "BACHELOR"
    @State private var entryYear: Int? = nil
    @State private var options: CourseOptions? = nil
    @State private var tab = "REQUIRED"
    @State private var query = ""
    @State private var courses: [Course] = []
    @State private var scores: [Int: String] = [:]          // courseId → 輸入中的分數
    @State private var pickedSkill: [Int: Int] = [:]        // courseId → 自填技能
    @State private var loading = false
    @State private var saving = false
    private let tabs = [("REQUIRED", "必修"), ("ELECTIVE", "選修"), ("GENERAL", "通識"), ("SEARCH", "搜尋")]

    var changed: [Course] {
        courses.filter { c in
            guard let t = scores[c.id], let v = Int(t), (0...100).contains(v) else { return false }
            return v != c.myScore || pickedSkill[c.id] != nil
        }
    }

    var body: some View {
        List {
            if let meta = app.meta {
                Section {
                    Picker("系所", selection: $departmentId) { ForEach(meta.departments) { Text("\($0.college)／\($0.name)").tag($0.id) } }
                    Picker("學制", selection: $degree) { ForEach(["BACHELOR", "MASTER", "PHD"], id: \.self) { Text(Labels.degree[$0] ?? $0).tag($0) } }
                    if let o = options, !o.years.isEmpty {
                        Picker("入學學年度", selection: Binding(get: { entryYear ?? o.nearestYear ?? o.years[0] }, set: { entryYear = $0; Task { await reload() } })) { ForEach(o.years, id: \.self) { Text("\($0) 學年度").tag($0) } }
                        if let mine = app.me?.entryYear, !o.years.contains(mine), departmentId == app.me?.departmentId {
                            Text("你的入學學年度 \(mine) 尚無科目表，顯示最接近的 \(o.nearestYear ?? 0) 學年度").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if options != nil {
                        Text("這個系所／學制尚無科目表，可用「搜尋」找科目").font(.caption).foregroundStyle(.secondary)
                    }
                    Picker("", selection: $tab) { ForEach(tabs, id: \.0) { Text($0.1).tag($0.0) } }.pickerStyle(.segmented).labelsHidden()
                    if tab == "SEARCH" {
                        HStack { TextField("科目名稱或課程編碼（全校四個年度）", text: $query).onSubmit { Task { await reload() } }; Button("搜尋") { Task { await reload() } }.buttonStyle(.bordered).controlSize(.small) }
                    }
                } footer: { Text("科目清單來自學校公告的各系所必修科目表／應修學分表；分數只有你本人可見，學期會依入學年度與科目年級自動推算。") }
                Section {
                    if loading { ProgressView() }
                    else if courses.isEmpty { Text(tab == "SEARCH" ? "輸入關鍵字後搜尋" : "此年度沒有這類科目").foregroundStyle(.secondary) }
                    ForEach(courses) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(c.name)
                                        Text(Labels.requirement[c.requirement] ?? c.requirement).font(.caption2.weight(.semibold)).padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(c.requirement == "REQUIRED" ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.12)).clipShape(Capsule())
                                    }
                                    Text(meta1(c)).font(.caption).foregroundStyle(.secondary)
                                    if let s = c.skills { Text("→ " + s).font(.caption).foregroundStyle(.secondary) }
                                    if let p = c.pendingSkills { Text("待核准：" + p).font(.caption).foregroundStyle(.tertiary) }
                                }
                                Spacer()
                                TextField("分數", text: Binding(get: { scores[c.id] ?? c.myScore.map(String.init) ?? "" }, set: { scores[c.id] = $0 }))
                                    .keyboardType(.numberPad).multilineTextAlignment(.center).frame(width: 64).textFieldStyle(.roundedBorder)
                            }
                            if c.skills == nil {
                                Picker("這門課對應的技能", selection: Binding(get: { pickedSkill[c.id] ?? 0 }, set: { pickedSkill[c.id] = $0 == 0 ? nil : $0 })) {
                                    Text("尚無對照，自填技能…").tag(0)
                                    ForEach(meta.skills) { Text("\($0.category)｜\($0.name)").tag($0.id) }
                                }.font(.caption).labelsHidden()
                            }
                        }
                    }
                } header: { Text(tab == "SEARCH" ? "搜尋結果" : "\(entryYear ?? options?.nearestYear ?? 0) 學年度 \(tabs.first { $0.0 == tab }?.1 ?? "")") }
            }
        }
        .navigationTitle("科目清單")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "儲存中…" : "儲存 \(changed.count) 筆") { Task { await save() } }.disabled(changed.isEmpty || saving)
            }
        }
        .onChange(of: departmentId) { _, _ in Task { await reloadOptions() } }
        .onChange(of: degree) { _, _ in Task { await reloadOptions() } }
        .onChange(of: tab) { _, _ in Task { await reload() } }
        .task {
            if app.meta == nil { app.meta = try? await app.api.get("/meta", as: Meta.self) }
            if departmentId == 0, let me = app.me { departmentId = me.departmentId; degree = me.degree }
            await reloadOptions()
        }
    }

    private func meta1(_ c: Course) -> String {
        var parts: [String] = []
        if let gy = c.gradeYear { parts.append("\(gy) 年級" + (c.term.map { " 第 \($0) 學期" } ?? "")) }
        if let cr = c.credits { parts.append("\(cr.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(cr)) : String(cr)) 學分") }
        if let code = c.code { parts.append(code) }
        if tab == "SEARCH" { parts.append("\(c.department ?? "校共同／通識") · \(c.entryYear ?? 0) 學年度 · \(Labels.degree[c.degree ?? ""] ?? "")") }
        if let g = c.groupCode { parts.append("（\(g)）") }
        return parts.joined(separator: " · ")
    }

    private func reloadOptions() async {
        guard departmentId > 0 else { return }
        options = try? await app.api.get("/courses/options?departmentId=\(departmentId)&degree=\(degree)", as: CourseOptions.self)
        entryYear = options?.nearestYear
        await reload()
    }

    private func reload() async {
        loading = true; defer { loading = false }
        scores = [:]; pickedSkill = [:]
        do {
            if tab == "SEARCH" {
                let q = query.trimmingCharacters(in: .whitespaces)
                courses = q.isEmpty ? [] : try await app.api.get("/courses?q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q)", as: [Course].self)
            } else if let y = entryYear ?? options?.nearestYear {
                courses = try await app.api.get("/courses?departmentId=\(departmentId)&degree=\(degree)&entryYear=\(y)&requirement=\(tab)", as: [Course].self)
            } else { courses = [] }
        } catch { app.error = error.localizedDescription; courses = [] }
    }

    private func save() async {
        saving = true; defer { saving = false }
        let body = changed.map { c in GradeBody(courseId: c.id, score: Int(scores[c.id] ?? "") ?? 0, semester: nil, skillIds: pickedSkill[c.id].map { [$0] } ?? []) }
        let ok = await app.run { _ = try await app.api.put("/me/grades", body, as: Me.self) }
        if ok { await app.reloadMe(); await reload() }
    }
}
