import Foundation

// 與後端 /api/v1 的 JSON 對應；欄位名稱與 Spring 回傳的 camelCase 一致
struct AuthResponse: Codable { let token: String; let user: Me }

struct Availability: Codable { var hoursPerWeek: Int; var availableFrom: String; var availableTo: String }
struct Grade: Codable, Identifiable {
    let id: Int; let courseId: Int; let course: String; let score: Int; let semester: String; let skills: String?
    let code: String?; let requirement: String?; let credits: Double?; let gradeYear: Int?; let term: Int?; let department: String?; let pendingSkills: String?
}
/// Skill Profile 的一筆證據（D54）：課程、證照、作品集、競賽、結案、自評
struct Evidence: Codable, Identifiable {
    let id: Int; let type: String; let typeLabel: String; let title: String; let score: Int; let verified: Bool; let tier: String
    let detail: String?; let occurredOn: String?; let proofUrl: String?
}
/// Skill Profile 的一項技能（D53）：score 0–100（只有本人看得到）、level 0–3、tier 初階／中階／進階、trust VERIFIED／COURSE／SELF
struct UserSkill: Codable, Identifiable {
    let skillId: Int; let name: String; let category: String; let score: Int; let level: Int; let tier: String
    let trust: String; let trustLabel: String; let evidenceCount: Int; let source: String; let sourceLabel: String?; let evidence: [Evidence]?
    var id: Int { skillId }
}
struct Credential: Codable, Identifiable { let id: Int; let type: String; let title: String; let issuer: String?; let obtainedOn: String?; let score: Int; let proofUrl: String?; let verified: Bool; let skills: String? }
struct LevelBand: Codable, Identifiable { let tier: Int; let name: String; let minScore: Int; let degreeGroup: String?; var id: String { (degreeGroup ?? "") + "\(tier)" } }
struct Award: Codable, Identifiable { let id: Int; let competition: String; let level: String; let rank: String; let awardDate: String; let score: Double; let skills: String?; let proofUrl: String?; let verified: Bool? }
struct Stats: Codable {
    let avgRating: Double?; let avgMatch: Double?; let reviewCount: Int; let awardScore: Double; let responseRate: Double
    let responded: Int; let missed: Int; let credibility: Double; let closedCases: Int; let activeCases: Int
}
struct Me: Codable {
    let id: Int; let studentNo: String; let name: String; let email: String; let degree: String; let year: Int; let role: String
    let departmentId: Int; let entryYear: Int?; let department: String; let college: String; let expectedGraduation: String
    let availability: Availability?; let grades: [Grade]; let skills: [UserSkill]; let awards: [Award]; let stats: Stats
    let credentials: [Credential]; let levelBands: [LevelBand]; let aiConsent: Bool
    let unreadNotifications: Int
}
struct PublicProfile: Codable {
    /// 對外只有階級與可信狀態，沒有分數（D16）
    struct Skill: Codable, Identifiable { let skillId: Int; let name: String; let category: String; let level: Int; let tier: String; let trust: String; let trustLabel: String; var id: Int { skillId } }
    let id: Int; let name: String; let degree: String; let year: Int; let department: String; let college: String
    let skills: [Skill]; let awards: [Award]; let stats: Stats; let availability: Availability?
}

struct MetaSkill: Codable, Identifiable { let id: Int; let name: String; let category: String }
struct MetaDepartment: Codable, Identifiable { let id: Int; let name: String; let collegeId: Int; let college: String }
struct CatalogCertificate: Codable, Identifiable { let id: Int; let name: String; let issuer: String?; let score: Int; let skills: String? }
struct Meta: Codable {
    let skills: [MetaSkill]; let departments: [MetaDepartment]; let currentAcademicYear: Int?
    let levelBands: [LevelBand]?; let certificateCatalog: [CatalogCertificate]?; let maxSkillsPerEvidence: Int?; let termsVersion: String?
}

