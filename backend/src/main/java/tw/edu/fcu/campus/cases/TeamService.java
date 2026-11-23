package tw.edu.fcu.campus.cases;

import org.springframework.context.ApplicationEventPublisher;
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
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 3.1 的比賽隊伍：精簡的開隊表單與隊伍牆（「找隊友」頁）。
 * 資料仍存在 cases／case_roles／case_role_skills：一支隊伍一個預設缺口，名額等於「還缺幾人」。
 * 用語對照：case = 隊伍、case_role = 缺口、engagement = 申請或邀請、owner = 隊長。
 */
@Service
public class TeamService {
    private static final ZoneId TZ = ZoneId.of("Asia/Taipei");
    static final String DEFAULT_ROLE = "隊友";

    private final Db db;
    private final DemoClock clock;
    private final NotificationService notify;
    private final RankingService ranking;
    private final CaseService cases;
    private final ApplicationEventPublisher events;

    public TeamService(Db db, DemoClock clock, NotificationService notify, RankingService ranking, CaseService cases, ApplicationEventPublisher events) {
        this.db = db; this.clock = clock; this.notify = notify; this.ranking = ranking; this.cases = cases; this.events = events;
    }

    // ---------- 開隊（FR-06）：隊名、還缺幾人、想找的技能、一句話；截止日與人數上限由比賽帶入 ----------
    public record TeamSkillIn(Integer skillId, Boolean required, Integer minLevel) {}
    public record TeamIn(Integer competitionId, String title, Integer need, List<TeamSkillIn> skills, String intro) {}

