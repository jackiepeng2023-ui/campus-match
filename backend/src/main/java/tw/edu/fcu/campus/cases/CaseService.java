package tw.edu.fcu.campus.cases;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.notify.NotificationService;
import tw.edu.fcu.campus.ranking.RankingEngine;
import tw.edu.fcu.campus.ranking.RankingService;

import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.*;

/**
 * 隊伍（程式裡稱 case）與申請／邀請。3.1 只建立比賽隊伍；精簡的開隊表單與隊伍牆在 {@link TeamService}。
 * 案件狀態：DRAFT → OPEN → FORMED → IN_PROGRESS → CLOSING → CLOSED；OPEN 可 EXPIRED；DRAFT/OPEN/FORMED 可 CANCELLED。
 * 申請與邀請共用 engagements（D17），名額在同一交易內以 FOR UPDATE 鎖定（D25）。
 */
@Service
public class CaseService {
    private final Db db;
    private final DemoClock clock;
    private final NotificationService notify;
    private final RankingService ranking;
    private static final ZoneId TZ = ZoneId.of("Asia/Taipei");

    public CaseService(Db db, DemoClock clock, NotificationService notify, RankingService ranking) {
        this.db = db; this.clock = clock; this.notify = notify; this.ranking = ranking;
    }

    int param(String key, int dflt) {
        Integer v = db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = :k", "k", key);
        return v == null ? dflt : v;
    }

    // ---------- 建立 / 編輯 ----------
    public record RoleSkillIn(Integer skillId, Integer minLevel, Boolean isRequired) {}
    public record RoleIn(String roleName, Integer headcount, Integer hoursPerWeek, List<RoleSkillIn> skills) {}
    /** competitionId／advisorTeacherId：選填，案件對應的競賽與指導老師（由競賽頁或 AI 助理帶入） */
    public record CaseIn(String title, String type, String description, Integer teamSize, String applyDeadline,
                         String startDate, String endDate, String attribution, List<RoleIn> roles, Integer competitionId, Integer advisorTeacherId) {}

    @Transactional
    public Map<String, Object> create(int uid, CaseIn in) {
        validate(in);
        assertNotInCompetition(uid, in.competitionId(), null);
        int id = db.insertReturningId("""
                INSERT INTO cases (owner_id, title, type, description, team_size, apply_deadline, start_date, end_date, attribution, status, created_at, competition_id, advisor_teacher_id)
                VALUES (:o, :t, :ty, :d, :n, :dl, :s, :e, :a, 'DRAFT', :c, :comp, :adv) RETURNING id""",
                "comp", in.competitionId(), "adv", in.advisorTeacherId(),
                "o", uid, "t", in.title().trim(), "ty", in.type(), "d", in.description() == null ? "" : in.description(), "n", in.teamSize(),
                "dl", Db.ts(parseDeadline(in.applyDeadline())), "s", LocalDate.parse(in.startDate()), "e", LocalDate.parse(in.endDate()),
                "a", "RESEARCH".equals(in.type()) ? in.attribution() : null, "c", Db.ts(clock.instant()));
        addMember(id, uid, null, true, in.competitionId());
        saveRoles(id, in.roles());
        notify.log(uid, "case", id, "CREATE", null);
        return detail(id, uid, false);
    }

    @Transactional
    public Map<String, Object> update(int caseId, int uid, CaseIn in) {
        var c = owned(caseId, uid);
        if (!"DRAFT".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "只有草稿可以編輯");
        validate(in);
        db.exec("""
                UPDATE cases SET title = :t, type = :ty, description = :d, team_size = :n, apply_deadline = :dl, start_date = :s, end_date = :e, attribution = :a,
                       competition_id = :comp, advisor_teacher_id = :adv WHERE id = :id""",
                "comp", in.competitionId(), "adv", in.advisorTeacherId(),
                "t", in.title().trim(), "ty", in.type(), "d", in.description() == null ? "" : in.description(), "n", in.teamSize(),
                "dl", Db.ts(parseDeadline(in.applyDeadline())), "s", LocalDate.parse(in.startDate()), "e", LocalDate.parse(in.endDate()),
                "a", "RESEARCH".equals(in.type()) ? in.attribution() : null, "id", caseId);
        db.exec("DELETE FROM case_role_skills WHERE case_role_id IN (SELECT id FROM case_roles WHERE case_id = :c)", "c", caseId);
        db.exec("DELETE FROM case_roles WHERE case_id = :c", "c", caseId);
        saveRoles(caseId, in.roles());
        return detail(caseId, uid, false);
    }