// 正式科目表（GET /courses）：系所 × 學制 × 入學學年度；requirement = REQUIRED／ELECTIVE／GENERAL
struct Course: Codable, Identifiable {
    let id: Int; let code: String?; let name: String; let requirement: String; let groupCode: String?; let credits: Double?
    let gradeYear: Int?; let term: Int?; let entryYear: Int?; let degree: String?; let departmentId: Int?; let department: String?
    let skills: String?; let pendingSkills: String?; let myScore: Int?; let mySemester: String?
}
struct CourseOptions: Codable { let departmentId: Int; let degree: String; let entryYear: Int?; let years: [Int]; let nearestYear: Int?; let currentAcademicYear: Int }

struct Engagement: Codable, Identifiable {
    let id: Int; let direction: String; let status: String; let message: String?; let score: Double?; let dueAt: String
    let createdAt: String; let decidedAt: String?
    let roleId: Int; let roleName: String; let caseId: Int; let caseTitle: String; let caseType: String; let caseStatus: String
    let ownerName: String; let ownerDepartment: String
}

struct RoleSkillRec: Codable, Identifiable { let skillId: Int; let name: String; let minLevel: Int; let required: Bool; var id: Int { skillId } }
struct RecommendedCase: Codable, Identifiable {
    let caseId: Int; let caseTitle: String; let caseType: String; let roleId: Int; let roleName: String
    let headcount: Int; let filled: Int; let skills: [RoleSkillRec]; let score: Double; let breakdown: [String: Double]; let reasons: [String]
    var id: Int { roleId }
}

struct CaseSummary: Codable, Identifiable {
    let id: Int; let title: String; let type: String; let status: String; let teamSize: Int; let applyDeadline: String
    let startDate: String; let endDate: String; let attribution: String?; let createdAt: String; let closeResult: String?
    let ownerId: Int; let ownerName: String; let ownerDepartment: String; let ownerCollege: String
    let headcount: Int; let filled: Int; let skillNames: String?; let roleNames: String?; let pendingApplications: Int; let isMember: Bool
}

struct CaseRoleSkill: Codable, Identifiable { let skillId: Int; let name: String; let category: String; let minLevel: Int; let isRequired: Bool; var id: Int { skillId } }
struct CaseRole: Codable, Identifiable {
    let id: Int; let roleName: String; let headcount: Int; let filledCount: Int; let hoursPerWeek: Int
    let pendingInvites: Int; let pendingApplications: Int; let skills: [CaseRoleSkill]; let invitable: Int
}
struct CaseMember: Codable, Identifiable { let userId: Int; let name: String; let department: String; let college: String; let isOwner: Bool; let roleName: String?; let joinedAt: String; var id: Int { userId } }
struct MyEngagement: Codable, Identifiable { let id: Int; let roleId: Int; let roleName: String; let direction: String; let status: String; let dueAt: String; let score: Double?; let createdAt: String }
struct CaseEngagement: Codable, Identifiable {
    let id: Int; let roleId: Int; let roleName: String; let direction: String; let status: String; let message: String?; let score: Double?
    let dueAt: String; let createdAt: String; let decidedAt: String?; let userId: Int; let name: String; let department: String; let college: String; let degree: String; let year: Int
}
struct CloseVote: Codable, Identifiable { let userId: Int; let name: String; let agree: Bool; let votedAt: String; var id: Int { userId } }
struct MyVote: Codable { let agree: Bool }
struct CloseRequest: Codable { let id: Int; let result: String; let auto: Bool; let status: String; let requestedAt: String; let dueAt: String; let votes: [CloseVote]; let myVote: MyVote? }
struct CaseDetail: Codable {
    let id: Int; let title: String; let type: String; let description: String; let status: String; let teamSize: Int
    let applyDeadline: String; let startDate: String; let endDate: String; let attribution: String?; let closeResult: String?
    let createdAt: String; let closedAt: String?; let ownerId: Int; let ownerName: String; let ownerDepartment: String; let ownerCollege: String
    let isOwner: Bool; let roles: [CaseRole]; let members: [CaseMember]; let isMember: Bool; let myEngagements: [MyEngagement]
    let engagements: [CaseEngagement]?; let closeRequest: CloseRequest?; let pendingReviews: Int
}

