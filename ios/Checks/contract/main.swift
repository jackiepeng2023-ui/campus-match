import Foundation

// CampusMatch iOS 契約測試
// 用 App 自己的 APIClient.swift 與 Models.swift（原封不動）對「執行中的後端」跑一遍 iOS 會用到的 API：
//   1. 每個請求的 body 由 App 的 Encodable 型別編碼；
//   2. 每個回應都要能解成 App 的 Decodable 型別（少一個必要欄位、型別不符就失敗）；
//   3. 顯示用文字（Models.swift 的 extension）要組得出來；AI 助理的卡片要能依 type 轉成具名型別。
// 這個程式只用 Foundation，Linux 上就能編譯執行（見 ../contract.sh）。它驗證「資料層」，不驗證 SwiftUI 畫面。
// 需要示範資料（APP_SEED_MODE=demo）；會寫入資料（新增證據、建立案件、送出邀請），請對可重置的環境執行。

struct Expect: Error, CustomStringConvertible { let description: String; init(_ d: String) { description = d } }
func expect(_ cond: @autoclosure () -> Bool, _ message: @autoclosure () -> String) throws { if !cond() { throw Expect(message()) } }

var passed = 0
var failures: [String] = []
@MainActor func step(_ name: String, _ body: () async throws -> String) async {
    do { let note = try await body(); passed += 1; print("  ok  " + name + (note.isEmpty ? "" : "  →  " + note)) }
    catch { failures.append(name); print("FAIL  " + name + "：\(error)") }
}

let api = APIClient.shared
api.baseURL = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "http://localhost:8080"
api.token = nil
let password = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "demo1234"

@MainActor func login(_ n: Int) async throws -> Me {
    api.token = nil
    let auth = try await api.post("/auth/login", LoginBody(account: String(format: "student%03d@example.edu", n), password: password), as: AuthResponse.self)
    api.token = auth.token
    return auth.user
}
/// 示範學生的帳號是 student001…050；以使用者編號找到並登入那位學生
@MainActor func loginUser(_ id: Int) async throws -> Me {
    for n in [id] + Array(1...50) { if let u = try? await login(n), u.id == id { return u } }
    throw Expect("找不到使用者編號 \(id) 的示範帳號")
}
func isISODate(_ s: String?) -> Bool { guard let s = s else { return true }; return s.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil }
func strict<T: Decodable>(_ v: JSONValue, _ type: T.Type) throws -> T { try JSONDecoder().decode(type, from: try JSONEncoder().encode(v)) }