    @Transactional
    public Map<String, Object> create(int uid, TeamIn in) {
        if (db.count("SELECT count(*) FROM users WHERE id = :u AND role = 'STUDENT' AND deidentified_at IS NULL", "u", uid) == 0)
            throw ApiException.forbidden("只有學生帳號可以開隊");
        if (in.competitionId() == null) throw ApiException.badRequest("請先選一場比賽");
        var comp = db.one("""
                SELECT id, coalesce(nullif(short_name, ''), name) display, apply_deadline, event_date, team_max, approved
                FROM competitions WHERE id = :id""", "id", in.competitionId());
        if (comp == null || !Boolean.TRUE.equals(comp.get("approved"))) throw ApiException.badRequest("找不到這場比賽");
        LocalDate today = LocalDate.now(clock);
        if (comp.get("apply_deadline") == null) throw ApiException.badRequest("這場比賽還沒有公告報名截止日，暫時不能開隊");
        LocalDate deadline = ((java.sql.Date) comp.get("apply_deadline")).toLocalDate();
        if (deadline.isBefore(today)) throw ApiException.conflict("COMPETITION_CLOSED", "這場比賽的報名已經截止，不能開隊");

        String title = in.title() == null ? "" : in.title().trim();
        if (title.isEmpty()) throw ApiException.badRequest("請填隊名");
        if (title.length() > 40) throw ApiException.badRequest("隊名最多 40 個字");
        String intro = in.intro() == null ? "" : in.intro().trim();
        if (intro.length() > 200) throw ApiException.badRequest("一句話介紹最多 200 個字");
        if (in.need() == null || in.need() < 1) throw ApiException.badRequest("還缺幾人至少填 1");
        Integer teamMax = comp.get("team_max") == null ? null : Db.i(comp.get("team_max"));
        if (teamMax != null && 1 + in.need() > teamMax)
            throw ApiException.badRequest(teamMax <= 1 ? "這場比賽是個人賽，不需要開隊" : "這場比賽每隊最多 " + teamMax + " 人，含你自己最多還能找 " + (teamMax - 1) + " 人");
        if (in.need() > 20) throw ApiException.badRequest("還缺幾人最多填 20");

        // 技能條件至少 1 項、從技能表選（D63）；沒勾「一定要會」的只影響排序
        if (in.skills() == null || in.skills().isEmpty()) throw ApiException.badRequest("至少選 1 項想找的技能");
        if (in.skills().size() > 6) throw ApiException.badRequest("想找的技能最多 6 項");
        Set<Integer> seen = new HashSet<>();
        for (TeamSkillIn s : in.skills()) {
            if (s.skillId() == null || !seen.add(s.skillId())) throw ApiException.badRequest("技能重複或格式錯誤");
            if (s.minLevel() != null && (s.minLevel() < 1 || s.minLevel() > 3)) throw ApiException.badRequest("最低等級須為 1 初階、2 中階、3 進階");
            if (db.count("SELECT count(*) FROM skills WHERE id = :s", "s", s.skillId()) == 0) throw ApiException.badRequest("技能表裡沒有這項技能");
        }

        cases.assertNotInCompetition(uid, in.competitionId(), null);
        int max = cases.param("max_open_cases", 0);
        if (max > 0 && db.count("SELECT count(*) FROM cases WHERE owner_id = :u AND status = 'OPEN'", "u", uid) >= max)
            throw ApiException.conflict("LIMIT", "同時招募中的隊伍已達上限 " + max + " 支");

        Instant now = clock.instant();
        // 隊伍的結束日 = 比賽日期；比賽還沒公告日期時，先抓報名截止後一段時間（可調參數），免得報名一截止群組就變唯讀
        LocalDate end = comp.get("event_date") == null ? deadline.plusDays(cases.param("team_days_without_event_date", 120)) : ((java.sql.Date) comp.get("event_date")).toLocalDate();
        if (end.isBefore(deadline)) end = deadline;
        int id = db.insertReturningId("""
                INSERT INTO cases (owner_id, title, type, description, team_size, apply_deadline, start_date, end_date, status, created_at, competition_id)
                VALUES (:o, :t, 'COMPETITION', :d, :n, :dl, :s, :e, 'OPEN', :c, :comp) RETURNING id""",
                "o", uid, "t", title, "d", intro, "n", 1 + in.need(),
                "dl", Db.ts(deadline.atTime(23, 59).atZone(TZ).toInstant()), "s", today, "e", end, "c", Db.ts(now), "comp", in.competitionId());
        cases.addMember(id, uid, null, true, in.competitionId());
        int roleId = db.insertReturningId("INSERT INTO case_roles (case_id, role_name, headcount, hours_per_week) VALUES (:c, :n, :h, :w) RETURNING id",
                "c", id, "n", DEFAULT_ROLE, "h", in.need(), "w", cases.param("default_role_hours", 4));
        for (TeamSkillIn s : in.skills())
            db.exec("INSERT INTO case_role_skills (case_role_id, skill_id, min_level, is_required) VALUES (:r, :s, :m, :q)",
                    "r", roleId, "s", s.skillId(), "m", s.minLevel() == null ? 1 : s.minLevel(), "q", Boolean.TRUE.equals(s.required()));
        notify.log(uid, "case", id, "OPEN_TEAM", "{\"competitionId\":" + in.competitionId() + ",\"need\":" + in.need() + "}");
        cases.opened(id, uid, title);
        return cases.detail(id, uid, false);
    }