struct Weights: Codable { let s: Double; let t: Double; let r: Double; let p: Double; let c: Double }
struct Candidate: Codable, Identifiable {
    let userId: Int; let name: String; let college: String; let dept: String; let degree: String; let year: Int; let hoursPerWeek: Int
    let score: Double; let breakdown: [String: Double]; let reasons: [String]; let blockedBy: [String]; let stats: Stats
    var id: Int { userId }
}
struct RecommendationResponse: Codable {
    struct Role: Codable { let id: Int; let roleName: String; let headcount: Int; let filled: Int; let pendingInvites: Int; let invitable: Int; let skills: [RoleSkillRec] }
    let role: Role; let weights: Weights; let recommended: [Candidate]; let blocked: [Candidate]
}
struct EngagementCreated: Codable { let id: Int; let status: String; let dueAt: String; let score: Double; let reasons: [String] }

struct PendingReviews: Codable {
    struct Item: Codable, Identifiable {
        let id: Int; let revieweeId: Int; let name: String; let department: String; let dueAt: String; let submittedAt: String?; let missed: Bool; let isOwner: Bool
    }
    let caseId: Int; let caseTitle: String; let caseType: String; let askAttribution: Bool; let items: [Item]
}
struct ReviewSubmission: Codable { let revieweeId: Int; let satisfaction: Int; let matchScore: Int; let onTime: Int; let communication: Int; let attributionKept: String?; let comment: String? }

struct Growth: Codable {
    struct Radar: Codable, Identifiable { let category: String; let avgScore: Double; let maxScore: Int; let n: Int; let verified: Int?; var id: String { category } }
    struct Event: Codable, Identifiable { let ts: String; let kind: String; let text: String; let ref: Int?; var id: String { ts + kind + text } }
    let radar: [Radar]; let skills: [UserSkill]; let timeline: [Event]; let stats: Stats
}
struct PromptResponse: Codable { let prompt: String; let notice: String }

struct NotificationItem: Codable, Identifiable { let id: Int; let type: String; let title: String; let body: String; let link: String?; let createdAt: String; let readAt: String? }
struct NotificationList: Codable { let unread: Int; let items: [NotificationItem] }

// ---------- NAPAI：三個媒合 Agent 與 AI 助理 ----------
struct SkillItem: Codable, Identifiable { let skillId: Int; let name: String; let core: Bool; let required: String; let mine: String?; let trust: String?; var id: Int { skillId } }
struct CompetitionSkill: Codable, Identifiable { let skillId: Int; let name: String; let minLevel: Int; let tier: String; let importance: String; var id: Int { skillId } }
/// 競賽（/competitions）＋競賽 Agent 的評估（/agents/competitions、/competitions/{id}）；fit 之後的欄位只有評估過才有
struct Competition: Codable, Identifiable {
    let id: Int; let name: String; let shortName: String; let organizer: String?; let category: String; let level: String; let url: String?; let description: String?
    let eligibilityNote: String?; let teamMin: Int?; let teamMax: Int?; let advisorRequired: Bool?; let applyDeadline: String?; let eventDate: String?; let prize: String?
    let daysLeft: Int?; let status: String; let sourceUrl: String?; let checkedAt: String?; let skills: [CompetitionSkill]
    let fit: Double?; let eligible: Bool?; let blockedBy: [String]?; let coreMet: Int?; let coreTotal: Int?
    let strengths: [SkillItem]?; let weaknesses: [SkillItem]?; let gaps: [SkillItem]?; let reasons: [String]?
}
struct CompetitionRecommendation: Codable { let recommended: [Competition]; let totalEligible: Int; let blocked: [Competition]; let trace: [String] }
struct TeammatesResult: Codable {
    struct Candidate: Codable, Identifiable { let userId: Int; let name: String; let department: String; let college: String; let score: Double; let complementReasons: [String]; var id: Int { userId } }
    struct Pick: Codable, Identifiable { let userId: Int; let name: String; let department: String; let fills: [String]; var id: Int { userId } }
    struct Suggested: Codable { let picks: [Pick]; let remainingGaps: [String]; let coveredAfter: Int; let total: Int }
    let gaps: [SkillItem]; let candidates: [Candidate]; let suggestedTeam: Suggested; let trace: [String]
}
struct TeachersResult: Codable {
    struct Teacher: Codable, Identifiable { let teacherId: Int; let name: String; let title: String?; let department: String?; let fit: Double; let reasons: [String]; let toConfirm: [String]; let profileUrl: String?; var id: Int { teacherId } }
    let teachers: [Teacher]; let totalMatched: Int; let trace: [String]
}
struct AgentRequest: Encodable { let competitionId: Int; var limit: Int = 6 }
struct DraftTeamBody: Encodable { let competitionId: Int; let inviteUserIds: [Int]; let advisorTeacherId: Int?; let hoursPerWeek: Int? }

