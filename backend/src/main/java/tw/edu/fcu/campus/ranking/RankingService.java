package tw.edu.fcu.campus.ranking;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.profile.SkillProfileService;
import tw.edu.fcu.campus.user.StatsService;

import java.sql.Date;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/** 把資料庫裡的角色、候選人組成引擎輸入；雙向共用同一組閘門與公式（D17） */
@Service
public class RankingService {
    private final Db db;
    private final StatsService stats;
    private final DemoClock clock;
    private final SkillProfileService profile;
    private final RankingEngine engine = new RankingEngine();
    private final ObjectMapper json = new ObjectMapper();

    public RankingService(Db db, StatsService stats, DemoClock clock, SkillProfileService profile) { this.db = db; this.stats = stats; this.clock = clock; this.profile = profile; }

    public RankingEngine engine() { return engine; }

    public RankingEngine.Weights weights() {
        Map<String, Double> w = new HashMap<>();
        for (var r : db.list("SELECT key, value FROM ranking_weights")) w.put((String) r.get("key"), Db.d(r.get("value")));
        return new RankingEngine.Weights(w.getOrDefault("S", .4), w.getOrDefault("T", .2), w.getOrDefault("R", .2), w.getOrDefault("P", .1), w.getOrDefault("C", .1));
    }

    // ---------- 角色 ----------
    public record RoleCtx(int roleId, int caseId, int ownerId, String caseTitle, String caseType, String roleName,
                          int headcount, int filled, int pendingInvites, RankingEngine.Role role) {}

    public RoleCtx loadRole(int roleId) {
        var r = db.required("""
                SELECT cr.id, cr.case_id, cr.role_name, cr.headcount, cr.filled_count, cr.hours_per_week,
                       c.owner_id, c.title, c.type, c.status, c.start_date, c.end_date,
                       d.name dept, col.name college,
                       (SELECT count(*) FROM engagements e WHERE e.case_role_id = cr.id AND e.direction = 'INVITE' AND e.status = 'PENDING') pending_invites
                FROM case_roles cr JOIN cases c ON c.id = cr.case_id
                JOIN users u ON u.id = c.owner_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                WHERE cr.id = :id""", "找不到角色", "id", roleId);
        var bands = profile.bands();
        List<RankingEngine.RoleSkill> skills = db.list("""
                SELECT rs.skill_id, s.name, rs.min_level, rs.is_required FROM case_role_skills rs JOIN skills s ON s.id = rs.skill_id
                WHERE rs.case_role_id = :id ORDER BY rs.is_required DESC, s.name""", "id", roleId).stream()
                .map(x -> new RankingEngine.RoleSkill(Db.i(x.get("skill_id")), (String) x.get("name"), Db.i(x.get("min_level")),
                        bands.minScore(Db.i(x.get("min_level"))), (Boolean) x.get("is_required")))
                .toList();
        int headcount = Db.i(r.get("headcount")), filled = Db.i(r.get("filled_count")), pend = Db.i(r.get("pending_invites"));
        var role = new RankingEngine.Role(Db.i(r.get("hours_per_week")), ((Date) r.get("start_date")).toLocalDate(), ((Date) r.get("end_date")).toLocalDate(),
                skills, (String) r.get("college"), (String) r.get("dept"), "OPEN".equals(r.get("status")), headcount - filled);
        return new RoleCtx(roleId, Db.i(r.get("case_id")), Db.i(r.get("owner_id")), (String) r.get("title"), (String) r.get("type"),
                (String) r.get("role_name"), headcount, filled, pend, role);
    }

    // ---------- 候選人 ----------
    public record UserRow(int id, String name, String college, String dept, String degree, int year, int hours, LocalDate from, LocalDate to) {}

    public List<UserRow> loadStudents(Integer onlyUserId) {
        return db.list("""
                SELECT u.id, u.name, u.degree, u.year, d.name dept, col.name college,
                       coalesce(a.hours_per_week, 0) hours, a.available_from, a.available_to
                FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                LEFT JOIN user_availability a ON a.user_id = u.id
                WHERE u.role = 'STUDENT' AND u.deidentified_at IS NULL AND (cast(:uid AS int) IS NULL OR u.id = :uid)""", "uid", onlyUserId)
                .stream().map(r -> new UserRow(Db.i(r.get("id")), (String) r.get("name"), (String) r.get("college"), (String) r.get("dept"),
                        (String) r.get("degree"), Db.i(r.get("year")), Db.i(r.get("hours")),
                        r.get("available_from") == null ? null : ((Date) r.get("available_from")).toLocalDate(),
                        r.get("available_to") == null ? null : ((Date) r.get("available_to")).toLocalDate())).toList();
    }