    // ---------- 隊伍牆（FR-07）：招募中的比賽隊伍；登入者是學生時附上「適合我」 ----------
    public List<Map<String, Object>> wall(int uid, Integer competitionId, Integer skillId, String q, boolean fitOnly, boolean mineOnly) {
        String kw = q == null || q.isBlank() ? null : q.trim();
        List<Map<String, Object>> rows = db.list("""
                SELECT c.id, c.title, c.description, c.status, c.team_size, c.created_at, c.roster_locked,
                       cp.id comp_id, coalesce(nullif(cp.short_name, ''), cp.name) comp_name, cp.category, cp.apply_deadline, cp.advisor_required,
                       u.id owner_id, u.name owner_name, u.degree owner_degree, u.year owner_year, d.name owner_dept, col.name owner_college,
                       (SELECT count(*) FROM case_members m WHERE m.case_id = c.id) members
                FROM cases c JOIN competitions cp ON cp.id = c.competition_id
                JOIN users u ON u.id = c.owner_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                WHERE (CASE WHEN :mine THEN c.status IN ('OPEN','FORMED','IN_PROGRESS') AND EXISTS (SELECT 1 FROM case_members m WHERE m.case_id = c.id AND m.user_id = :uid)
                            ELSE c.status = 'OPEN' END)
                  AND (cast(:comp AS int) IS NULL OR c.competition_id = :comp)
                  AND (cast(:skill AS int) IS NULL OR EXISTS (SELECT 1 FROM case_roles r JOIN case_role_skills rs ON rs.case_role_id = r.id WHERE r.case_id = c.id AND rs.skill_id = :skill))
                  AND (cast(:q AS text) IS NULL OR c.title ILIKE '%' || :q || '%' OR c.description ILIKE '%' || :q || '%' OR cp.name ILIKE '%' || :q || '%'
                       OR EXISTS (SELECT 1 FROM case_roles r JOIN case_role_skills rs ON rs.case_role_id = r.id JOIN skills s ON s.id = rs.skill_id
                                  WHERE r.case_id = c.id AND s.name ILIKE '%' || :q || '%'))
                ORDER BY c.created_at DESC, c.id DESC""",
                "uid", uid, "mine", mineOnly, "comp", competitionId, "skill", skillId, "q", kw);
        if (rows.isEmpty()) return List.of();
        List<Integer> caseIds = rows.stream().map(r -> Db.i(r.get("id"))).toList();

        // 缺口與技能條件：一次取回
        Map<Integer, List<Map<String, Object>>> rolesByCase = new LinkedHashMap<>();
        Map<Integer, Map<String, Object>> roleById = new LinkedHashMap<>();
        for (var r : db.list("SELECT id, case_id, headcount, filled_count FROM case_roles WHERE case_id IN (:ids) ORDER BY id", "ids", caseIds)) {
            Map<String, Object> role = new LinkedHashMap<>();
            role.put("id", r.get("id")); role.put("need", Db.i(r.get("headcount")) - Db.i(r.get("filled_count"))); role.put("skills", new ArrayList<Map<String, Object>>());
            rolesByCase.computeIfAbsent(Db.i(r.get("case_id")), k -> new ArrayList<>()).add(role);
            roleById.put(Db.i(r.get("id")), role);
        }
        var mySkills = ranking.loadSkills(uid).getOrDefault(uid, RankingService.SkillSet.EMPTY);
        if (roleById.isEmpty()) return List.of();
        for (var s : db.list("""
                SELECT rs.case_role_id, rs.skill_id, s.name, rs.min_level, rs.is_required FROM case_role_skills rs JOIN skills s ON s.id = rs.skill_id
                WHERE rs.case_role_id IN (:ids) ORDER BY rs.is_required DESC, s.name""", "ids", new ArrayList<>(roleById.keySet()))) {
            Map<String, Object> x = new LinkedHashMap<>();
            int skill = Db.i(s.get("skill_id")), min = Db.i(s.get("min_level"));
            x.put("skillId", skill); x.put("name", s.get("name")); x.put("minLevel", min); x.put("required", s.get("is_required"));
            x.put("mine", mySkills.level(skill) >= min);       // 只回「我有沒有達到」，不回分數（D16）
            @SuppressWarnings("unchecked") var list = (List<Map<String, Object>>) roleById.get(Db.i(s.get("case_role_id"))).get("skills");
            list.add(x);
        }

        // 我和每支隊伍的關係：待回覆的申請或邀請
        Map<Integer, Map<String, Object>> pendingByCase = new HashMap<>();
        for (var e : db.list("""
                SELECT e.id, e.direction, r.case_id FROM engagements e JOIN case_roles r ON r.id = e.case_role_id
                WHERE e.user_id = :u AND e.status = 'PENDING' AND r.case_id IN (:ids)""", "u", uid, "ids", caseIds))
            pendingByCase.put(Db.i(e.get("case_id")), Map.of("id", e.get("id"), "direction", e.get("direction")));
        Set<Integer> memberOf = new HashSet<>();
        for (var m : db.list("SELECT case_id FROM case_members WHERE user_id = :u AND case_id IN (:ids)", "u", uid, "ids", caseIds)) memberOf.add(Db.i(m.get("case_id")));

        // 「適合我」：同一顆排序引擎，方向相反（D17）。只對還有名額的缺口計算。
        List<Integer> openRoles = roleById.entrySet().stream().filter(e -> (int) e.getValue().get("need") > 0).map(Map.Entry::getKey).toList();
        Map<Integer, RankingEngine.Result> fits = ranking.evaluateRoles(uid, openRoles);
        var me = db.one("SELECT d.name dept, col.name college FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id WHERE u.id = :u", "u", uid);

        LocalDate today = LocalDate.now(clock);
        List<Map<String, Object>> out = new ArrayList<>();
        Map<Integer, Double> scoreOf = new HashMap<>();
        for (var r : rows) {
            int id = Db.i(r.get("id"));
            List<Map<String, Object>> roles = rolesByCase.getOrDefault(id, List.of());
            int need = roles.stream().mapToInt(x -> (int) x.get("need")).sum();
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", id); m.put("title", r.get("title")); m.put("intro", r.get("description")); m.put("status", r.get("status"));
            m.put("need", need); m.put("members", r.get("members")); m.put("teamSize", r.get("team_size")); m.put("createdAt", r.get("created_at"));
            LocalDate deadline = r.get("apply_deadline") == null ? null : ((java.sql.Date) r.get("apply_deadline")).toLocalDate();
            Map<String, Object> comp = new LinkedHashMap<>();
            comp.put("id", r.get("comp_id")); comp.put("name", r.get("comp_name")); comp.put("category", r.get("category"));
            comp.put("applyDeadline", deadline); comp.put("daysLeft", deadline == null ? null : (int) ChronoUnit.DAYS.between(today, deadline));
            comp.put("advisorRequired", r.get("advisor_required"));
            m.put("competition", comp);
            Map<String, Object> owner = new LinkedHashMap<>();
            owner.put("id", r.get("owner_id")); owner.put("name", r.get("owner_name")); owner.put("department", r.get("owner_dept")); owner.put("college", r.get("owner_college"));
            owner.put("degree", r.get("owner_degree")); owner.put("year", r.get("owner_year"));
            m.put("owner", owner);
            m.put("roles", roles);

            boolean isOwner = Db.i(r.get("owner_id")) == uid, isMember = memberOf.contains(id);
            Map<String, Object> my = new LinkedHashMap<>();
            my.put("isOwner", isOwner); my.put("isMember", isMember); my.put("pending", pendingByCase.get(id));
            m.put("my", my);

            // 多個缺口時取通過且分數最高的那一個；都沒過就回第一個的原因
            RankingEngine.Result best = null; Integer bestRole = null;
            for (var role : roles) {
                var res = fits.get(Db.i(role.get("id")));
                if (res == null) continue;
                if (best == null || (res.passed() && (!best.passed() || res.score() > best.score()))) { best = res; bestRole = Db.i(role.get("id")); }
            }
            if (best != null && !isOwner && !isMember) {
                Map<String, Object> fit = new LinkedHashMap<>();
                fit.put("passed", best.passed()); fit.put("roleId", bestRole);
                fit.put("tags", best.passed() ? fitTags(roleById.get(bestRole), me, r) : List.of());
                fit.put("blocked", plain(best.blockedBy()));
                m.put("fit", fit);
                if (best.passed()) scoreOf.put(id, best.score());
            } else m.put("fit", null);
            out.add(m);
        }
        if (fitOnly) {
            out.removeIf(m -> !scoreOf.containsKey(Db.i(m.get("id"))));
            out.sort((a, b) -> Double.compare(scoreOf.get(Db.i(b.get("id"))), scoreOf.get(Db.i(a.get("id")))));
        }
        return out;
    }