/// 卡片與動作的內容是巢狀 JSON：用通用型別讀取，畫面只取需要的欄位
indirect enum JSONValue: Codable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s); case .bool(let b): try c.encode(b)
        case .number(let n): if n == n.rounded(), abs(n) < 1e15 { try c.encode(Int(n)) } else { try c.encode(n) }   // 整數值寫成整數，轉成具名型別時 Int 欄位才解得開
        case .object(let o): try c.encode(o); case .array(let a): try c.encode(a); case .null: try c.encodeNil()
        }
    }
    /// 卡片是巢狀 JSON：依 type 轉成具名型別（與 REST 回應共用同一組 struct）；欄位不符時回傳 nil，畫面略過該卡片而不是整頁失敗
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    subscript(key: String) -> JSONValue { if case .object(let o) = self { return o[key] ?? .null }; return .null }
    var list: [JSONValue] { if case .array(let a) = self { return a }; return [] }
    var str: String? { switch self { case .string(let s): return s; case .number(let n): return n == n.rounded() ? String(Int(n)) : String(format: "%.1f", n); default: return nil } }
    var int: Int? { if case .number(let n) = self { return Int(n) }; return nil }
    var strings: [String] { list.compactMap { $0.str } }
    var stringValue: String? { if case .bool(let b) = self { return b ? "true" : "false" }; return str }
    var doubleValue: Double? { if case .number(let d) = self { return d }; return nil }
}
struct AssistantStatus: Codable { let llmEnabled: Bool; let aiConsent: Bool; let mode: String; let model: String?; let notice: String?; let dailyLimit: Int; let usedToday: Int; let maxSteps: Int }
struct AssistantPosted: Codable { let sessionId: Int; let userMessageId: Int; let assistantMessageId: Int; let status: String }
struct AssistantStep: Codable, Identifiable { let seq: Int; let agent: String; let tool: String; let summary: String; let ok: Bool; let durationMs: Int; var id: Int { seq } }
struct AssistantChecks: Codable { let ok: Bool; let unverified: [String]; let unknownTokens: [String] }
struct AssistantMessage: Codable, Identifiable {
    let id: Int; let role: String; var content: String; let mode: String?; let status: String; let notice: String?; let stop: String?
    let durationMs: Int?; let toolCalls: Int?; let llmCalls: Int?; let steps: [AssistantStep]?; let cards: [JSONValue]?; let checks: AssistantChecks?
}
struct AssistantSession: Codable { let id: Int; let messages: [AssistantMessage] }
/// 待確認動作（D56）：助理只準備草稿，按下確認才會建立案件、送出邀請
struct ActionPayload: Codable {
    struct Role: Codable { let roleName: String; let headcount: Int; let hoursPerWeek: Int; let inviteUserId: Int?; let inviteName: String?; let inviteDepartment: String? }
    let title: String; let teamSize: Int; let applyDeadline: String; let startDate: String; let endDate: String
    let description: String?; let competitionId: Int?; let competitionName: String?; let advisorTeacherId: Int?; let advisorName: String?; let roles: [Role]
}
struct ActionResult: Codable {
    struct Row: Codable { let userId: Int; let name: String?; let role: String?; let reason: String? }
    let caseId: Int?; let title: String?; let invited: [Row]?; let failed: [Row]?; let error: String?
}
struct AssistantAction: Codable { let id: Int; let title: String; let status: String; let payload: ActionPayload; let result: ActionResult? }
// 對話卡片（cards[].type）：profile／competitions／competition／competition_list／teammates／teachers／action
struct ActionCard: Codable { let actionId: Int; let title: String; let status: String; let payload: ActionPayload; let result: ActionResult? }
struct ProfileCard: Codable {
    struct Top: Codable { let name: String; let tier: String; let trustLabel: String }
    let total: Int; let top: [Top]; let byTier: [String: Int]; let byTrust: [String: Int]
}
struct CompetitionListCard: Codable { let keyword: String?; let items: [Competition] }
struct MessageBody: Encodable { let sessionId: Int?; let text: String }
struct ConsentBody: Encodable { let agree: Bool }
struct CredentialBody: Encodable { let type: String; let title: String?; let issuer: String?; let obtainedOn: String?; let catalogId: Int?; let tier: Int?; let proofUrl: String?; let skillIds: [Int] }

