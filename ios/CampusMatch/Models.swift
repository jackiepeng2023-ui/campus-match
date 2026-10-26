import Foundation

// 與後端 /api/v1 的 JSON 對應；欄位名稱與 Spring 回傳的 camelCase 一致
struct AuthResponse: Codable { let token: String; let user: Me }

struct Availability: Codable { var hoursPerWeek: Int; var availableFrom: String; var availableTo: String }
struct Grade: Codable, Identifiable { let id: Int; let courseId: Int; let course: String; let score: Int; let semester: String; let skills: String? }
struct UserSkill: Codable, Identifiable {
    let skillId: Int; let name: String; let category: String; let defaultLevel: Int?; let level: Int; let source: String
    var id: Int { skillId }
}
struct Award: Codable, Identifiable { let id: Int; let competition: String; let level: String; let rank: String; let awardDate: String; let score: Double; let skills: String? }
struct Stats: Codable {
    let avgRating: Double?; let avgMatch: Double?; let reviewCount: Int; let awardScore: Double; let responseRate: Double
    let responded: Int; let missed: Int; let credibility: Double; let closedCases: Int; let activeCases: Int
}
struct Me: Codable {
    let id: Int; let studentNo: String; let name: String; let email: String; let degree: String; let year: Int; let role: String
    let departmentId: Int; let department: String; let college: String; let expectedGraduation: String
    let availability: Availability?; let grades: [Grade]; let skills: [UserSkill]; let awards: [Award]; let stats: Stats
    let unreadNotifications: Int
}
struct PublicProfile: Codable {
    struct Skill: Codable, Identifiable { let skillId: Int; let name: String; let category: String; let level: Int; var id: Int { skillId } }
    let id: Int; let name: String; let degree: String; let year: Int; let department: String; let college: String
    let skills: [Skill]; let awards: [Award]; let stats: Stats; let availability: Availability?
}

struct MetaSkill: Codable, Identifiable { let id: Int; let name: String; let category: String }
struct MetaDepartment: Codable, Identifiable { let id: Int; let name: String; let collegeId: Int; let college: String }
struct MetaCourse: Codable, Identifiable { let id: Int; let name: String; let departmentId: Int?; let isGraduate: Bool; let skills: String? }
struct Meta: Codable { let skills: [MetaSkill]; let departments: [MetaDepartment]; let courses: [MetaCourse] }

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
    struct Radar: Codable, Identifiable { let category: String; let avgLevel: Double; let maxLevel: Int; let n: Int; var id: String { category } }
    struct Event: Codable, Identifiable { let ts: String; let kind: String; let text: String; let ref: Int?; var id: String { ts + kind + text } }
    let radar: [Radar]; let skills: [UserSkill]; let timeline: [Event]; let stats: Stats
}
struct PromptResponse: Codable { let prompt: String; let notice: String }

struct NotificationItem: Codable, Identifiable { let id: Int; let type: String; let title: String; let body: String; let link: String?; let createdAt: String; let readAt: String? }
struct NotificationList: Codable { let unread: Int; let items: [NotificationItem] }

struct APIError: Codable { let code: String?; let message: String?; let reasons: [String]? }

enum Labels {
    static let type = ["PROJECT": "專題", "COMPETITION": "競賽", "SHORT_TERM": "短期支援", "RESEARCH": "研究協作"]
    static let status = ["DRAFT": "草稿", "OPEN": "招募中", "FORMED": "已成案", "IN_PROGRESS": "執行中", "CLOSING": "結案確認中", "CLOSED": "已結案", "CANCELLED": "已取消", "EXPIRED": "截止未成案"]
    static let eng = ["PENDING": "待回覆", "ACCEPTED": "已成立", "DECLINED": "已拒絕", "WITHDRAWN": "已撤回", "EXPIRED": "逾時放棄", "FULL": "額滿"]
    static let degree = ["BACHELOR": "學士", "MASTER": "碩士", "PHD": "博士"]
    static let factor = ["S": "技能", "T": "時間", "R": "評價", "P": "回應", "C": "跨系"]
    static let level = ["CAMPUS": "校內", "NATIONAL": "全國", "INTERNATIONAL": "國際"]
    static let rank = ["FIRST": "第一名", "TOP3": "前三名", "HONORABLE": "佳作", "FINALIST": "入圍"]
    static let attribution = ["AUTHORSHIP": "論文掛名", "ACK": "致謝", "NONE": "無"]
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