    // ---------- 成隊、退出、請離、報名追蹤（主線的後半段） ----------
    /** 鎖住隊伍列；隊伍層級的寫入都先做這一步（鎖的順序見 CaseService） */
    private Map<String, Object> locked(int caseId) {
        return db.required("""
                SELECT c.id, c.owner_id, c.status, c.title, c.apply_deadline, c.registered_at, c.roster_locked, cp.team_min, cp.team_max
                FROM cases c LEFT JOIN competitions cp ON cp.id = c.competition_id WHERE c.id = :id FOR UPDATE OF c""", "找不到隊伍", "id", caseId);
    }

    private int memberCount(int caseId) { return db.count("SELECT count(*) FROM case_members WHERE case_id = :c", "c", caseId); }

    /** 人數要落在比賽規定的每隊人數之內；比賽沒有寫下限時不擋 */
    private void checkSize(Map<String, Object> c, int members) {
        if (c.get("team_min") != null && members < Db.i(c.get("team_min")))
            throw ApiException.conflict("TEAM_TOO_SMALL", "這場比賽每隊至少 " + c.get("team_min") + " 人，目前 " + members + " 人");
        if (c.get("team_max") != null && members > Db.i(c.get("team_max")))
            throw ApiException.conflict("TEAM_TOO_LARGE", "這場比賽每隊最多 " + c.get("team_max") + " 人，目前 " + members + " 人");
    }