// 知識圖譜（GET /me/growth/graph）：證據（科目、證照與作品、得獎、結案案件）→ 技能 → 分類；與網頁、Obsidian 匯出為同一份資料
struct GraphNode: Codable, Identifiable {
    let id: String; let type: String; let label: String; let data: [String: JSONValue]
    func str(_ k: String) -> String? { data[k]?.stringValue }
    func num(_ k: String) -> Double? { data[k]?.doubleValue }
}
struct GraphEdge: Codable { let source: String; let target: String; let kind: String; let weight: Double }
struct GraphData: Codable { let nodes: [GraphNode]; let edges: [GraphEdge]; let summary: [String: Int] }

struct APIError: Codable { let code: String?; let message: String?; let reasons: [String]? }

enum Labels {
    static let type = ["PROJECT": "專題", "COMPETITION": "競賽", "SHORT_TERM": "短期支援", "RESEARCH": "研究協作"]
    static let status = ["DRAFT": "草稿", "OPEN": "招募中", "FORMED": "已成案", "IN_PROGRESS": "執行中", "CLOSING": "結案確認中", "CLOSED": "已結案", "CANCELLED": "已取消", "EXPIRED": "截止未成案"]
    static let eng = ["PENDING": "待回覆", "ACCEPTED": "已成立", "DECLINED": "已拒絕", "WITHDRAWN": "已撤回", "EXPIRED": "逾時放棄", "FULL": "額滿"]
    static let degree = ["BACHELOR": "學士", "MASTER": "碩士", "PHD": "博士"]
    static let requirement = ["REQUIRED": "必修", "ELECTIVE": "選修", "GENERAL": "通識"]
    static let factor = ["S": "技能", "T": "時間", "R": "評價", "P": "回應", "C": "跨系"]
    static let level = ["CAMPUS": "校內", "NATIONAL": "全國", "INTERNATIONAL": "國際"]
    static let rank = ["FIRST": "第一名", "TOP3": "前三名", "HONORABLE": "佳作", "FINALIST": "入圍"]
    static let attribution = ["AUTHORSHIP": "論文掛名", "ACK": "致謝", "NONE": "無"]
    static let tier = ["未達初階", "初階", "中階", "進階"]                                   // D53 三階等級
    static let evidence = ["COURSE": "課程", "CERTIFICATE": "證照", "PORTFOLIO": "作品集", "COMPETITION": "競賽", "CASE": "結案", "SELF": "自評"]
    static let agent = ["PROFILE": "能力盤點", "COMPETITION": "競賽 Agent", "STUDENT": "學生 Agent", "TEACHER": "教師 Agent", "ACTION": "待確認動作"]
    static func tierName(_ level: Int) -> String { tier[max(0, min(3, level))] }
    static func bands(_ b: [LevelBand]) -> String {
        let l = b.filter { $0.degreeGroup == nil || $0.degreeGroup == "BACHELOR" }.sorted { $0.tier < $1.tier }
        return l.enumerated().map { i, x in "\(x.name) \(x.minScore)–\(i + 1 < l.count ? l[i + 1].minScore - 1 : 100)" }.joined(separator: "、")
    }
}

enum Fmt {
    private static let iso: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }()
    private static let isoNoFrac: ISO8601DateFormatter = { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
    static func date(_ s: String?) -> Date? { guard let s = s else { return nil }; return iso.date(from: s) ?? isoNoFrac.date(from: s) }
    /// "10/26 14:30"
    static func time(_ s: String?) -> String {
        guard let d = date(s) else { return String((s ?? "").prefix(10)) }
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_TW"); f.dateFormat = "M/d HH:mm"; return f.string(from: d)
    }
    static func day(_ s: String?) -> String { String((s ?? "").prefix(10)) }
    static func hoursLeft(_ s: String?) -> Int { guard let d = date(s) else { return 0 }; return max(0, Int(d.timeIntervalSinceNow / 3600)) }
    static func score(_ v: Double) -> String { String(format: "%.1f", v) }
    static func pct(_ v: Double) -> String { "\(Int((v * 100).rounded()))%" }
    static func opt(_ v: Double?) -> String { v.map { String(format: "%.1f", $0) } ?? "—" }
}