/// Skill Profile 的每一列都要有畫面需要的文字
func checkProfile(_ me: Me) throws {
    try expect(Labels.bands(me.levelBands).contains("初階"), "levelBands 組不出等級說明：\(me.levelBands)")
    for s in me.skills {
        try expect((1...3).contains(s.level) || s.level == 0, "level 超出 0–3：\(s.name) \(s.level)")
        try expect((0...100).contains(s.score), "score 超出 0–100：\(s.name) \(s.score)")
        try expect(["已驗證", "修課成績", "自述"].contains(s.trustLabel), "未知的可信狀態：\(s.trustLabel)")
        guard let ev = s.evidence else { throw Expect("本人的技能缺少 evidence：\(s.name)") }
        try expect(ev.count == s.evidenceCount && !ev.isEmpty, "evidenceCount 與 evidence 筆數不符：\(s.name)")
        for e in ev { try expect(!e.headline.isEmpty && !e.typeLabel.isEmpty && isISODate(e.occurredOn), "證據欄位不完整：\(e)") }
    }
    for c in me.credentials { try expect(!c.subtitle.isEmpty && isISODate(c.obtainedOn), "證照／作品欄位不完整：\(c)") }
    for g in me.grades { try expect(!g.subtitle(myDepartment: me.department).isEmpty, "成績欄位不完整：\(g)") }
    for a in me.awards { try expect(!a.subtitle.isEmpty && isISODate(a.awardDate), "得獎欄位不完整：\(a)") }
    _ = (me.degreeLine, me.skillFooter, me.gradeFooter, me.availabilityFooter)
}
func checkCompetition(_ c: Competition, evaluated: Bool) throws {
    try expect(isISODate(c.applyDeadline) && isISODate(c.eventDate) && isISODate(c.checkedAt), "競賽日期不是 ISO 字串：\(c.shortName) \(c.applyDeadline ?? "") \(c.checkedAt ?? "")")
    try expect(["OPEN", "CLOSED", "UNKNOWN"].contains(c.status), "未知的競賽狀態 \(c.status)")
    try expect(!c.metaLine.isEmpty && !c.teamText.isEmpty && !c.checkedText.isEmpty && !c.skills.isEmpty, "競賽顯示文字不完整：\(c.shortName)")
    if evaluated {
        try expect(c.fit != nil && c.eligible != nil && c.reasons != nil && c.strengths != nil && c.weaknesses != nil && c.gaps != nil && c.blockedBy != nil, "競賽 Agent 的評估欄位不完整：\(c.shortName)")
        _ = (c.strengthText, c.weaknessText, c.gapText, c.coreText, c.fitText)
    }
}
func checkTeam(_ t: TeammatesResult) throws {
    for c in t.candidates { try expect(!c.headline.isEmpty && !c.complementReasons.isEmpty, "隊友候選人缺少互補原因：\(c.name)") }
    for p in t.suggestedTeam.picks { try expect(!p.fills.isEmpty && !p.text.isEmpty, "建議組合缺少補位技能：\(p.name)") }
    _ = (t.gapText, t.suggestionText)
}
func checkTeachers(_ t: TeachersResult) throws {
    for x in t.teachers { try expect(!x.headline.isEmpty && !x.reasons.isEmpty && !x.toConfirm.isEmpty, "教師推薦缺少理由或待確認條件：\(x.name)") }
}
func checkPayload(_ p: ActionPayload) throws {
    try expect(isISODate(p.applyDeadline) && isISODate(p.startDate) && isISODate(p.endDate) && !p.roles.isEmpty && p.teamSize == p.roles.count + 1, "動作草稿不完整：\(p)")
    for r in p.roles { try expect(!r.text.isEmpty, "角色文字為空") }
    _ = (p.summary, p.advisorText)
}
/// 對話卡片：依 type 轉成具名型別（與 AssistantCard 的 switch 相同），回傳卡片類型
func checkCards(_ m: AssistantMessage) throws -> [String] {
    var kinds: [String] = []
    for card in m.cardList {
        let type = card["type"].str ?? "?"
        switch type {
        case "profile": let p = try strict(card, ProfileCard.self); try expect(!p.top.isEmpty && !p.title.isEmpty, "能力盤點卡片是空的")
        case "competitions": let r = try strict(card, CompetitionRecommendation.self); for c in r.recommended + r.blocked { try checkCompetition(c, evaluated: true) }
        case "competition": try checkCompetition(try strict(card, Competition.self), evaluated: true)
        case "competition_list": for c in try strict(card, CompetitionListCard.self).items { try checkCompetition(c, evaluated: false) }
        case "teammates": try checkTeam(try strict(card, TeammatesResult.self))
        case "teachers": try checkTeachers(try strict(card, TeachersResult.self))
        case "action": let a = try strict(card, ActionCard.self); try checkPayload(a.payload); try expect(!ActionStatus.label(a.status).isEmpty, "動作狀態為空")
        default: throw Expect("App 不認得的卡片類型：\(type)")
        }
        try expect(card.decode(JSONValue.self) != nil, "卡片無法重新編碼")
        kinds.append(type)
    }
    return kinds
}
/// 與 AssistantView.send 相同的輪詢；回傳最後一則，並檢查執行中的每個快照都解得開
@MainActor func ask(_ text: String, session: Int?) async throws -> (AssistantMessage, Int, Int) {
    let p = try await api.post("/assistant/messages", MessageBody(sessionId: session, text: text), as: AssistantPosted.self)
    var snapshots = 0
    for _ in 0..<600 {
        let m = try await api.get("/assistant/messages/\(p.assistantMessageId)", as: AssistantMessage.self)
        snapshots += 1
        _ = (m.modeLabel, m.meterText, m.progressText, m.stepList.map { $0.title })
        _ = try checkCards(m)
        if !m.running { return (m, p.sessionId, snapshots) }
        try await Task.sleep(nanoseconds: 150_000_000)
    }
    throw Expect("助理超過 90 秒沒有完成")
}

print("CampusMatch iOS 契約測試  →  " + api.baseURL)