    /** 一位學生的 Skill Profile（供引擎與三個媒合 Agent 共用）：分數、階級、可信狀態標籤 */
    public record SkillSet(Map<Integer, Integer> scores, Map<Integer, Integer> levels, Map<Integer, String> trust) {
        public static final SkillSet EMPTY = new SkillSet(Map.of(), Map.of(), Map.of());
        public int score(int skillId) { return scores.getOrDefault(skillId, 0); }
        public int level(int skillId) { return levels.getOrDefault(skillId, 0); }
    }

    public Map<Integer, SkillSet> loadSkills(Integer onlyUserId) {
        Map<Integer, SkillSet> m = new HashMap<>();
        for (var r : db.list("SELECT user_id, skill_id, score, level, trust FROM user_skills WHERE cast(:uid AS int) IS NULL OR user_id = :uid", "uid", onlyUserId)) {
            SkillSet ss = m.computeIfAbsent(Db.i(r.get("user_id")), k -> new SkillSet(new HashMap<>(), new HashMap<>(), new HashMap<>()));
            int sid = Db.i(r.get("skill_id"));
            ss.scores().put(sid, Db.i(r.get("score"))); ss.levels().put(sid, Db.i(r.get("level")));
            ss.trust().put(sid, SkillProfileService.trustLabel((String) r.get("trust")));
        }
        return m;
    }

    public RankingEngine.Candidate candidate(UserRow u, SkillSet sk, StatsService.Stats st, int ownerId, Set<Integer> members, Set<Integer> pending) {
        if (sk == null) sk = SkillSet.EMPTY;
        return new RankingEngine.Candidate(u.id(), u.name(), u.college(), u.dept(), sk.scores(), sk.levels(), sk.trust(),
                u.hours(), u.from(), u.to(), st.peerScore(), st.awardScore(), st.responseRate(), st.credibility(),
                u.id() == ownerId, members.contains(u.id()), pending.contains(u.id()), st.activeCases());
    }

    private RankingEngine.Candidate candidate(UserRow u, SkillSet sk, StatsService.Stats st, RoleCtx ctx, Set<Integer> members, Set<Integer> pending) {
        return candidate(u, sk, st, ctx.ownerId(), members, pending);
    }