// ---------- 顯示用文字 ----------
// 只用 Foundation：畫面（SwiftUI）只負責排版，字串在這裡組好。
// ios/ContractCheck 會在 Linux 上編譯這個檔案，並用後端的實際回應驗證每個型別都解得開、每段文字都組得出來。
private func joined(_ parts: [String?], _ sep: String) -> String { parts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: sep) }

extension Me {
    var degreeLine: String { "\(Labels.degree[degree] ?? degree) \(year) 年級" + (entryYear.map { "（\($0) 學年度入學）" } ?? "") }
    var curriculumNote: String { entryYear.map { "\($0) 學年度入學" } ?? "依年級推算" }
    var skillFooter: String { "等級：\(Labels.bands(levelBands))。同一技能有多筆證據時不疊加、取最高分；分數只有你看得到，別人只看到階級與「已驗證／修課成績／自述」。" }
    var gradeFooter: String {
        "科目清單來自學校公告的科目表（\(curriculumNote)）。每門課由規則、課綱與 AI 對到 Skill 資料庫的技能；"
            + (degree == "BACHELOR" ? "學士成績直接作為證據分數。" : "研究所成績先依研究所門檻換算到共同量尺。")
    }
    var availabilityFooter: String { "可用期間 \(availability?.availableFrom ?? "—") ～ \(availability?.availableTo ?? "—")" }
}
extension UserSkill { var subtitle: String { "\(category) · \(evidenceCount) 筆證據" } }
extension Evidence {
    var headline: String { "\(title)　\(score) 分（\(tier)）" }
    var subline: String { joined([detail, occurredOn], "・") }
    var trustLabel: String { verified ? "已驗證" : (type == "COURSE" ? "修課成績" : "自述") }
}
extension Credential {
    var subtitle: String { joined([Labels.evidence[type] ?? type, skills, obtainedOn], " · ") }
    var trustLabel: String { verified ? "已驗證" : "自述" }
}
extension Grade {
    func subtitle(myDepartment: String) -> String {
        var s = semester
        if let k = skills, !k.isEmpty { s += " → " + k }
        if let p = pendingSkills, !p.isEmpty { s += "（待核准：" + p + "）" }
        if let d = department, d != myDepartment { s += " · " + d }
        return s
    }
}
extension Award {
    var subtitle: String { "\(Labels.level[level] ?? level)・\(Labels.rank[rank] ?? rank) · \(awardDate)" }
    var trustLabel: String { verified == true ? "已驗證" : "自述" }
}
extension CatalogCertificate { var optionLabel: String { "\(name)（\(score) 分）" } }
extension MetaSkill { var optionLabel: String { "\(category)｜\(name)" } }