// ---------- 參考資料 ----------
var meta: Meta!
await step("GET /meta → Meta") {
    meta = try await api.get("/meta", as: Meta.self)
    try expect(meta.skills.count >= 50 && !(meta.certificateCatalog ?? []).isEmpty && (meta.levelBands ?? []).count >= 3 && meta.maxSkillsPerEvidence == 5, "參考資料不完整")
    return "\(meta.skills.count) 技能、\(meta.certificateCatalog?.count ?? 0) 證照、等級 \(Labels.bands(meta.levelBands ?? []))"
}
guard meta != nil else { print("後端沒有回應，停止。"); exit(2) }

// ---------- 全部示範學生：/me、成長、競賽推薦 ----------
var graduate: Int?
var noConsent: Int?
await step("50 位示範學生：/auth/login → AuthResponse、/me → Me、/me/growth → Growth、/agents/competitions → CompetitionRecommendation") {
    var skills = 0, evidence = 0, recommended = 0
    for n in 1...50 {
        _ = try await login(n)
        let me = try await api.get("/me", as: Me.self)
        try checkProfile(me)
        if me.degree != "BACHELOR", graduate == nil { graduate = n }
        if !me.aiConsent, noConsent == nil { noConsent = n }
        skills += me.skills.count; evidence += me.skills.reduce(0) { $0 + $1.evidenceCount }
        let g = try await api.get("/me/growth", as: Growth.self)
        try expect(g.radar.allSatisfy { (0...100).contains($0.avgScore) && (0...100).contains($0.maxScore) }, "雷達圖分數超出 0–100")
        let r = try await api.get("/agents/competitions?limit=10", as: CompetitionRecommendation.self)
        for c in r.recommended + r.blocked { try checkCompetition(c, evaluated: true) }
        recommended += r.recommended.count
    }
    return "\(skills) 項技能、\(evidence) 筆證據、\(recommended) 筆競賽推薦；研究生樣本 student\(graduate ?? 0)、未同意 AI 樣本 student\(noConsent ?? 0)"
}

// ---------- 個人檔案、首頁、案件 ----------
var me = try await login(7)
await step("GET /users/{id} → PublicProfile（對外只有階級與可信狀態）") {
    let mine = try await api.get("/users/\(me.id)", as: PublicProfile.self)
    let other = try await api.get("/users/\(me.id == 1 ? 2 : 1)", as: PublicProfile.self)
    try expect(mine.skills.allSatisfy { !$0.tier.isEmpty && !$0.trustLabel.isEmpty }, "公開檔案的技能缺少階級或可信狀態")
    return "\(mine.name) \(mine.skills.count) 項、\(other.name) \(other.skills.count) 項"
}
await step("首頁：/me/engagements → [Engagement]、/me/recommended-cases → [RecommendedCase]、/cases?member=true → [CaseSummary]") {
    let e = try await api.get("/me/engagements", as: [Engagement].self)
    let r = try await api.get("/me/recommended-cases", as: [RecommendedCase].self)
    let m = try await api.get("/cases?member=true", as: [CaseSummary].self)
    try expect(r.allSatisfy { $0.skills.allSatisfy { (1...3).contains($0.minLevel) } }, "案件技能門檻不是三階")
    return "\(e.count) 筆申請邀請、\(r.count) 筆推薦案件、\(m.count) 筆參與中"
}
var caseIds: [Int] = []
await step("案件列表：/cases（全部／mine／member／type／q）→ [CaseSummary]") {
    var total = 0
    for q in ["", "?mine=true", "?member=true", "?type=COMPETITION", "?q=" + ("設計".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")] {
        let l = try await api.get("/cases" + q, as: [CaseSummary].self)
        total += l.count
        for c in l where !caseIds.contains(c.id) { caseIds.append(c.id) }
    }
    try expect(!caseIds.isEmpty, "沒有任何案件")
    return "\(caseIds.count) 個不同案件（共 \(total) 列）"
}
await step("案件詳情：/cases/{id} → CaseDetail；發案方 /roles/{id}/recommendations → RecommendationResponse；/cases/{id}/reviews/pending → PendingReviews") {
    var statuses: [String: Int] = [:], recs = 0, reviews = 0
    for n in [7, 1, 2, 3] {
        _ = try await login(n)
        let mine = try await api.get("/cases?mine=true", as: [CaseSummary].self).map { $0.id }
        let member = try await api.get("/cases?member=true", as: [CaseSummary].self).map { $0.id }
        for id in Array(Set(caseIds.prefix(25) + mine + member)).sorted() {
            let c = try await api.get("/cases/\(id)", as: CaseDetail.self)
            statuses[c.status, default: 0] += 1
            try expect(c.roles.allSatisfy { $0.skills.allSatisfy { (1...3).contains($0.minLevel) } }, "角色技能門檻不是三階：\(c.title)")
            if c.isOwner, c.status == "OPEN", let role = c.roles.first {
                let r = try await api.get("/roles/\(role.id)/recommendations", as: RecommendationResponse.self)
                try expect(r.recommended.allSatisfy { !$0.reasons.isEmpty }, "推薦名單缺少理由")
                recs += 1
            }
            if c.pendingReviews > 0 { _ = try await api.get("/cases/\(id)/reviews/pending", as: PendingReviews.self); reviews += 1 }
        }
    }
    return statuses.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: "、") + "；推薦名單 \(recs) 次、待評價 \(reviews) 次"
}
me = try await login(7)
await step("通知：/me/notifications → NotificationList、POST /me/notifications/read-all") {
    let n = try await api.get("/me/notifications", as: NotificationList.self)
    _ = try await api.post("/me/notifications/read-all", as: EmptyResponse.self)
    let after = try await api.get("/me/notifications", as: NotificationList.self)
    try expect(after.unread == 0, "全部已讀後仍有未讀")
    return "\(n.items.count) 則（原未讀 \(n.unread)）"
}
await step("成長：/me/growth/graph → GraphData、POST /me/growth-prompt → PromptResponse、GET /me/growth/obsidian（zip）") {
    let g = try await api.get("/me/growth/graph", as: GraphData.self)
    try expect(!g.nodes.isEmpty && !g.edges.isEmpty, "知識圖譜是空的")
    let types = Set(g.nodes.map { $0.type }).sorted().joined(separator: "／")
    let p = try await api.post("/me/growth-prompt", PromptBody(goal: "成為前端工程師", question: "下學期該補什麼？"), as: PromptResponse.self)
    let zip = try await api.raw("GET", "/me/growth/obsidian")
    try expect(!p.prompt.isEmpty && zip.count > 1000 && zip.prefix(2) == Data([0x50, 0x4B]), "Prompt 或 Obsidian 匯出異常")
    return "\(g.nodes.count) 節點（\(types)）、\(g.edges.count) 連線、zip \(zip.count / 1024) KB"
}