    private Set<Integer> members(int caseId) {
        return db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId).stream().map(r -> Db.i(r.get("user_id"))).collect(Collectors.toSet());
    }

    private Set<Integer> pendingForRole(int roleId) {
        return db.list("SELECT user_id FROM engagements WHERE case_role_id = :r AND status = 'PENDING'", "r", roleId).stream().map(r -> Db.i(r.get("user_id"))).collect(Collectors.toSet());
    }

    /** 單一候選人對單一角色（申請／邀請時用） */
    public RankingEngine.Result evaluateOne(int roleId, int userId) {
        RoleCtx ctx = loadRole(roleId);
        List<UserRow> us = loadStudents(userId);
        if (us.isEmpty()) throw ApiException.notFound("找不到學生");
        var levels = loadSkills(userId).get(userId);
        var st = stats.of(userId);
        return engine.evaluate(ctx.role(), candidate(us.get(0), levels, st, ctx, members(ctx.caseId()), pendingForRole(roleId)), weights());
    }

    /** 一位學生對多個缺口（隊伍牆的「適合我」）：學生的技能與統計只讀一次。不是學生（管理員）時回傳空集合。 */
    public Map<Integer, RankingEngine.Result> evaluateRoles(int userId, Collection<Integer> roleIds) {
        List<UserRow> us = loadStudents(userId);
        if (us.isEmpty() || roleIds.isEmpty()) return Map.of();
        var skills = loadSkills(userId).get(userId);
        var st = stats.of(userId);
        var w = weights();
        Map<Integer, RankingEngine.Result> out = new LinkedHashMap<>();
        for (int roleId : roleIds) {
            RoleCtx ctx = loadRole(roleId);
            out.put(roleId, engine.evaluate(ctx.role(), candidate(us.get(0), skills, st, ctx, members(ctx.caseId()), pendingForRole(roleId)), w));
        }
        return out;
    }

    /** 發案方看：此角色的推薦人選（含被擋下者與原因），並存快照 */
    @Transactional
    public Map<String, Object> recommendForRole(int roleId, int requesterId, boolean isAdmin) {
        RoleCtx ctx = loadRole(roleId);
        if (ctx.ownerId() != requesterId && !isAdmin) throw ApiException.forbidden("只有發案方能查看推薦名單");
        List<UserRow> users = loadStudents(null);
        var levels = loadSkills(null);
        var st = stats.all(users.stream().map(UserRow::id).toList());
        Set<Integer> members = members(ctx.caseId()), pending = pendingForRole(roleId);
        var w = weights();
        Map<Integer, UserRow> byId = users.stream().collect(Collectors.toMap(UserRow::id, u -> u));

        List<RankingEngine.Result> results = users.stream()
                .map(u -> engine.evaluate(ctx.role(), candidate(u, levels.get(u.id()), st.get(u.id()), ctx, members, pending), w)).toList();
        Comparator<RankingEngine.Result> order = Comparator.comparingDouble(RankingEngine.Result::score).reversed()
                .thenComparingInt(RankingEngine.Result::activeCases);
        List<RankingEngine.Result> passed = results.stream().filter(RankingEngine.Result::passed).sorted(order).limit(20).toList();
        List<RankingEngine.Result> blocked = results.stream().filter(r -> !r.passed() && r.blockedBy().stream().noneMatch(b -> b.startsWith("G2") || b.startsWith("G1：發案方")))
                .sorted(order).limit(10).toList();

        // 快照（口試可追溯「當時為什麼推薦」）
        db.exec("DELETE FROM recommendations WHERE case_role_id = :r", "r", roleId);
        int rank = 1;
        for (var r : passed) {
            try {
                db.exec("INSERT INTO recommendations (case_role_id, user_id, rank, score, breakdown_json, generated_at) VALUES (:r, :u, :k, :s, cast(:b AS jsonb), :t)",
                        "r", roleId, "u", r.userId(), "k", rank++, "s", r.score(), "b", json.writeValueAsString(r.breakdown()), "t", Db.ts(clock.instant()));
            } catch (Exception e) { throw new RuntimeException(e); }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("role", Map.of("id", roleId, "roleName", ctx.roleName(), "headcount", ctx.headcount(), "filled", ctx.filled(),
                "pendingInvites", ctx.pendingInvites(), "invitable", Math.max(0, ctx.headcount() - ctx.filled() - ctx.pendingInvites()),
                "skills", ctx.role().skills()));
        out.put("weights", w);
        out.put("recommended", passed.stream().map(r -> view(r, byId.get(r.userId()), st.get(r.userId()))).toList());
        out.put("blocked", blocked.stream().map(r -> view(r, byId.get(r.userId()), st.get(r.userId()))).toList());
        return out;
    }

    private Map<String, Object> view(RankingEngine.Result r, UserRow u, StatsService.Stats st) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("userId", u.id()); m.put("name", u.name()); m.put("college", u.college()); m.put("dept", u.dept());
        m.put("degree", u.degree()); m.put("year", u.year()); m.put("hoursPerWeek", u.hours());
        m.put("score", r.score()); m.put("breakdown", r.breakdown()); m.put("reasons", r.reasons()); m.put("blockedBy", r.blockedBy());
        m.put("stats", st.toMap());
        return m;
    }

    /** 學生看：推薦給我的案件（同一組閘門與公式，查詢方向相反） */
    public List<Map<String, Object>> recommendCasesForUser(int userId) {
        List<UserRow> us = loadStudents(userId);
        if (us.isEmpty()) return List.of();
        UserRow u = us.get(0);
        var levels = loadSkills(userId).get(userId);
        var st = stats.of(userId);
        var w = weights();
        List<Map<String, Object>> out = new ArrayList<>();
        for (var r : db.list("""
                SELECT cr.id FROM case_roles cr JOIN cases c ON c.id = cr.case_id
                WHERE c.status = 'OPEN' AND c.owner_id <> :u AND cr.filled_count < cr.headcount
                  AND NOT EXISTS (SELECT 1 FROM case_members m WHERE m.case_id = c.id AND m.user_id = :u)""", "u", userId)) {
            int roleId = Db.i(r.get("id"));
            RoleCtx ctx = loadRole(roleId);
            var res = engine.evaluate(ctx.role(), candidate(u, levels, st, ctx, members(ctx.caseId()), pendingForRole(roleId)), w);
            if (!res.passed()) continue;
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("caseId", ctx.caseId()); m.put("caseTitle", ctx.caseTitle()); m.put("caseType", ctx.caseType());
            m.put("roleId", roleId); m.put("roleName", ctx.roleName()); m.put("headcount", ctx.headcount()); m.put("filled", ctx.filled());
            m.put("skills", ctx.role().skills()); m.put("score", res.score()); m.put("breakdown", res.breakdown()); m.put("reasons", res.reasons());
            out.add(m);
        }
        out.sort((a, b) -> Double.compare((Double) b.get("score"), (Double) a.get("score")));
        return out.size() > 10 ? out.subList(0, 10) : out;
    }
}