    private void notifyOthers(int caseId, int exceptUserId, String type, String title, String body) {
        for (var m : db.list("SELECT user_id FROM case_members WHERE case_id = :c AND user_id <> :u", "c", caseId, "u", exceptUserId))
            notify.notify(Db.i(m.get("user_id")), type, title, body, "/cases/" + caseId);
    }

    /** 提前成隊（FR-13）：名額還沒滿，隊長決定就用目前的名單。還在等回覆的申請與邀請一併結束。 */
    @Transactional
    public Map<String, Object> form(int caseId, int uid) {
        var c = locked(caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有隊長可以確認成隊");
        if (!"OPEN".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "隊伍不在招募中，不需要再確認成隊");
        int members = memberCount(caseId);
        checkSize(c, members);
        String title = (String) c.get("title");
        cases.closePending(caseId, uid, title, "FULL", "FULL");
        db.exec("UPDATE cases SET status = 'FORMED' WHERE id = :c", "c", caseId);
        events.publishEvent(new TeamFormed(caseId, title, true, false, uid));
        notifyOthers(caseId, uid, "FORMED", "成隊了", "「" + title + "」隊長確認成隊。下一步：到比賽官網完成報名");
        notify.log(uid, "case", caseId, "FORM_EARLY", "{\"members\":" + members + "}");
        return cases.detail(caseId, uid, false);
    }

    /** 退出隊伍（FR-14）：報名前可以退出；隊長不能退出，只能解散 */
    @Transactional
    public Map<String, Object> leave(int caseId, int uid) {
        var c = locked(caseId);
        if (Db.i(c.get("owner_id")) == uid) throw ApiException.conflict("OWNER_CANNOT_LEAVE", "隊長不能退出。不打算參加的話，可以解散隊伍");
        String name = db.scalar(String.class, "SELECT name FROM users WHERE id = :u", "u", uid);
        boolean reopened = removeMember(c, uid, false);
        notify.notify(Db.i(c.get("owner_id")), "MEMBER_LEFT", "有隊友退出", name + " 退出了「" + c.get("title") + "」" + (reopened ? "，隊伍回到招募中" : ""), "/cases/" + caseId);
        return Map.of("left", true, "caseId", caseId);
    }

    /** 請人離開（FR-14）：報名前隊長可以調整名單 */
    @Transactional
    public Map<String, Object> remove(int caseId, int uid, int targetId) {
        var c = locked(caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有隊長可以調整名單");
        if (targetId == uid) throw ApiException.badRequest("不能把自己移出隊伍；不打算參加的話，可以解散隊伍");
        removeMember(c, targetId, true);
        notify.notify(targetId, "MEMBER_REMOVED", "你已離開隊伍", "隊長調整了「" + c.get("title") + "」的名單，你已不在這支隊伍", "/");
        return cases.detail(caseId, uid, false);
    }

    /** 回傳隊伍是否因此回到招募中 */
    private boolean removeMember(Map<String, Object> c, int userId, boolean removed) {
        int caseId = Db.i(c.get("id"));
        String status = (String) c.get("status");
        if (Boolean.TRUE.equals(c.get("roster_locked"))) throw ApiException.conflict("ROSTER_LOCKED", "已經報名、名單鎖定，不能再調整成員");
        if (!Set.of("OPEN", "FORMED").contains(status)) throw ApiException.conflict("INVALID_STATE", "隊伍已經結束，不能再調整成員");
        var m = db.one("SELECT case_role_id FROM case_members WHERE case_id = :c AND user_id = :u", "c", caseId, "u", userId);
        if (m == null) throw ApiException.notFound(removed ? "這位同學不在隊伍裡" : "你不在這支隊伍裡");
        // 成員資格直接刪除：同一場比賽可以再加入別隊，這支隊伍也空出一個名額
        db.exec("DELETE FROM case_members WHERE case_id = :c AND user_id = :u", "c", caseId, "u", userId);
        if (m.get("case_role_id") != null) db.exec("UPDATE case_roles SET filled_count = greatest(filled_count - 1, 0) WHERE id = :r", "r", m.get("case_role_id"));
        boolean reopened = "FORMED".equals(status) && Db.instant(c.get("apply_deadline")).isAfter(clock.instant());
        if (reopened) db.exec("UPDATE cases SET status = 'OPEN' WHERE id = :c", "c", caseId);
        events.publishEvent(new MemberLeft(caseId, userId, removed, reopened, (String) c.get("title")));
        notify.log(userId, "case", caseId, removed ? "MEMBER_REMOVED" : "MEMBER_LEFT", "{\"reopened\":" + reopened + "}");
        return reopened;
    }

    /**
     * 標記已報名（FR-15）：報名是在比賽官網做的，這裡只記錄「隊長說已經報好了」，並鎖定名單。
     * 還在招募中就按，等於同時確認成隊。
     */
    @Transactional
    public Map<String, Object> markRegistered(int caseId, int uid) {
        var c = locked(caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有隊長可以標記已報名");
        if (c.get("registered_at") != null) return cases.detail(caseId, uid, false);
        String status = (String) c.get("status"), title = (String) c.get("title");
        if (!Set.of("OPEN", "FORMED").contains(status)) throw ApiException.conflict("INVALID_STATE", "隊伍已經結束，不能標記報名");
        int members = memberCount(caseId);
        checkSize(c, members);
        if ("OPEN".equals(status)) cases.closePending(caseId, uid, title, "FULL", "FULL");
        db.exec("UPDATE cases SET status = 'IN_PROGRESS', registered_at = :t, registered_by = :u, roster_locked = TRUE WHERE id = :c", "t", Db.ts(clock.instant()), "u", uid, "c", caseId);
        events.publishEvent(new RegistrationMarked(caseId, uid, true, title));
        notifyOthers(caseId, uid, "REGISTERED", "隊伍已報名", "「" + title + "」隊長已標記完成報名，名單鎖定");
        notify.log(uid, "case", caseId, "REGISTERED", "{\"members\":" + members + "}");
        return cases.detail(caseId, uid, false);
    }

    /** 取消「已報名」的標記（按錯時用）：名單解鎖，回到已成隊 */
    @Transactional
    public Map<String, Object> unmarkRegistered(int caseId, int uid) {
        var c = locked(caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有隊長可以取消標記");
        if (c.get("registered_at") == null || !"IN_PROGRESS".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "這支隊伍沒有標記已報名");
        db.exec("UPDATE cases SET status = 'FORMED', registered_at = NULL, registered_by = NULL, roster_locked = FALSE WHERE id = :c", "c", caseId);
        events.publishEvent(new RegistrationMarked(caseId, uid, false, (String) c.get("title")));
        notify.log(uid, "case", caseId, "UNREGISTERED", null);
        return cases.detail(caseId, uid, false);
    }

    /** 排程：報名截止前 7、3、1 天，提醒還沒標記已報名的隊伍（FR-16）。每個門檻只提醒一次。 */
    @Transactional
    public int registrationReminders() {
        LocalDate today = LocalDate.now(clock);
        int n = 0;
        for (var c : db.list("""
                SELECT c.id, c.title, c.owner_id, c.reminded_days, cp.apply_deadline FROM cases c JOIN competitions cp ON cp.id = c.competition_id
                WHERE c.status IN ('OPEN','FORMED') AND c.registered_at IS NULL AND cp.apply_deadline IS NOT NULL
                  AND cp.apply_deadline - cast(:today AS date) BETWEEN 0 AND 7 ORDER BY c.id FOR UPDATE OF c""", "today", today)) {
            int daysLeft = (int) ChronoUnit.DAYS.between(today, ((java.sql.Date) c.get("apply_deadline")).toLocalDate());
            int threshold = daysLeft <= 1 ? 1 : daysLeft <= 3 ? 3 : 7;
            if (c.get("reminded_days") != null && Db.i(c.get("reminded_days")) <= threshold) continue;     // 這個門檻（或更近的）已經提醒過
            int caseId = Db.i(c.get("id"));
            String title = (String) c.get("title");
            db.exec("UPDATE cases SET reminded_days = :d WHERE id = :c", "d", threshold, "c", caseId);
            events.publishEvent(new RegistrationReminder(caseId, daysLeft, title));
            notify.notify(Db.i(c.get("owner_id")), "REG_REMINDER", "報名快截止了",
                    "「" + title + "」" + (daysLeft == 0 ? "今天報名截止" : "距離報名截止還有 " + daysLeft + " 天") + "，記得到比賽官網報名", "/cases/" + caseId);
            n++;
        }
        return n;
    }

    /** 卡片上的白話理由：不顯示分數，也不出現「閘門」「契合度」這些詞（規格書第 11 節的友善標準） */
    private static List<String> fitTags(Map<String, Object> role, Map<String, Object> me, Map<String, Object> team) {
        List<String> tags = new ArrayList<>();
        @SuppressWarnings("unchecked") var skills = (List<Map<String, Object>>) role.get("skills");
        long mine = skills.stream().filter(s -> Boolean.TRUE.equals(s.get("mine"))).count();
        if (mine > 0) tags.add(skills.size() == 1 ? "你會這項技能" : mine == skills.size() ? "你會全部 " + mine + " 項" : "你會其中 " + mine + " 項");
        if (me != null) {
            if (!Objects.equals(me.get("college"), team.get("owner_college"))) tags.add("跨學院");
            else if (!Objects.equals(me.get("dept"), team.get("owner_dept"))) tags.add("不同系");
        }
        return tags;
    }

    private static final Pattern MISSING = Pattern.compile("^G2：缺少必要技能 (.+)$");
    private static final Pattern BELOW = Pattern.compile("^G2：(.+) (未達初階|初階|中階|進階)，未達 (初階|中階|進階)$");
    private static final Pattern HOURS = Pattern.compile("^G3：每週可投入 (\\d+) 小時，低於需求 (\\d+) 小時$");

    /** 把排序引擎的原因改寫成給學生看的白話（對象是登入者自己） */
    public static List<String> plain(List<String> blockedBy) { return plain(blockedBy, false); }

    /** aboutOther：原因講的是別人（隊長邀請時），主詞從「你」換成「這位同學」 */
    public static List<String> plain(List<String> blockedBy, boolean aboutOther) {
        List<String> out = new ArrayList<>();
        String who = aboutOther ? "這位同學" : "你";
        for (String b : blockedBy) {
            Matcher m;
            if (b.startsWith("G1：發案方")) out.add(aboutOther ? "不能邀請自己" : "這是你自己的隊伍");
            else if (b.startsWith("G1：已是本案成員")) out.add(who + "已經在這支隊伍裡");
            else if (b.startsWith("G1：已有待處理")) out.add("已經有一筆申請或邀請在等回覆");
            else if ((m = MISSING.matcher(b)).matches()) out.add("一定要會「" + m.group(1) + "」");
            else if ((m = BELOW.matcher(b)).matches()) out.add("「" + m.group(1) + "」需要" + m.group(3) + "以上");
            else if ((m = HOURS.matcher(b)).matches()) out.add("每週可投入的時間不夠（需要 " + m.group(2) + " 小時）");
            else if (b.startsWith("G3：可用期間")) out.add(who + "的可用期間和比賽期間對不上");
            else if (b.startsWith("G4：案件不在招募中")) out.add("這支隊伍已經不在招募");
            else if (b.startsWith("G4：")) out.add("名額已滿");
            else out.add(b.replaceFirst("^G\\d：", ""));
        }
        return out;
    }
}