// ---------- 科目與證據（寫入） ----------
await step("科目：/courses/options → CourseOptions、/courses（必修／選修／通識／搜尋）→ [Course]、PUT /me/grades [GradeBody] → Me") {
    let o = try await api.get("/courses/options?departmentId=\(me.departmentId)&degree=\(me.degree)", as: CourseOptions.self)
    guard let year = o.entryYear ?? o.nearestYear ?? o.years.last else { throw Expect("這個系所沒有任何科目表年度") }
    var counts: [String] = [], target: Course?
    for tab in ["REQUIRED", "ELECTIVE", "GENERAL"] {
        let l = try await api.get("/courses?departmentId=\(me.departmentId)&degree=\(me.degree)&entryYear=\(year)&requirement=\(tab)", as: [Course].self)
        counts.append("\(Labels.requirement[tab] ?? tab) \(l.count)")
        if target == nil { target = l.first { $0.myScore == nil && $0.skills != nil } }
    }
    let q = "程式".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let found = try await api.get("/courses?q=\(q)", as: [Course].self)
    guard let c = target else { throw Expect("找不到還沒填分數、且有技能對照的科目") }
    let before = me.grades.count
    _ = try await api.put("/me/grades", [GradeBody(courseId: c.id, score: 88, semester: nil, skillIds: [])], as: Me.self)
    me = try await api.get("/me", as: Me.self)
    try expect(me.grades.count == before + 1 && me.grades.contains { $0.courseId == c.id && $0.score == 88 }, "成績沒有寫入")
    try checkProfile(me)
    return "\(year) 學年度：" + counts.joined(separator: "、") + "、搜尋 \(found.count)；新增「\(c.name)」88 分"
}
await step("證據：PUT /me/skills [SkillBody]、POST /me/credentials CredentialBody（對照表、自填作品集）、DELETE、PUT /me/availability → Me") {
    guard let cert = meta.certificateCatalog?.first, let s1 = meta.skills.first, let s2 = meta.skills.dropFirst().first else { throw Expect("參考資料不足") }
    let have = Set(me.skills.map { $0.skillId })
    guard let free = meta.skills.first(where: { !have.contains($0.id) }) else { throw Expect("沒有可自評的新技能") }
    me = try await api.put("/me/skills", [SkillBody(skillId: free.id, level: 2)], as: Me.self)
    guard let selfSkill = me.skills.first(where: { $0.skillId == free.id }) else { throw Expect("自我評估沒有出現在 Skill Profile") }
    try expect(selfSkill.trustLabel == "自述" && selfSkill.tier == "中階", "自我評估應為「中階・自述」，實際 \(selfSkill.tier)・\(selfSkill.trustLabel)")
    let n0 = me.credentials.count
    me = try await api.post("/me/credentials", CredentialBody(type: "CERTIFICATE", title: nil, issuer: nil, obtainedOn: nil, catalogId: cert.id, tier: nil, proofUrl: nil, skillIds: []), as: Me.self)
    me = try await api.post("/me/credentials", CredentialBody(type: "PORTFOLIO", title: "契約測試作品", issuer: nil, obtainedOn: nil, catalogId: nil, tier: 3, proofUrl: "https://example.edu/portfolio", skillIds: [s1.id, s2.id]), as: Me.self)
    try expect(me.credentials.count == n0 + 2, "證照／作品沒有寫入")
    guard let mine = me.credentials.first(where: { $0.title == "契約測試作品" }) else { throw Expect("找不到剛新增的作品集") }
    try expect(!mine.verified && mine.trustLabel == "自述", "自填作品集應標示為自述")
    try await api.delete("/me/credentials/\(mine.id)")
    me = try await api.put("/me/availability", AvailabilityBody(hoursPerWeek: 10, availableFrom: me.availability?.availableFrom ?? "2026-01-01", availableTo: me.availability?.availableTo ?? "2027-06-30"), as: Me.self)
    try expect(me.credentials.count == n0 + 1 && me.availability?.hoursPerWeek == 10, "刪除或可投入時間沒有生效")
    try checkProfile(me)
    return "自評「\(free.name)」中階・自述；對照表證照「\(cert.name)」；作品集新增後刪除"
}