extension SkillItem {
    var strengthText: String { let d = joined([mine, trust], "・"); return d.isEmpty ? name : "\(name)（\(d)）" }
    var weaknessText: String { "\(name)（\(mine ?? "未達初階")，需 \(required)）" }
}
extension Competition {
    var isClosed: Bool { status == "CLOSED" }
    var deadlineText: String {
        guard let d = applyDeadline else { return "報名日期未公告" }
        if isClosed { return "報名已截止 " + d }
        return "報名截止 " + d + (daysLeft.map { "（剩 \($0) 天）" } ?? "")
    }
    var metaLine: String { "\(category)・\(Labels.level[level] ?? level)・\(deadlineText)" }
    var teamText: String {
        if teamMax == 1 { return "個人賽" }
        let lo = teamMin.map { String($0) } ?? "?", hi = teamMax.map { String($0) } ?? "?"
        return "\(lo)–\(hi) 人" + (advisorRequired == true ? "・需指導老師" : "")
    }
    var fitText: String { fit.map { Fmt.score($0) } ?? "—" }
    var coreText: String { "核心技能 \(coreMet ?? 0)／\(coreTotal ?? 0)" }
    var strengthText: String? { guard let s = strengths, !s.isEmpty else { return nil }; return "優點：" + s.map { $0.strengthText }.joined(separator: "、") }
    var weaknessText: String? { guard let w = weaknesses, !w.isEmpty else { return nil }; return "弱項：" + w.map { $0.weaknessText }.joined(separator: "、") }
    var gapText: String? { guard let g = gaps, !g.isEmpty else { return nil }; return "能力缺口：" + g.map { $0.name }.joined(separator: "、") }
    var link: URL? { (url ?? sourceUrl).flatMap { URL(string: $0) } }
    var checkedText: String { "資料查證日 \(checkedAt ?? "—")；日期與資格以官方公告為準。" }
}
extension TeammatesResult {
    var gapText: String? { gaps.isEmpty ? nil : "團隊缺口：" + gaps.map { $0.name }.joined(separator: "、") }
    var suggestionText: String? {
        if suggestedTeam.picks.isEmpty { return nil }
        return "建議組合：" + suggestedTeam.picks.map { $0.text }.joined(separator: "、")
    }
}
extension TeammatesResult.Pick { var text: String { "\(name)（\(department)）補 " + fills.joined(separator: "、") } }
extension TeammatesResult.Candidate {
    var headline: String { "\(name)・\(department)" }
    var why: String { complementReasons.prefix(2).joined(separator: "；") }
}
extension TeachersResult.Teacher {
    var headline: String { joined([joined([name, title], " "), department], "・") }
    var why: String { reasons.first ?? "" }
    var confirmText: String? { toConfirm.first.map { "待確認：" + $0 } }
}
extension AssistantStatus {
    var isLLM: Bool { mode == "LLM" }
    var label: String { isLLM ? "Claude" : "規則模式" }
    var detail: String { isLLM ? "由 \(model ?? "Claude") 規劃步驟、呼叫工具" : (notice ?? "未使用語言模型：依固定規則呼叫各 Agent") }
}
extension AssistantMessage {
    var running: Bool { status == "RUNNING" }
    var isLLM: Bool { mode == "LLM" }
    var modeLabel: String { running ? "執行中" : (isLLM ? "Claude" : "規則模式") }
    var meterText: String? {
        guard !running, let d = durationMs else { return nil }
        return String(format: "%.1f", Double(d) / 1000) + " 秒・工具 \(toolCalls ?? 0) 次"
    }
    var stepList: [AssistantStep] { steps ?? [] }
    var cardList: [JSONValue] { cards ?? [] }
    var progressText: String { stepList.isEmpty ? "理解目標、規劃步驟…" : "依上一步的結果決定下一步…" }
}
extension AssistantChecks { var text: String { ok ? "輸出檢核通過" : "輸出檢核：" + (unverified + unknownTokens).joined(separator: "、") + " 無法對應工具結果" } }
extension AssistantStep { var title: String { "\(Labels.agent[agent] ?? agent)・\(tool)" } }
extension ActionPayload {
    var summary: String { "\(teamSize) 人（含你）・招募截止 \(applyDeadline)・期間 \(startDate) ~ \(endDate)" }
    var advisorText: String? { advisorName.map { "指導老師（待你自行聯絡確認）：" + $0 } }
}
extension ActionPayload.Role { var text: String { "・\(roleName)：" + (inviteName.map { "邀請 " + $0 + (inviteDepartment.map { "（" + $0 + "）" } ?? "") } ?? "公開招募") } }
extension ActionResult {
    var invitedText: String? { guard let i = invited, !i.isEmpty else { return nil }; return "已邀請：" + i.compactMap { $0.name }.joined(separator: "、") }
    var failedText: String? { guard let f = failed, !f.isEmpty else { return nil }; return "未送出：" + f.map { joined([$0.name, $0.reason], "－") }.joined(separator: "；") }
}
enum ActionStatus {
    static func label(_ s: String) -> String { ["PENDING": "待你確認", "DONE": "已執行", "CANCELLED": "已取消，沒有任何變動", "FAILED": "執行失敗"][s] ?? s }
}
extension ProfileCard { var title: String { "能力盤點：\(total) 項技能" } }