    private void saveRoles(int caseId, List<RoleIn> roles) {
        for (RoleIn r : roles) {
            int rid = db.insertReturningId("INSERT INTO case_roles (case_id, role_name, headcount, hours_per_week) VALUES (:c, :n, :h, :w) RETURNING id",
                    "c", caseId, "n", r.roleName().trim(), "h", r.headcount(), "w", r.hoursPerWeek() == null ? 4 : r.hoursPerWeek());
            for (RoleSkillIn s : r.skills())
                db.exec("INSERT INTO case_role_skills VALUES (:r, :s, :m, :q) ON CONFLICT DO NOTHING", "r", rid, "s", s.skillId(), "m", s.minLevel(), "q", s.isRequired() == null || s.isRequired());
        }
    }

    private void validate(CaseIn in) {
        if (in.title() == null || in.title().isBlank()) throw ApiException.badRequest("標題為必填");
        // 3.1 只做比賽（D62）：專題、短期支援、研究協作不再建立；資料表的類型欄位與舊資料保留
        if (!"COMPETITION".equals(in.type())) throw ApiException.badRequest("這一版只開放比賽隊伍（專題、短期支援、研究協作已停用）");
        if (in.competitionId() == null) throw ApiException.badRequest("請先選一場比賽");
        if (in.teamSize() == null || in.teamSize() < 2) throw ApiException.badRequest("每隊人數至少 2 人（含隊長）");
        LocalDate s, e;
        try { s = LocalDate.parse(in.startDate()); e = LocalDate.parse(in.endDate()); parseDeadline(in.applyDeadline()); }
        catch (ApiException ex) { throw ex; } catch (Exception ex) { throw ApiException.badRequest("日期格式錯誤"); }
        if (e.isBefore(s)) throw ApiException.badRequest("結束日不可早於開始日");
        if (in.competitionId() != null && db.count("SELECT count(*) FROM competitions WHERE id = :c AND approved", "c", in.competitionId()) == 0) throw ApiException.badRequest("競賽不存在");
        if (in.advisorTeacherId() != null && db.count("SELECT count(*) FROM teachers WHERE id = :t AND active", "t", in.advisorTeacherId()) == 0) throw ApiException.badRequest("教師不存在");
        if (in.roles() == null || in.roles().isEmpty()) throw ApiException.badRequest("至少一個角色");
        int total = 0;
        for (RoleIn r : in.roles()) {
            if (r.roleName() == null || r.roleName().isBlank() || r.headcount() == null || r.headcount() < 1) throw ApiException.badRequest("角色名稱與名額為必填");
            if (r.skills() == null || r.skills().isEmpty()) throw ApiException.badRequest("角色「" + r.roleName() + "」至少一項技能條件");
            for (RoleSkillIn sk : r.skills()) if (sk.skillId() == null || sk.minLevel() == null || sk.minLevel() < 1 || sk.minLevel() > 3) throw ApiException.badRequest("技能條件須含技能與最低階級（1 初階／2 中階／3 進階）");
            total += r.headcount();
        }
        if (total != in.teamSize() - 1) throw ApiException.badRequest("角色名額總和（" + total + "）須等於每隊人數減 1（" + (in.teamSize() - 1) + "）");
    }

    private Instant parseDeadline(String s) {
        try {
            if (s.length() == 10) return LocalDate.parse(s).atTime(23, 59).atZone(TZ).toInstant();
            if (s.endsWith("Z") || s.contains("+")) return OffsetDateTime.parse(s).toInstant();
            return java.time.LocalDateTime.parse(s).atZone(TZ).toInstant();
        } catch (Exception e) { throw ApiException.badRequest("申請截止日格式錯誤"); }
    }