// ---------- 競賽頁：三個 Agent 與待確認動作 ----------
var teamCaseId: Int?
await step("競賽：/competitions → [Competition]、/competitions/{id} → Competition") {
    let all = try await api.get("/competitions", as: [Competition].self)
    for c in all { try checkCompetition(c, evaluated: false) }
    for c in all.prefix(8) { try checkCompetition(try await api.get("/competitions/\(c.id)", as: Competition.self), evaluated: true) }
    return "\(all.count) 筆，其中 \(all.filter { !$0.isClosed }.count) 筆未截止"
}
await step("競賽頁流程：POST /agents/teammates → TeammatesResult、/agents/teachers → TeachersResult、draft-team → AssistantAction、confirm → CaseDetail") {
    let rec = try await api.get("/agents/competitions?limit=10", as: CompetitionRecommendation.self)
    guard let c = rec.recommended.first(where: { ($0.teamMax ?? 1) > 1 }) ?? rec.recommended.first else { throw Expect("沒有可報名的推薦競賽") }
    let team = try await api.post("/agents/teammates", AgentRequest(competitionId: c.id, limit: 8), as: TeammatesResult.self)
    try checkTeam(team)
    let teachers = try await api.post("/agents/teachers", AgentRequest(competitionId: c.id, limit: 5), as: TeachersResult.self)
    try checkTeachers(teachers)
    let invitees = team.suggestedTeam.picks.map { $0.userId }
    var a = try await api.post("/assistant/actions/draft-team", DraftTeamBody(competitionId: c.id, inviteUserIds: invitees, advisorTeacherId: teachers.teachers.first?.teacherId, hoursPerWeek: nil), as: AssistantAction.self)
    try expect(a.status == "PENDING" && a.result == nil, "草稿應為待確認")
    try checkPayload(a.payload)
    a = try await api.get("/assistant/actions/\(a.id)", as: AssistantAction.self)
    a = try await api.post("/assistant/actions/\(a.id)/confirm", as: AssistantAction.self)
    try expect(a.status == "DONE", "確認後應為已執行，實際 \(a.status)：\(a.result?.error ?? "")")
    guard let cid = a.result?.caseId else { throw Expect("確認後沒有回傳案件編號") }
    teamCaseId = cid
    let detail = try await api.get("/cases/\(cid)", as: CaseDetail.self)
    try expect(detail.isOwner && detail.status == "OPEN", "案件應已發布")
    return "「\(c.shortName)」缺口 \(team.gaps.count)、候選 \(team.candidates.count)、教師 \(teachers.teachers.count)；案件 #\(cid) " + (a.result?.invitedText ?? "未邀請") + (a.result?.failedText.map { "；" + $0 } ?? "")
}
await step("取消：draft-team → cancel → AssistantAction（沒有任何變動）；重複確認 → 409") {
    let rec = try await api.get("/agents/competitions?limit=10", as: CompetitionRecommendation.self)
    guard let c = rec.recommended.last else { throw Expect("沒有推薦競賽") }
    let before = try await api.get("/cases?mine=true", as: [CaseSummary].self).count
    var a = try await api.post("/assistant/actions/draft-team", DraftTeamBody(competitionId: c.id, inviteUserIds: [], advisorTeacherId: nil, hoursPerWeek: nil), as: AssistantAction.self)
    a = try await api.post("/assistant/actions/\(a.id)/cancel", as: AssistantAction.self)
    try expect(a.status == "CANCELLED", "取消後狀態應為 CANCELLED")
    var conflict = false
    do { _ = try await api.post("/assistant/actions/\(a.id)/confirm", as: AssistantAction.self) } catch let e as APIClient.RequestError { conflict = e.status == 409 }
    let after = try await api.get("/cases?mine=true", as: [CaseSummary].self).count
    try expect(conflict && after == before, "取消後不應能確認，也不應建立案件")
    return ActionStatus.label(a.status)
}
if let cid = teamCaseId {
    await step("案件生命週期：接受邀請 → 撤回 → /roles/{id}/recommendations → 邀請（EngagementCreated）→ 開始 → 結案申請 → 投票 → 互評（PendingReviews）→ 結案證據") {
        var owner = try await login(7)
        var c = try await api.get("/cases/\(cid)", as: CaseDetail.self)
        var invites = (c.engagements ?? []).filter { $0.status == "PENDING" && $0.direction == "INVITE" }
        guard let first = invites.first else { throw Expect("案件沒有待回覆的邀請") }
        // 第一位受邀者接受（首頁的「接受邀請」）
        _ = try await loginUser(first.userId)
        guard let mineE = try await api.get("/me/engagements", as: [Engagement].self).first(where: { $0.id == first.id }) else { throw Expect("受邀者看不到邀請") }
        c = try await api.post("/engagements/\(mineE.id)/accept", as: CaseDetail.self)
        try expect(c.isMember && c.members.contains { $0.userId == first.userId }, "接受邀請後應成為成員")
        invites.removeFirst()
        // 其餘邀請由發案方撤回，改從推薦名單邀請
        var invitedByList = 0
        owner = try await login(7)
        for e in invites { c = try await api.post("/engagements/\(e.id)/withdraw", as: CaseDetail.self) }
        c = try await api.get("/cases/\(cid)", as: CaseDetail.self)
        for role in c.roles where role.filledCount < role.headcount {
            _ = try await login(7)
            let rec = try await api.get("/roles/\(role.id)/recommendations", as: RecommendationResponse.self)
            try expect(rec.recommended.allSatisfy { !$0.reasons.isEmpty && $0.blockedBy.isEmpty } && rec.blocked.allSatisfy { !$0.blockedBy.isEmpty }, "推薦名單的理由或閘門欄位不完整")
            guard let pick = rec.recommended.first(where: { x in !c.members.contains { $0.userId == x.userId } }) else { throw Expect("角色「\(role.roleName)」沒有可邀請的人選") }
            let created = try await api.post("/roles/\(role.id)/engagements", EngagementBody(direction: "INVITE", userId: pick.userId, message: ""), as: EngagementCreated.self)
            try expect(created.status == "PENDING" && !created.reasons.isEmpty, "邀請應為待回覆並附推薦理由")
            _ = try await loginUser(pick.userId)
            c = try await api.post("/engagements/\(created.id)/accept", as: CaseDetail.self)
            invitedByList += 1
        }
        try expect(c.status == "FORMED", "名額補滿後應為已成案，實際 \(c.status)")
        // 發案方：開始執行、提出結案
        owner = try await login(7)
        c = try await api.post("/cases/\(cid)/start", as: CaseDetail.self)
        try expect(c.status == "IN_PROGRESS", "開始後應為執行中")
        c = try await api.post("/cases/\(cid)/close-requests", CloseBody(result: "COMPLETED"), as: CaseDetail.self)
        guard let cr = c.closeRequest else { throw Expect("提出結案後應有結案申請") }
        let memberIds = c.members.map { $0.userId }
        for uid in memberIds where uid != owner.id {
            _ = try await loginUser(uid)
            c = try await api.post("/close-requests/\(cr.id)/votes", VoteBody(agree: true), as: CaseDetail.self)
        }
        try expect(c.status == "CLOSED" && c.closeResult == "COMPLETED", "全員同意後應結案，實際 \(c.status)")
        // 互評：每個人評其他成員
        var submitted = 0
        for uid in memberIds {
            _ = try await loginUser(uid)
            let p = try await api.get("/cases/\(cid)/reviews/pending", as: PendingReviews.self)
            let body = p.items.filter { $0.submittedAt == nil }.map { ReviewSubmission(revieweeId: $0.revieweeId, satisfaction: 5, matchScore: 4, onTime: 5, communication: 4, attributionKept: nil, comment: nil) }
            try expect(body.count == memberIds.count - 1, "每個人應評價其他 \(memberIds.count - 1) 位成員，實際 \(body.count)")
            let after = try await api.post("/cases/\(cid)/reviews", body, as: PendingReviews.self)
            try expect(after.items.allSatisfy { $0.submittedAt != nil }, "送出後仍有未評價的項目")
            submitted += body.count
        }
        // 互評公開後，能力盤點模組為成員加上「結案」證據（已驗證）
        _ = try await loginUser(first.userId)
        let member = try await api.get("/me", as: Me.self)
        try checkProfile(member)
        let caseEvidence = member.skills.flatMap { s in (s.evidence ?? []).filter { $0.type == "CASE" && $0.verified }.map { "\(s.name) \($0.score)" } }
        try expect(!caseEvidence.isEmpty, "結案並互評後，成員的 Skill Profile 應出現結案證據")
        return "案件 #\(cid)：\(memberIds.count) 人成案（其中 \(invitedByList) 位由推薦名單邀請）→ 結案 → 互評 \(submitted) 筆 → \(member.name) 的結案證據：" + caseEvidence.prefix(3).joined(separator: "、")
    }
}
await step("申請：POST /roles/{id}/engagements EngagementBody(APPLY) → EngagementCreated；撤回 → CaseDetail") {
    for n in 1...50 {
        _ = try await login(n)
        guard let r = try await api.get("/me/recommended-cases", as: [RecommendedCase].self).first else { continue }
        let created = try await api.post("/roles/\(r.roleId)/engagements", EngagementBody(direction: "APPLY", userId: nil, message: ""), as: EngagementCreated.self)
        let c = try await api.post("/engagements/\(created.id)/withdraw", as: CaseDetail.self)
        try expect(c.myEngagements.contains { $0.id == created.id && $0.status == "WITHDRAWN" }, "撤回後申請狀態應為已撤回")
        return "student\(String(format: "%03d", n)) 申請「\(r.caseTitle)／\(r.roleName)」（推薦分數 \(Fmt.score(created.score))）後撤回"
    }
    throw Expect("沒有任何學生有推薦案件可申請")
}

