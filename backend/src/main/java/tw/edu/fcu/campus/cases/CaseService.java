package tw.edu.fcu.campus.cases;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.common.events.TeamEvents.*;
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
 * 隊伍狀態：OPEN 招募中 → FORMED 已成隊 → IN_PROGRESS 已報名 → CLOSED 已結束；OPEN 可 EXPIRED（截止未成隊）；OPEN、FORMED 可 CANCELLED（解散）。
 * DRAFT、CLOSING 是 2.0 的完整表單與結案投票留下來的狀態，3.1 的畫面不會產生。
 * 申請與邀請共用 engagements（D17），名額在同一交易內以 FOR UPDATE 鎖定（D25）。
 * 流程上發生的事以事件發布（{@link tw.edu.fcu.campus.common.events.TeamEvents}），即時通訊在同一筆交易內接手。
 */
@Service
public class CaseService {
    private final Db db;
    private final DemoClock clock;
    private final NotificationService notify;
    private final RankingService ranking;
    private final ApplicationEventPublisher events;
    private static final ZoneId TZ = ZoneId.of("Asia/Taipei");

    public CaseService(Db db, DemoClock clock, NotificationService notify, RankingService ranking, ApplicationEventPublisher events) {
        this.db = db; this.clock = clock; this.notify = notify; this.ranking = ranking; this.events = events;
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
        var c = db.required("SELECT id, owner_id, status, title, type, start_date, end_date, apply_deadline FROM cases WHERE id = :id FOR UPDATE", "找不到隊伍", "id", caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有隊長可以這樣做");
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
    void opened(int caseId, int ownerId, String title) { events.publishEvent(new TeamOpened(caseId, ownerId, title)); }

    /** 隊伍解散、截止、結束後，成員資格不再計入「同一場比賽一人一隊」 */
    public void releaseMembers(int caseId) { db.exec("UPDATE case_members SET active = FALSE WHERE case_id = :c", "c", caseId); }

    /**
     * 把這支隊伍還在等回覆的申請與邀請全部結束（解散、提前成隊、標記報名、截止時用）。
     * status 寫進 engagements；reason 給對話的系統訊息用（TEAM_ENDED 隊伍停止招募、FULL 隊伍已成隊）。
     */
    void closePending(int caseId, int ownerId, String title, String status, String reason) {
        boolean ended = "TEAM_ENDED".equals(reason);
        for (var e : db.list("""
                SELECT e.id, e.user_id, e.direction FROM engagements e JOIN case_roles r ON r.id = e.case_role_id
                WHERE r.case_id = :c AND e.status = 'PENDING' ORDER BY e.id FOR UPDATE OF e""", "c", caseId)) {
            int id = Db.i(e.get("id")), joiner = Db.i(e.get("user_id"));
            db.exec("UPDATE engagements SET status = :s, decided_at = :t WHERE id = :id", "s", status, "t", Db.ts(clock.instant()), "id", id);
            notify.notify(joiner, ended ? "CASE_CANCELLED" : "FULL", ended ? "隊伍已停止招募" : "隊伍已經成隊",
                    "「" + title + "」" + (ended ? "已停止招募" : "已經成隊，不再收人") + "，你的" + ("INVITE".equals(e.get("direction")) ? "邀請" : "申請") + "已結束", "/messages?e=" + id);
            events.publishEvent(new EngagementClosed(id, caseId, joiner, ownerId, (String) e.get("direction"), reason, null, title));
        }
    }

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
        String status = (String) c.get("status"), title = (String) c.get("title");
        if (!Set.of("DRAFT", "OPEN", "FORMED").contains(status)) throw ApiException.conflict("INVALID_STATE", "隊伍已經報名或已經結束，不能解散");
        db.exec("UPDATE cases SET status = 'CANCELLED' WHERE id = :id", "id", caseId);
        releaseMembers(caseId);
        closePending(caseId, uid, title, "DECLINED", "TEAM_ENDED");
        for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c AND NOT is_owner", "c", caseId))
            notify.notify(Db.i(m.get("user_id")), "CASE_CANCELLED", "隊伍已解散", "「" + title + "」已由隊長解散", "/cases/" + caseId);
        if (!"DRAFT".equals(status)) events.publishEvent(new TeamEnded(caseId, "CANCELLED", title));
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
                WHERE c.id = :id""", "找不到隊伍", "id", caseId);
        boolean isOwner = Db.i(c.get("ownerId")) == uid;
        if ("DRAFT".equals(c.get("status")) && !isOwner && !isAdmin) throw ApiException.notFound("找不到隊伍");
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
        m.put("need", roles.stream().mapToInt(r -> Db.i(r.get("headcount")) - Db.i(r.get("filledCount"))).sum());
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

    /**
     * 鎖的順序固定：先隊伍列，再缺口與申請列，最後才是對話列。
     * 隊伍層級的寫入（申請、接受、解散、成隊、退出、標記報名、排程）都照這個順序，兩個請求同時進來不會互相卡死。
     */
    private void lockTeamOfRole(int roleId) {
        db.one("SELECT id FROM cases WHERE id = (SELECT case_id FROM case_roles WHERE id = :r) FOR UPDATE", "r", roleId);
    }

    private void lockTeamOfEngagement(int engagementId) {
        db.one("SELECT id FROM cases WHERE id = (SELECT r.case_id FROM engagements e JOIN case_roles r ON r.id = e.case_role_id WHERE e.id = :e) FOR UPDATE", "e", engagementId);
    }

    @Transactional
    public Map<String, Object> createEngagement(int roleId, int actorId, EngagementIn in) {
        lockTeamOfRole(roleId);
        var role = db.required("""
                SELECT r.id, r.case_id, r.headcount, r.filled_count, c.owner_id, c.status, c.title, c.apply_deadline, c.competition_id, c.roster_locked
                FROM case_roles r JOIN cases c ON c.id = r.case_id WHERE r.id = :id FOR UPDATE OF r""", "找不到隊伍", "id", roleId);
        int caseId = Db.i(role.get("case_id")), ownerId = Db.i(role.get("owner_id"));
        if (!"OPEN".equals(role.get("status"))) throw ApiException.conflict("INVALID_STATE", "這支隊伍已經不在招募");
        if (in.message() != null && in.message().length() > 300) throw ApiException.badRequest("附的那句話最多 300 個字");
        boolean invite = "INVITE".equals(in.direction());
        int joiner;
        if (invite) {
            if (actorId != ownerId) throw ApiException.forbidden("只有隊長可以邀請");
            if (in.userId() == null) throw ApiException.badRequest("邀請需指定 userId");
            joiner = in.userId();
            int pendingInvites = db.count("SELECT count(*) FROM engagements WHERE case_role_id = :r AND direction = 'INVITE' AND status = 'PENDING'", "r", roleId);
            int invitable = Db.i(role.get("headcount")) - Db.i(role.get("filled_count")) - pendingInvites;
            if (invitable <= 0) throw ApiException.conflict("NO_SEAT", "可以邀請的名額用完了（還在等回覆的邀請也算名額）");
        } else {
            if (!"APPLY".equals(in.direction())) throw ApiException.badRequest("direction 須為 APPLY 或 INVITE");
            joiner = actorId;
            int maxPending = param("max_pending_applications", 0);
            if (maxPending > 0 && db.count("SELECT count(*) FROM engagements WHERE user_id = :u AND direction = 'APPLY' AND status = 'PENDING'", "u", joiner) >= maxPending)
                throw ApiException.conflict("LIMIT", "等待回覆的申請已經有 " + maxPending + " 筆，先等對方回覆，或取消其中一筆");
        }
        RankingEngine.Result r = ranking.evaluateOne(roleId, joiner);
        if (!r.passed()) throw ApiException.blocked(invite ? "這位同學目前不符合條件，無法邀請" : "目前不符合這支隊伍的條件，無法申請", TeamService.plain(r.blockedBy(), invite));
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
                "r", roleId, "u", joiner, "d", in.direction(), "m", in.message() == null ? "" : in.message().strip(), "s", r.score(), "due", Db.ts(due), "now", Db.ts(now));
        String title = (String) role.get("title");
        if (invite) notify.notify(joiner, "INVITE", "收到組隊邀請", "「" + title + "」邀請你加入。可以先聊聊，再決定要不要接受", "/messages?e=" + id);
        else notify.notify(ownerId, "APPLY", "有人想加入你的隊伍", "有同學申請加入「" + title + "」。可以先聊聊，再決定要不要接受", "/messages?e=" + id);
        // 即時通訊在同一筆交易內建立洽談對話；附的那句話成為對話的第一則訊息
        events.publishEvent(new EngagementCreated(id, caseId, joiner, ownerId, in.direction(), in.message(), title));
        // 建立時若距到期已不足提醒時數，立即提醒（D24）
        if (due.minusSeconds(param("reminder_hours", 24) * 3600L).isBefore(now)) remind(id, invite ? joiner : ownerId, title, caseId);
        notify.log(actorId, "engagement", id, in.direction(), "{\"score\":" + r.score() + "}");
        return Map.of("id", id, "caseId", caseId, "status", "PENDING", "dueAt", due.toString(), "score", r.score(), "reasons", r.reasons());
    }

    void remind(int engagementId, int responderId, String caseTitle, int caseId) {
        notify.notify(responderId, "REMINDER", "有一筆在等你回覆", "「" + caseTitle + "」的申請或邀請快到期了，逾時會自動失效", "/messages?e=" + engagementId);
        db.exec("UPDATE engagements SET reminded_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
    }

    private Map<String, Object> engagement(int id) {
        lockTeamOfEngagement(id);
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
        if (responder(e) != uid) throw ApiException.forbidden("這一筆不是由你回覆");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "這一筆已經處理過了");
        if (!"OPEN".equals(e.get("case_status"))) throw ApiException.conflict("INVALID_STATE", "這支隊伍已經不在招募");
        int caseId = Db.i(e.get("case_id")), roleId = Db.i(e.get("case_role_id")), joiner = Db.i(e.get("user_id"));
        Instant now = clock.instant();
        if (Db.i(e.get("filled_count")) >= Db.i(e.get("headcount"))) {
            db.exec("UPDATE engagements SET status = 'FULL', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", engagementId);
            throw ApiException.conflict("NO_SEAT", "名額已滿");
        }
        if (db.count("SELECT count(*) FROM case_members WHERE case_id = :c AND user_id = :u", "c", caseId, "u", joiner) > 0)
            throw ApiException.conflict("ALREADY_MEMBER", "這位同學已經是隊友");
        Integer competitionId = e.get("competition_id") == null ? null : Db.i(e.get("competition_id"));
        assertNotInCompetition(joiner, competitionId, caseId);
        db.exec("UPDATE engagements SET status = 'ACCEPTED', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", engagementId);
        db.exec("UPDATE case_roles SET filled_count = filled_count + 1 WHERE id = :r", "r", roleId);
        addMember(caseId, joiner, roleId, false, competitionId);
        String title = (String) e.get("title");
        int ownerId = Db.i(e.get("owner_id"));
        notify.notify(initiator(e), "ACCEPTED", "成為隊友了", "你和「" + title + "」的組隊成立了，可以到隊伍群組討論", "/cases/" + caseId);
        events.publishEvent(new EngagementAccepted(engagementId, caseId, joiner, ownerId, (String) e.get("direction"), uid, title));
        // 這個缺口收滿了：其他還在等回覆的以「額滿」結束
        int filled = Db.i(e.get("filled_count")) + 1;
        if (filled >= Db.i(e.get("headcount"))) {
            for (var o : db.list("SELECT id, user_id, direction FROM engagements WHERE case_role_id = :r AND status = 'PENDING' ORDER BY id FOR UPDATE", "r", roleId)) {
                db.exec("UPDATE engagements SET status = 'FULL', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", o.get("id"));
                notify.notify(Db.i(o.get("user_id")), "FULL", "名額已滿", "「" + title + "」已經收滿人", "/messages?e=" + o.get("id"));
                events.publishEvent(new EngagementClosed(Db.i(o.get("id")), caseId, Db.i(o.get("user_id")), ownerId, (String) o.get("direction"), "FULL", null, title));
            }
        }
        // 全部缺口收滿 → 自動成隊
        if (db.count("SELECT count(*) FROM case_roles WHERE case_id = :c AND filled_count < headcount", "c", caseId) == 0) {
            db.exec("UPDATE cases SET status = 'FORMED' WHERE id = :c", "c", caseId);
            for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId))
                notify.notify(Db.i(m.get("user_id")), "FORMED", "成隊了", "「" + title + "」人到齊了。下一步：到比賽官網完成報名", "/cases/" + caseId);
            events.publishEvent(new TeamFormed(caseId, title, false, false, null));
            notify.log(uid, "case", caseId, "FORMED", null);
        }
        notify.log(uid, "engagement", engagementId, "ACCEPT", null);
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> decline(int engagementId, int uid) {
        var e = engagement(engagementId);
        if (responder(e) != uid) throw ApiException.forbidden("這一筆不是由你回覆");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "這一筆已經處理過了");
        db.exec("UPDATE engagements SET status = 'DECLINED', decided_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
        int caseId = Db.i(e.get("case_id"));
        String what = "INVITE".equals(e.get("direction")) ? "邀請" : "申請";
        notify.notify(initiator(e), "DECLINED", "對方婉拒了", "「" + e.get("title") + "」的" + what + "沒有成立", "/messages?e=" + engagementId);
        events.publishEvent(new EngagementClosed(engagementId, caseId, Db.i(e.get("user_id")), Db.i(e.get("owner_id")), (String) e.get("direction"), "DECLINED", uid, (String) e.get("title")));
        notify.log(uid, "engagement", engagementId, "DECLINE", null);
        return detail(caseId, uid, false);
    }

    @Transactional
    public Map<String, Object> withdraw(int engagementId, int uid) {
        var e = engagement(engagementId);
        if (initiator(e) != uid) throw ApiException.forbidden("只有送出的人可以取消");
        if (!"PENDING".equals(e.get("status"))) throw ApiException.conflict("INVALID_STATE", "這一筆已經處理過了");
        db.exec("UPDATE engagements SET status = 'WITHDRAWN', decided_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", engagementId);
        String what = "INVITE".equals(e.get("direction")) ? "邀請" : "申請";
        notify.notify(responder(e), "WITHDRAWN", "對方取消了", "「" + e.get("title") + "」的" + what + "已由對方取消", "/messages?e=" + engagementId);
        events.publishEvent(new EngagementClosed(engagementId, Db.i(e.get("case_id")), Db.i(e.get("user_id")), Db.i(e.get("owner_id")), (String) e.get("direction"), "WITHDRAWN", uid, (String) e.get("title")));
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
            int id = Db.i(e.get("id")), caseId = Db.i(e.get("case_id"));
            lockTeamOfEngagement(id);
            // 帶著狀態條件更新：排程和使用者同時動同一筆時，只會有一邊成立
            if (db.exec("UPDATE engagements SET status = 'EXPIRED', decided_at = :t WHERE id = :id AND status = 'PENDING'", "t", Db.ts(now), "id", id) == 0) continue;
            String what = "INVITE".equals(e.get("direction")) ? "邀請" : "申請";
            notify.notify(responder(e), "EXPIRED", "逾時未回覆，已自動失效", "「" + e.get("title") + "」的" + what + "超過回覆期限（會計入回應率）", "/messages?e=" + id);
            notify.notify(initiator(e), "EXPIRED", "對方逾時未回覆", "「" + e.get("title") + "」的" + what + "已失效，名額已釋放", "/messages?e=" + id);
            events.publishEvent(new EngagementClosed(id, caseId, Db.i(e.get("user_id")), Db.i(e.get("owner_id")), (String) e.get("direction"), "EXPIRED", null, (String) e.get("title")));
            notify.log(null, "engagement", id, "EXPIRE", null);
        }
        // 報名截止時還在招募的隊伍：人數夠（至少 2 人，而且達到比賽的每隊下限）就以目前名單成隊，之後照常追蹤報名；不夠的結束
        for (var c : db.list("""
                SELECT c.id, c.title, c.owner_id, (SELECT count(*) FROM case_members m WHERE m.case_id = c.id) members, coalesce(cp.team_min, 2) team_min
                FROM cases c LEFT JOIN competitions cp ON cp.id = c.competition_id
                WHERE c.status = 'OPEN' AND c.apply_deadline <= :t ORDER BY c.id FOR UPDATE OF c""", "t", Db.ts(now))) {
            int caseId = Db.i(c.get("id"));
            String title = (String) c.get("title");
            closePending(caseId, Db.i(c.get("owner_id")), title, "EXPIRED", "TEAM_ENDED");
            boolean enough = Db.i(c.get("members")) >= Math.max(2, Db.i(c.get("team_min")));
            db.exec("UPDATE cases SET status = :s WHERE id = :id", "s", enough ? "FORMED" : "EXPIRED", "id", caseId);
            if (!enough) releaseMembers(caseId);
            for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId))
                notify.notify(Db.i(m.get("user_id")), enough ? "FORMED" : "CASE_EXPIRED", enough ? "報名截止，以目前名單成隊" : "隊伍沒有在截止前成隊",
                        enough ? "「" + title + "」以目前的名單成隊。已經報名的話，請隊長按「已報名」" : "「" + title + "」在報名截止前沒有找到隊友", "/cases/" + caseId);
            events.publishEvent(enough ? new TeamFormed(caseId, title, false, true, null) : new TeamEnded(caseId, "EXPIRED", title));
            notify.log(null, "case", caseId, enough ? "FORMED_AT_DEADLINE" : "EXPIRE", null);
        }
        return rows.size();
    }
}