    private Map<String, Object> owned(int caseId, int uid) {
        var c = db.required("SELECT id, owner_id, status, title, type, start_date, end_date, apply_deadline FROM cases WHERE id = :id", "找不到案件", "id", caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有發案方可以執行此操作");
        return c;
    }

    // ---------- 同一場比賽一人一隊（D69） ----------
    /** 先給清楚的訊息；真正的保證在 case_members 的部分唯一索引 uq_member_competition */
    void assertNotInCompetition(int userId, Integer competitionId, Integer exceptCaseId) {
        if (competitionId == null) return;
        var other = db.one("""
                SELECT c.title FROM case_members m JOIN cases c ON c.id = m.case_id
                WHERE m.user_id = :u AND m.competition_id = :comp AND m.active AND (cast(:x AS int) IS NULL OR m.case_id <> :x) LIMIT 1""",
                "u", userId, "comp", competitionId, "x", exceptCaseId);
        if (other != null) throw ApiException.conflict("ALREADY_IN_COMPETITION", "同一場比賽只能參加一隊：已經在「" + other.get("title") + "」");
    }

    /** 加入成員；同一場比賽已有另一隊時由唯一索引擋下 */
    void addMember(int caseId, int userId, Integer roleId, boolean owner, Integer competitionId) {
        try {
            db.exec("""
                    INSERT INTO case_members (case_id, user_id, case_role_id, is_owner, joined_at, competition_id, active)
                    VALUES (:c, :u, :r, :o, :t, :comp, TRUE)""",
                    "c", caseId, "u", userId, "r", roleId, "o", owner, "t", Db.ts(clock.instant()), "comp", competitionId);
        } catch (DuplicateKeyException e) {
            throw ApiException.conflict("ALREADY_IN_COMPETITION", "同一場比賽只能參加一隊");
        }
    }

    /** 隊伍開始招募（開隊，或舊流程的發布）。即時通訊在這裡接上：建立隊伍群組。 */
    void opened(int caseId, int ownerId, String title) {
        // 由 M3 的事件接手
    }

    /** 隊伍取消、過期、結束後，成員資格不再計入「同一場比賽一人一隊」 */
    void releaseMembers(int caseId) { db.exec("UPDATE case_members SET active = FALSE WHERE case_id = :c", "c", caseId); }

    // ---------- 狀態轉移 ----------
    @Transactional
    public Map<String, Object> publish(int caseId, int uid) {
        var c = owned(caseId, uid);
        if (!"DRAFT".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "只有草稿可以發布");
        if (Db.instant(c.get("apply_deadline")).isBefore(clock.instant())) throw ApiException.badRequest("申請截止日必須晚於現在");
        int max = param("max_open_cases", 0);
        if (max > 0 && db.count("SELECT count(*) FROM cases WHERE owner_id = :u AND status = 'OPEN'", "u", uid) >= max)
            throw ApiException.conflict("LIMIT", "同時開放的案件已達上限 " + max + " 件");
        db.exec("UPDATE cases SET status = 'OPEN' WHERE id = :id", "id", caseId);
        notify.log(uid, "case", caseId, "PUBLISH", null);
        opened(caseId, uid, (String) c.get("title"));
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> cancel(int caseId, int uid) {
        var c = owned(caseId, uid);
        if (!Set.of("DRAFT", "OPEN", "FORMED").contains((String) c.get("status"))) throw ApiException.conflict("INVALID_STATE", "此狀態不能取消");
        db.exec("UPDATE cases SET status = 'CANCELLED' WHERE id = :id", "id", caseId);
        releaseMembers(caseId);
        for (var e : db.list("SELECT e.id, e.user_id, e.direction FROM engagements e JOIN case_roles r ON r.id = e.case_role_id WHERE r.case_id = :c AND e.status = 'PENDING'", "c", caseId)) {
            db.exec("UPDATE engagements SET status = 'DECLINED', decided_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", e.get("id"));
            notify.notify(Db.i(e.get("user_id")), "CASE_CANCELLED", "案件已取消", "「" + c.get("title") + "」已由發案方取消", "/cases/" + caseId);
        }
        for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c AND NOT is_owner", "c", caseId))
            notify.notify(Db.i(m.get("user_id")), "CASE_CANCELLED", "案件已取消", "「" + c.get("title") + "」已由發案方取消", "/cases/" + caseId);
        notify.log(uid, "case", caseId, "CANCEL", null);
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> start(int caseId, int uid) {
        var c = owned(caseId, uid);
        if (!"FORMED".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "成案後才能開始執行");
        db.exec("UPDATE cases SET status = 'IN_PROGRESS' WHERE id = :id", "id", caseId);
        notify.log(uid, "case", caseId, "START", null);
        return detail(caseId, uid, false);
    }

    // ---------- 查詢 ----------
    public List<Map<String, Object>> list(int uid, String status, String type, Integer skillId, String q, boolean mine, boolean member) {
        return db.list("""
                SELECT c.id, c.title, c.type, c.status, c.team_size "teamSize", c.apply_deadline "applyDeadline", c.start_date "startDate", c.end_date "endDate",
                       c.attribution, c.created_at "createdAt", c.close_result "closeResult",
                       u.id "ownerId", u.name "ownerName", d.name "ownerDepartment", col.name "ownerCollege",
                       (SELECT coalesce(sum(headcount), 0) FROM case_roles r WHERE r.case_id = c.id) headcount,
                       (SELECT coalesce(sum(filled_count), 0) FROM case_roles r WHERE r.case_id = c.id) filled,
                       (SELECT string_agg(DISTINCT s.name, '、') FROM case_roles r JOIN case_role_skills rs ON rs.case_role_id = r.id JOIN skills s ON s.id = rs.skill_id WHERE r.case_id = c.id) "skillNames",
                       (SELECT string_agg(r.role_name, '、') FROM case_roles r WHERE r.case_id = c.id) "roleNames",
                       (SELECT count(*) FROM engagements e JOIN case_roles r ON r.id = e.case_role_id WHERE r.case_id = c.id AND e.status = 'PENDING' AND e.direction = 'APPLY') "pendingApplications",
                       EXISTS (SELECT 1 FROM case_members m WHERE m.case_id = c.id AND m.user_id = :uid) "isMember"
                FROM cases c JOIN users u ON u.id = c.owner_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                WHERE (cast(:status AS text) IS NULL OR c.status = :status)
                  AND (cast(:type AS text) IS NULL OR c.type = :type)
                  AND (cast(:q AS text) IS NULL OR c.title ILIKE '%' || :q || '%' OR c.description ILIKE '%' || :q || '%')
                  AND (NOT :mine OR c.owner_id = :uid)
                  AND (NOT :member OR EXISTS (SELECT 1 FROM case_members m WHERE m.case_id = c.id AND m.user_id = :uid))
                  AND (cast(:skill AS int) IS NULL OR EXISTS (SELECT 1 FROM case_roles r JOIN case_role_skills rs ON rs.case_role_id = r.id WHERE r.case_id = c.id AND rs.skill_id = :skill))
                  AND (c.status <> 'DRAFT' OR c.owner_id = :uid)
                ORDER BY CASE c.status WHEN 'OPEN' THEN 0 WHEN 'FORMED' THEN 1 WHEN 'IN_PROGRESS' THEN 2 WHEN 'CLOSING' THEN 3 WHEN 'DRAFT' THEN 4 ELSE 5 END, c.created_at DESC""",
                "uid", uid, "status", status, "type", type, "q", q == null || q.isBlank() ? null : q.trim(), "mine", mine, "member", member, "skill", skillId);
    }

    public Map<String, Object> detail(int caseId, int uid, boolean isAdmin) {
        var c = db.required("""
                SELECT c.id, c.title, c.type, c.description, c.status, c.team_size "teamSize", c.apply_deadline "applyDeadline", c.start_date "startDate", c.end_date "endDate",
                       c.attribution, c.close_result "closeResult", c.created_at "createdAt", c.closed_at "closedAt",
                       u.id "ownerId", u.name "ownerName", d.name "ownerDepartment", col.name "ownerCollege",
                       c.competition_id "competitionId", coalesce(nullif(cp.short_name, ''), cp.name) "competitionName", cp.url "competitionUrl", cp.apply_deadline "competitionDeadline",
                       cp.event_date "competitionEventDate", cp.team_min "competitionTeamMin", cp.team_max "competitionTeamMax", cp.advisor_required "competitionAdvisorRequired",
                       cp.category "competitionCategory", cp.checked_at "competitionCheckedAt",
                       c.registered_at "registeredAt", c.roster_locked "rosterLocked",
                       c.advisor_teacher_id "advisorTeacherId", t.name "advisorName", t.title "advisorTitle", td.name "advisorDepartment"
                FROM cases c JOIN users u ON u.id = c.owner_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                LEFT JOIN competitions cp ON cp.id = c.competition_id LEFT JOIN teachers t ON t.id = c.advisor_teacher_id LEFT JOIN departments td ON td.id = t.department_id
                WHERE c.id = :id""", "找不到案件", "id", caseId);
        boolean isOwner = Db.i(c.get("ownerId")) == uid;
        if ("DRAFT".equals(c.get("status")) && !isOwner && !isAdmin) throw ApiException.notFound("找不到案件");
        Map<String, Object> m = new LinkedHashMap<>(c);
        m.put("isOwner", isOwner);
        if (c.get("competitionDeadline") != null)
            m.put("daysLeft", (int) java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(clock), ((java.sql.Date) c.get("competitionDeadline")).toLocalDate()));
        List<Map<String, Object>> roles = db.list("""
                SELECT r.id, r.role_name "roleName", r.headcount, r.filled_count "filledCount", r.hours_per_week "hoursPerWeek",
                       (SELECT count(*) FROM engagements e WHERE e.case_role_id = r.id AND e.direction = 'INVITE' AND e.status = 'PENDING') "pendingInvites",
                       (SELECT count(*) FROM engagements e WHERE e.case_role_id = r.id AND e.direction = 'APPLY' AND e.status = 'PENDING') "pendingApplications"
                FROM case_roles r WHERE r.case_id = :c ORDER BY r.id""", "c", caseId);
        for (var r : roles) {
            r.put("skills", db.list("SELECT rs.skill_id \"skillId\", s.name, s.category, rs.min_level \"minLevel\", rs.is_required \"isRequired\" FROM case_role_skills rs JOIN skills s ON s.id = rs.skill_id WHERE rs.case_role_id = :r ORDER BY rs.is_required DESC, s.name", "r", r.get("id")));
            r.put("invitable", Math.max(0, Db.i(r.get("headcount")) - Db.i(r.get("filledCount")) - Db.i(r.get("pendingInvites"))));
        }
        m.put("roles", roles);
        m.put("members", db.list("""
                SELECT m.user_id "userId", u.name, d.name department, col.name college, u.degree, u.year, m.is_owner "isOwner", r.role_name "roleName", m.joined_at "joinedAt"
                FROM case_members m JOIN users u ON u.id = m.user_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                LEFT JOIN case_roles r ON r.id = m.case_role_id WHERE m.case_id = :c ORDER BY m.is_owner DESC, m.joined_at""", "c", caseId));
        m.put("isMember", db.count("SELECT count(*) FROM case_members WHERE case_id = :c AND user_id = :u", "c", caseId, "u", uid) > 0);
        m.put("myEngagements", db.list("""
                SELECT e.id, e.case_role_id "roleId", r.role_name "roleName", e.direction, e.status, e.due_at "dueAt", e.score_snapshot "score", e.created_at "createdAt"
                FROM engagements e JOIN case_roles r ON r.id = e.case_role_id WHERE r.case_id = :c AND e.user_id = :u ORDER BY e.created_at DESC""", "c", caseId, "u", uid));
        if (isOwner || isAdmin) m.put("engagements", engagementsOfCase(caseId));
        var cr = db.one("SELECT id, result, auto, status, requested_at \"requestedAt\", due_at \"dueAt\" FROM close_requests WHERE case_id = :c ORDER BY id DESC LIMIT 1", "c", caseId);
        if (cr != null) {
            cr.put("votes", db.list("SELECT v.user_id \"userId\", u.name, v.agree, v.voted_at \"votedAt\" FROM close_votes v JOIN users u ON u.id = v.user_id WHERE v.close_request_id = :r", "r", cr.get("id")));
            cr.put("myVote", db.one("SELECT agree FROM close_votes WHERE close_request_id = :r AND user_id = :u", "r", cr.get("id"), "u", uid));
        }
        m.put("closeRequest", cr);
        m.put("pendingReviews", db.count("SELECT count(*) FROM reviews WHERE case_id = :c AND reviewer_id = :u AND submitted_at IS NULL AND NOT missed", "c", caseId, "u", uid));
        return m;
    }

    public List<Map<String, Object>> engagementsOfCase(int caseId) {
        return db.list("""
                SELECT e.id, e.case_role_id "roleId", r.role_name "roleName", e.direction, e.status, e.message, e.score_snapshot "score",
                       e.due_at "dueAt", e.created_at "createdAt", e.decided_at "decidedAt",
                       u.id "userId", u.name, d.name department, col.name college, u.degree, u.year
                FROM engagements e JOIN case_roles r ON r.id = e.case_role_id JOIN users u ON u.id = e.user_id
                JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                WHERE r.case_id = :c ORDER BY e.status = 'PENDING' DESC, e.created_at DESC""", "c", caseId);
    }

    /** 我的申請與收到的邀請（我是加入方） */
    public List<Map<String, Object>> myEngagements(int uid) {
        return db.list("""
                SELECT e.id, e.direction, e.status, e.message, e.score_snapshot "score", e.due_at "dueAt", e.created_at "createdAt", e.decided_at "decidedAt",
                       r.id "roleId", r.role_name "roleName", c.id "caseId", c.title "caseTitle", c.type "caseType", c.status "caseStatus",
                       o.name "ownerName", d.name "ownerDepartment"
                FROM engagements e JOIN case_roles r ON r.id = e.case_role_id JOIN cases c ON c.id = r.case_id
                JOIN users o ON o.id = c.owner_id JOIN departments d ON d.id = o.department_id
                WHERE e.user_id = :u ORDER BY e.status = 'PENDING' DESC, e.created_at DESC""", "u", uid);
    }

    // ---------- 申請 / 邀請（D17、D19、D20、D25） ----------
    public record EngagementIn(String direction, Integer userId, String message) {}

    @Transactional
    public Map<String, Object> createEngagement(int roleId, int actorId, EngagementIn in) {
        var role = db.required("""
                SELECT r.id, r.case_id, r.headcount, r.filled_count, c.owner_id, c.status, c.title, c.apply_deadline, c.competition_id, c.roster_locked
                FROM case_roles r JOIN cases c ON c.id = r.case_id WHERE r.id = :id FOR UPDATE OF r""", "找不到角色", "id", roleId);
        int caseId = Db.i(role.get("case_id")), ownerId = Db.i(role.get("owner_id"));
        if (!"OPEN".equals(role.get("status"))) throw ApiException.conflict("INVALID_STATE", "案件不在招募中");
        boolean invite = "INVITE".equals(in.direction());
        int joiner;
        if (invite) {
            if (actorId != ownerId) throw ApiException.forbidden("只有發案方可以邀請");
            if (in.userId() == null) throw ApiException.badRequest("邀請需指定 userId");
            joiner = in.userId();
            int pendingInvites = db.count("SELECT count(*) FROM engagements WHERE case_role_id = :r AND direction = 'INVITE' AND status = 'PENDING'", "r", roleId);
            int invitable = Db.i(role.get("headcount")) - Db.i(role.get("filled_count")) - pendingInvites;
            if (invitable <= 0) throw ApiException.conflict("NO_SEAT", "此角色的可邀請名額已用完（名額 − 已加入 − 待處理邀請 = 0）");
        } else {
            if (!"APPLY".equals(in.direction())) throw ApiException.badRequest("direction 須為 APPLY 或 INVITE");
            joiner = actorId;
            int maxPending = param("max_pending_applications", 0);
            if (maxPending > 0 && db.count("SELECT count(*) FROM engagements WHERE user_id = :u AND direction = 'APPLY' AND status = 'PENDING'", "u", joiner) >= maxPending)
                throw ApiException.conflict("LIMIT", "待處理的申請已達上限 " + maxPending + " 筆");
        }
        RankingEngine.Result r = ranking.evaluateOne(roleId, joiner);
        if (!r.passed()) throw ApiException.blocked(invite ? "這位同學目前不符合條件，無法邀請" : "目前不符合這支隊伍的條件，無法申請", r.blockedBy());
        if (role.get("competition_id") != null) {
            try { assertNotInCompetition(joiner, Db.i(role.get("competition_id")), caseId); }
            catch (ApiException ex) { throw ApiException.blocked(invite ? "這位同學已經在這場比賽的另一支隊伍" : "你已經在這場比賽的另一支隊伍", List.of(ex.getMessage())); }
        }

        Instant now = clock.instant();
        Instant due = now.plusSeconds(param("response_hours", 72) * 3600L);
        Instant deadline = Db.instant(role.get("apply_deadline"));
        if (deadline.isBefore(due)) due = deadline;
        int id = db.insertReturningId("""
                INSERT INTO engagements (case_role_id, user_id, direction, status, message, score_snapshot, due_at, created_at)
                VALUES (:r, :u, :d, 'PENDING', :m, :s, :due, :now) RETURNING id""",
                "r", roleId, "u", joiner, "d", in.direction(), "m", in.message() == null ? "" : in.message(), "s", r.score(), "due", Db.ts(due), "now", Db.ts(now));
        String title = (String) role.get("title");
        if (invite) notify.notify(joiner, "INVITE", "收到組隊邀請", "「" + title + "」邀請你加入，請在期限內回覆", "/cases/" + caseId);
        else notify.notify(ownerId, "APPLY", "收到新申請", "有人申請加入「" + title + "」，請在期限內審核", "/cases/" + caseId);
        // 建立時若距到期已不足提醒時數，立即提醒（D24）
        if (due.minusSeconds(param("reminder_hours", 24) * 3600L).isBefore(now)) remind(id, invite ? joiner : ownerId, title, caseId);
        notify.log(actorId, "engagement", id, in.direction(), "{\"score\":" + r.score() + "}");
        return Map.of("id", id, "status", "PENDING", "dueAt", due.toString(), "score", r.score(), "reasons", r.reasons());
    }

    void remind(int engagementId, int responderId, String caseTitle, int caseId) {
        notify.notify(responderId, "REMINDER", "待回覆即將到期", "「" + caseTitle + "」的申請／邀請將在 24 小時內到期，逾時自動視為放棄", "/cases/" + caseId);
        db.exec("UPDATE engagements SET reminded_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
    }

    private Map<String, Object> engagement(int id) {
        return db.required("""
                SELECT e.id, e.case_role_id, e.user_id, e.direction, e.status, r.case_id, r.headcount, r.filled_count, c.owner_id, c.status case_status, c.title,
                       c.competition_id, c.roster_locked
                FROM engagements e JOIN case_roles r ON r.id = e.case_role_id JOIN cases c ON c.id = r.case_id WHERE e.id = :id FOR UPDATE OF e, r""", "找不到申請或邀請", "id", id);
    }

    private static int responder(Map<String, Object> e) { return "INVITE".equals(e.get("direction")) ? Db.i(e.get("user_id")) : Db.i(e.get("owner_id")); }
    private static int initiator(Map<String, Object> e) { return "INVITE".equals(e.get("direction")) ? Db.i(e.get("owner_id")) : Db.i(e.get("user_id")); }

    /** 對方同意：APPLY 由發案方核准，INVITE 由被邀請者接受；名額在鎖內檢查 */
    @Transactional
    public Map<String, Object> accept(int engagementId, int uid) {
        var e = engagement(engagementId);
        if (responder(e) != uid) throw ApiException.forbidden("你不是這筆申請／邀請的確認方");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "此筆已不是待處理狀態");
        if (!"OPEN".equals(e.get("case_status"))) throw ApiException.conflict("INVALID_STATE", "案件已不在招募中");
        int caseId = Db.i(e.get("case_id")), roleId = Db.i(e.get("case_role_id")), joiner = Db.i(e.get("user_id"));
        Instant now = clock.instant();
        if (Db.i(e.get("filled_count")) >= Db.i(e.get("headcount"))) {
            db.exec("UPDATE engagements SET status = 'FULL', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", engagementId);
            throw ApiException.conflict("NO_SEAT", "名額已滿");
        }
        if (db.count("SELECT count(*) FROM case_members WHERE case_id = :c AND user_id = :u", "c", caseId, "u", joiner) > 0)
            throw ApiException.conflict("ALREADY_MEMBER", "此人已是成員");
        Integer competitionId = e.get("competition_id") == null ? null : Db.i(e.get("competition_id"));
        assertNotInCompetition(joiner, competitionId, caseId);
        db.exec("UPDATE engagements SET status = 'ACCEPTED', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", engagementId);
        db.exec("UPDATE case_roles SET filled_count = filled_count + 1 WHERE id = :r", "r", roleId);
        addMember(caseId, joiner, roleId, false, competitionId);
        String title = (String) e.get("title");
        notify.notify(initiator(e), "ACCEPTED", "申請／邀請已成立", "你與「" + title + "」的組隊已成立", "/cases/" + caseId);
        // 角色額滿：其他待處理者以「額滿」結束
        int filled = Db.i(e.get("filled_count")) + 1;
        if (filled >= Db.i(e.get("headcount"))) {
            for (var o : db.list("SELECT id, user_id, direction FROM engagements WHERE case_role_id = :r AND status = 'PENDING'", "r", roleId)) {
                db.exec("UPDATE engagements SET status = 'FULL', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", o.get("id"));
                notify.notify(Db.i(o.get("user_id")), "FULL", "名額已滿", "「" + title + "」的該角色名額已滿", "/cases/" + caseId);
            }
        }
        // 全部角色額滿 → 自動成案
        if (db.count("SELECT count(*) FROM case_roles WHERE case_id = :c AND filled_count < headcount", "c", caseId) == 0) {
            db.exec("UPDATE cases SET status = 'FORMED' WHERE id = :c", "c", caseId);
            for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId))
                notify.notify(Db.i(m.get("user_id")), "FORMED", "成案了", "「" + title + "」所有角色已到齊，正式成案", "/cases/" + caseId);
            notify.log(uid, "case", caseId, "FORMED", null);
        }
        notify.log(uid, "engagement", engagementId, "ACCEPT", null);
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> decline(int engagementId, int uid) {
        var e = engagement(engagementId);
        if (responder(e) != uid) throw ApiException.forbidden("你不是這筆申請／邀請的確認方");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "此筆已不是待處理狀態");
        db.exec("UPDATE engagements SET status = 'DECLINED', decided_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
        int caseId = Db.i(e.get("case_id"));
        notify.notify(initiator(e), "DECLINED", "對方已拒絕", "「" + e.get("title") + "」的申請／邀請未被接受", "/cases/" + caseId);
        notify.log(uid, "engagement", engagementId, "DECLINE", null);
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> withdraw(int engagementId, int uid) {
        var e = engagement(engagementId);
        if (initiator(e) != uid) throw ApiException.forbidden("只有發起方可以撤回");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "此筆已不是待處理狀態");
        db.exec("UPDATE engagements SET status = 'WITHDRAWN', decided_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
        notify.log(uid, "engagement", engagementId, "WITHDRAW", null);
        return detail(Db.i(e.get("case_id")), uid, false);
    }

    // ---------- 排程呼叫（D21、D24） ----------
    @Transactional
    public int remindDue() {
        int hours = param("reminder_hours", 24);
        var rows = db.list("""
                SELECT e.id, e.direction, e.user_id, c.owner_id, c.title, c.id case_id FROM engagements e
                JOIN case_roles r ON r.id = e.case_role_id JOIN cases c ON c.id = r.case_id
                WHERE e.status = 'PENDING' AND e.reminded_at IS NULL AND e.due_at <= :t""", "t", Db.ts(clock.instant().plusSeconds(hours * 3600L)));
        for (var e : rows) remind(Db.i(e.get("id")), responder(e), (String) e.get("title"), Db.i(e.get("case_id")));
        return rows.size();
    }

    @Transactional
    public int expireDue() {
        Instant now = clock.instant();
        var rows = db.list("""
                SELECT e.id, e.direction, e.user_id, c.owner_id, c.title, c.id case_id FROM engagements e
                JOIN case_roles r ON r.id = e.case_role_id JOIN cases c ON c.id = r.case_id
                WHERE e.status = 'PENDING' AND e.due_at <= :t""", "t", Db.ts(now));
        for (var e : rows) {
            db.exec("UPDATE engagements SET status = 'EXPIRED', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", e.get("id"));
            int caseId = Db.i(e.get("case_id"));
            notify.notify(responder(e), "EXPIRED", "逾時未回覆，已自動放棄", "「" + e.get("title") + "」的申請／邀請已逾期，計入回應率", "/cases/" + caseId);
            notify.notify(initiator(e), "EXPIRED", "對方逾時未回覆", "「" + e.get("title") + "」的申請／邀請已逾期，名額已釋放", "/cases/" + caseId);
            notify.log(null, "engagement", Db.i(e.get("id")), "EXPIRE", null);
        }
        // 招募截止仍未成案 → EXPIRED
        for (var c : db.list("SELECT id, title FROM cases WHERE status = 'OPEN' AND apply_deadline <= :t", "t", Db.ts(now))) {
            db.exec("UPDATE cases SET status = 'EXPIRED' WHERE id = :id", "id", c.get("id"));
            releaseMembers(Db.i(c.get("id")));
            for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", c.get("id")))
                notify.notify(Db.i(m.get("user_id")), "CASE_EXPIRED", "案件招募截止未成案", "「" + c.get("title") + "」在截止日前未湊齊成員", "/cases/" + c.get("id"));
        }
        return rows.size();
    }
}