// ---------- AI 助理 ----------
me = try await login(12)
var status: AssistantStatus!
await step("GET /assistant/status → AssistantStatus") {
    status = try await api.get("/assistant/status", as: AssistantStatus.self)
    return "\(status.label)：\(status.detail)（今日 \(status.usedToday)／\(status.dailyLimit)，步數上限 \(status.maxSteps)）"
}
var sessionId: Int?
var pendingAction: Int?
await step("助理多步驟任務：POST /assistant/messages → AssistantPosted、輪詢 /assistant/messages/{id} → AssistantMessage（卡片逐張轉成具名型別）") {
    let (m, sid, snapshots) = try await ask("我想參加比賽，幫我規劃", session: nil)
    sessionId = sid
    let kinds = try checkCards(m)
    try expect(m.status == "DONE" && m.stepList.count >= 3 && !m.content.isEmpty, "助理沒有完成：\(m.status) \(m.stop ?? "") \(m.notice ?? "")")
    try expect(m.stepList.allSatisfy { !$0.title.isEmpty && !$0.summary.isEmpty }, "執行軌跡缺少說明")
    guard let checks = m.checks else { throw Expect("缺少輸出檢核結果") }
    for card in m.cardList where card["type"].str == "action" { pendingAction = try strict(card, ActionCard.self).actionId }
    return "\(m.modeLabel)，\(m.stepList.count) 步（" + m.stepList.map { Labels.agent[$0.agent] ?? $0.agent }.joined(separator: " → ") + "），卡片 " + kinds.joined(separator: "／") + "；\(checks.text)；輪詢 \(snapshots) 次，\(m.meterText ?? "")"
}
if let sid = sessionId {
    await step("同一對話追問：GET /assistant/sessions/{id} → AssistantSession") {
        let (m, _, _) = try await ask("幫我找互補的隊友", session: sid)
        let s = try await api.get("/assistant/sessions/\(sid)", as: AssistantSession.self)
        try expect(s.messages.count == 4 && s.messages.map { $0.role } == ["user", "assistant", "user", "assistant"], "對話訊息數不符：\(s.messages.map { $0.role })")
        for x in s.messages { _ = try checkCards(x) }
        return "\(s.messages.count) 則訊息；追問後卡片 " + (try checkCards(m)).joined(separator: "／")
    }
}
if let sid = sessionId, let aid = pendingAction {
    await step("對話裡的待確認動作：POST /assistant/actions/{id}/confirm → 重新載入後卡片變成已執行") {
        let a = try await api.post("/assistant/actions/\(aid)/confirm", as: AssistantAction.self)
        try expect(a.status == "DONE" || a.status == "FAILED", "確認後狀態異常：\(a.status)")
        let s = try await api.get("/assistant/sessions/\(sid)", as: AssistantSession.self)
        var shown: ActionCard?
        for m in s.messages { for card in m.cardList where card["type"].str == "action" { let c = try strict(card, ActionCard.self); if c.actionId == aid { shown = c } } }
        guard let card = shown else { throw Expect("對話裡找不到這個動作卡片") }
        try expect(card.status == a.status && (a.status != "DONE" || card.result?.caseId != nil), "卡片狀態沒有跟著更新：\(card.status)")
        return ActionStatus.label(card.status) + (card.result?.caseId.map { "，案件 #\($0)" } ?? "") + (card.result?.error.map { "：" + $0 } ?? "")
    }
}
await step("AI 同意：POST /me/consents/ai ConsentBody → 撤回後助理改用規則模式，卡片仍解得開；重新同意後恢復") {
    _ = try await api.post("/me/consents/ai", ConsentBody(agree: false), as: EmptyResponse.self)
    let off = try await api.get("/assistant/status", as: AssistantStatus.self)
    let meOff = try await api.get("/me", as: Me.self)
    try expect(!off.aiConsent && off.mode == "RULE" && !meOff.aiConsent, "撤回同意後應為規則模式")
    let (m, _, _) = try await ask("幫我推薦競賽", session: nil)
    let kinds = try checkCards(m)
    try expect(m.mode == "RULE" && m.status == "DONE" && !kinds.isEmpty, "規則模式沒有產生結果")
    _ = try await api.post("/me/consents/ai", ConsentBody(agree: true), as: EmptyResponse.self)
    let on = try await api.get("/assistant/status", as: AssistantStatus.self)
    try expect(on.aiConsent, "重新同意沒有生效")
    return "撤回：\(off.label)（\(off.detail)），卡片 " + kinds.joined(separator: "／") + "；重新同意：\(on.label)"
}
if let n = graduate {
    await step("研究生（成績先換算到共同量尺）：/me → Me") {
        _ = try await login(n)
        let g = try await api.get("/me", as: Me.self)
        try checkProfile(g)
        try expect(g.gradeFooter.contains("研究所"), "研究生的成績說明應提到換算")
        return "student\(String(format: "%03d", n)) \(g.degreeLine)，\(g.skills.count) 項技能"
    }
}

print("\n\(passed) 項通過、\(failures.count) 項失敗" + (failures.isEmpty ? "" : "：\n  - " + failures.joined(separator: "\n  - ")))
exit(failures.isEmpty ? 0 : 1)
