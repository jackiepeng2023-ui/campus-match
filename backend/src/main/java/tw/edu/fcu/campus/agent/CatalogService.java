package tw.edu.fcu.campus.agent;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.agent.AgentModels.Need;
import tw.edu.fcu.campus.agent.AgentModels.NeedIn;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.sql.Date;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 競賽與教師資料（三個媒合 Agent 的資料來源）。
 * 競賽：官方簡章可查證的資訊＋需求技能（Skill ID、最低階級、核心／輔助）；每筆保留來源連結與查證日。
 * 教師：系所網站公開的姓名、職稱、專長、研究方向、指導競賽經歷＋對應的 Skill ID；不存聯絡方式。
 * AI 擷取（source=LLM）的資料先以 approved=false 進來，管理員核准後才會被 Agent 使用。
 */
@Service
public class CatalogService {
    private final Db db;
    private final DemoClock clock;
    private final SkillProfileService profile;

    public CatalogService(Db db, DemoClock clock, SkillProfileService profile) { this.db = db; this.clock = clock; this.profile = profile; }

    public LocalDate today() { return LocalDate.now(clock); }

    // ---------- 需求技能 ----------
    public List<Need> needsOfCompetition(int competitionId) {
        var bands = profile.bands();
        return db.list("""
                SELECT cs.skill_id, s.name, cs.min_level, cs.importance FROM competition_skills cs JOIN skills s ON s.id = cs.skill_id
                WHERE cs.competition_id = :c ORDER BY cs.importance, s.name""", "c", competitionId).stream()
                .map(r -> new Need(Db.i(r.get("skill_id")), (String) r.get("name"), Db.i(r.get("min_level")), bands.minScore(Db.i(r.get("min_level"))), "CORE".equals(r.get("importance")))).toList();
    }

    /** 案件的需求＝各角色的技能條件（必要 → 核心，加分 → 輔助；同一技能取最高門檻） */
    public List<Need> needsOfCase(int caseId) {
        var bands = profile.bands();
        return db.list("""
                SELECT rs.skill_id, s.name, max(rs.min_level) min_level, bool_or(rs.is_required) core
                FROM case_roles r JOIN case_role_skills rs ON rs.case_role_id = r.id JOIN skills s ON s.id = rs.skill_id
                WHERE r.case_id = :c GROUP BY rs.skill_id, s.name ORDER BY core DESC, s.name""", "c", caseId).stream()
                .map(r -> new Need(Db.i(r.get("skill_id")), (String) r.get("name"), Db.i(r.get("min_level")), bands.minScore(Db.i(r.get("min_level"))), Boolean.TRUE.equals(r.get("core")))).toList();
    }

    public List<Need> needs(List<NeedIn> in) {
        if (in == null || in.isEmpty()) return List.of();
        if (in.size() > 12) throw ApiException.badRequest("需求技能最多 12 項");
        var bands = profile.bands();
        List<Need> out = new ArrayList<>();
        Set<Integer> seen = new HashSet<>();
        for (NeedIn n : in) {
            if (n.skillId() == null || !seen.add(n.skillId())) continue;
            String name = db.scalar(String.class, "SELECT name FROM skills WHERE id = :s", "s", n.skillId());
            if (name == null) throw ApiException.badRequest("技能不存在：" + n.skillId());
            int tier = n.minLevel() == null ? 2 : n.minLevel();
            if (tier < 1 || tier > 3) throw ApiException.badRequest("minLevel 須為 1 初階／2 中階／3 進階");
            out.add(new Need(n.skillId(), name, tier, bands.minScore(tier), !"SUPPORT".equalsIgnoreCase(n.importance())));
        }
        return out;
    }

    // ---------- 競賽 ----------
    public record Comp(int id, String name, String shortName, String organizer, String category, String level, String url, String description,
                       Set<String> degrees, String eligibilityNote, Integer teamMin, Integer teamMax, Boolean advisorRequired,
                       LocalDate deadline, LocalDate eventDate, String scheduleNote, String prize, String source, String sourceUrl, LocalDate checkedAt,
                       boolean approved, List<Need> needs) {
        public String display() { return shortName == null || shortName.isBlank() ? name : shortName; }
        public Integer daysLeft(LocalDate today) { return deadline == null ? null : (int) ChronoUnit.DAYS.between(today, deadline); }
        public boolean team() { return teamMax == null || teamMax > 1; }
    }

    private static final String COMP_SQL = """
            SELECT id, name, short_name, organizer, category, level, url, description, eligible_degrees, eligibility_note, team_min, team_max, advisor_required,
                   apply_deadline, event_date, schedule_note, prize, source, source_url, checked_at, approved FROM competitions""";

    private Comp comp(Map<String, Object> r, List<Need> needs) {
        return new Comp(Db.i(r.get("id")), (String) r.get("name"), (String) r.get("short_name"), (String) r.get("organizer"), (String) r.get("category"), (String) r.get("level"),
                (String) r.get("url"), (String) r.get("description"), new LinkedHashSet<>(Arrays.asList(String.valueOf(r.get("eligible_degrees")).split(","))),
                (String) r.get("eligibility_note"), intOrNull(r.get("team_min")), intOrNull(r.get("team_max")), (Boolean) r.get("advisor_required"),
                date(r.get("apply_deadline")), date(r.get("event_date")), (String) r.get("schedule_note"), (String) r.get("prize"), (String) r.get("source"),
                (String) r.get("source_url"), date(r.get("checked_at")), Boolean.TRUE.equals(r.get("approved")), needs);
    }

    /** 全部競賽（一次把需求技能帶齊，避免逐筆查詢） */
    public List<Comp> competitions(boolean approvedOnly) {
        var bands = profile.bands();
        Map<Integer, List<Need>> needs = new HashMap<>();
        for (var r : db.list("SELECT cs.competition_id, cs.skill_id, s.name, cs.min_level, cs.importance FROM competition_skills cs JOIN skills s ON s.id = cs.skill_id ORDER BY cs.importance, s.name"))
            needs.computeIfAbsent(Db.i(r.get("competition_id")), k -> new ArrayList<>())
                 .add(new Need(Db.i(r.get("skill_id")), (String) r.get("name"), Db.i(r.get("min_level")), bands.minScore(Db.i(r.get("min_level"))), "CORE".equals(r.get("importance"))));
        return db.list(COMP_SQL + (approvedOnly ? " WHERE approved" : "") + " ORDER BY apply_deadline NULLS LAST, name").stream()
                .map(r -> comp(r, needs.getOrDefault(Db.i(r.get("id")), List.of()))).toList();
    }

    public Comp competition(int id) {
        var r = db.required(COMP_SQL + " WHERE id = :id", "找不到競賽", "id", id);
        return comp(r, needsOfCompetition(id));
    }

    public Map<String, Object> view(Comp c) {
        LocalDate today = today();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", c.id()); m.put("name", c.name()); m.put("shortName", c.display()); m.put("organizer", c.organizer()); m.put("category", c.category()); m.put("level", c.level());
        m.put("url", c.url()); m.put("description", c.description()); m.put("eligibleDegrees", c.degrees()); m.put("eligibilityNote", c.eligibilityNote());
        m.put("teamMin", c.teamMin()); m.put("teamMax", c.teamMax()); m.put("advisorRequired", c.advisorRequired());
        m.put("applyDeadline", c.deadline()); m.put("eventDate", c.eventDate()); m.put("scheduleNote", c.scheduleNote()); m.put("prize", c.prize());
        Integer left = c.daysLeft(today);
        m.put("daysLeft", left); m.put("status", left == null ? "UNKNOWN" : left < 0 ? "CLOSED" : "OPEN");
        m.put("source", c.source()); m.put("sourceUrl", c.sourceUrl()); m.put("checkedAt", c.checkedAt()); m.put("approved", c.approved());
        m.put("skills", c.needs().stream().map(n -> { Map<String, Object> x = new LinkedHashMap<>();
            x.put("skillId", n.skillId()); x.put("name", n.name()); x.put("minLevel", n.minTier()); x.put("tier", AgentModels.tier(n.minTier())); x.put("importance", n.importance()); return x; }).toList());
        return m;
    }

    public record SkillReq(Integer skillId, Integer minLevel, String importance, Double confidence) {}
    public record CompIn(String name, String shortName, String organizer, String category, String level, String url, String description,
                         List<String> eligibleDegrees, String eligibilityNote, Integer teamMin, Integer teamMax, Boolean advisorRequired,
                         String applyDeadline, String eventDate, String scheduleNote, String prize, String sourceUrl, Boolean approved, List<SkillReq> skills) {}

    @Transactional
    public Map<String, Object> saveCompetition(Integer id, CompIn in, String source) {
        if (in.name() == null || in.name().isBlank()) throw ApiException.badRequest("競賽名稱為必填");
        String level = in.level() == null ? "NATIONAL" : in.level();
        if (!Set.of("CAMPUS", "NATIONAL", "INTERNATIONAL").contains(level)) throw ApiException.badRequest("level 須為 CAMPUS／NATIONAL／INTERNATIONAL");
        List<String> deg = in.eligibleDegrees() == null || in.eligibleDegrees().isEmpty() ? List.of("BACHELOR", "MASTER", "PHD") : in.eligibleDegrees();
        if (!Set.of("BACHELOR", "MASTER", "PHD").containsAll(deg)) throw ApiException.badRequest("eligibleDegrees 只能是 BACHELOR／MASTER／PHD");
        if (in.teamMin() != null && in.teamMax() != null && in.teamMin() > in.teamMax()) throw ApiException.badRequest("隊伍人數下限不可大於上限");
        if (in.skills() == null || in.skills().isEmpty()) throw ApiException.badRequest("至少一項需求技能");
        var p = Db.params("n", in.name().trim(), "sn", blank(in.shortName()), "o", blank(in.organizer()), "c", in.category() == null || in.category().isBlank() ? "跨域" : in.category().trim(),
                "l", level, "u", blank(in.url()), "d", cut(in.description(), 600), "deg", String.join(",", deg), "en", cut(in.eligibilityNote(), 300),
                "tmin", in.teamMin(), "tmax", in.teamMax(), "adv", in.advisorRequired(), "dl", parse(in.applyDeadline()), "ev", parse(in.eventDate()),
                "sch", cut(in.scheduleNote(), 200), "pr", cut2(in.prize(), 300), "su", blank(in.sourceUrl()), "ap", in.approved() == null || in.approved(), "today", today());
        int cid;
        if (id == null) {
            if (db.count("SELECT count(*) FROM competitions WHERE name = :n", "n", in.name().trim()) > 0) throw ApiException.conflict("DUPLICATE", "已有同名競賽");
            p.addValue("src", source);
            cid = db.jdbc.queryForObject("""
                    INSERT INTO competitions (name, short_name, organizer, category, level, url, description, eligible_degrees, eligibility_note, team_min, team_max,
                        advisor_required, apply_deadline, event_date, schedule_note, prize, source, source_url, checked_at, approved)
                    VALUES (:n, :sn, :o, :c, :l, :u, :d, :deg, :en, :tmin, :tmax, :adv, :dl, :ev, :sch, :pr, :src, :su, :today, :ap) RETURNING id""", p, Integer.class);
        } else {
            cid = id; p.addValue("id", id);
            int n = db.jdbc.update("""
                    UPDATE competitions SET name = :n, short_name = :sn, organizer = :o, category = :c, level = :l, url = :u, description = :d, eligible_degrees = :deg,
                        eligibility_note = :en, team_min = :tmin, team_max = :tmax, advisor_required = :adv, apply_deadline = :dl, event_date = :ev, schedule_note = :sch,
                        prize = :pr, source_url = :su, checked_at = :today, approved = :ap WHERE id = :id""", p);
            if (n == 0) throw ApiException.notFound("找不到競賽");
            db.exec("DELETE FROM competition_skills WHERE competition_id = :c", "c", cid);
        }
        boolean hasCore = false;
        for (SkillReq s : in.skills()) {
            if (s.skillId() == null || db.count("SELECT count(*) FROM skills WHERE id = :s", "s", s.skillId()) == 0) throw ApiException.badRequest("技能不存在：" + s.skillId());
            int tier = s.minLevel() == null ? 2 : s.minLevel();
            if (tier < 1 || tier > 3) throw ApiException.badRequest("minLevel 須為 1–3");
            boolean core = !"SUPPORT".equalsIgnoreCase(s.importance());
            hasCore |= core;
            db.exec("INSERT INTO competition_skills VALUES (:c, :s, :m, :i) ON CONFLICT DO NOTHING", "c", cid, "s", s.skillId(), "m", tier, "i", core ? "CORE" : "SUPPORT");
        }
        if (!hasCore) throw ApiException.badRequest("至少一項核心（CORE）技能");
        return view(competition(cid));
    }

    @Transactional
    public void deleteCompetition(int id) {
        if (db.count("SELECT count(*) FROM cases WHERE competition_id = :c", "c", id) > 0) throw ApiException.conflict("IN_USE", "已有案件連結這個競賽，請改為停用（approved=false）");
        db.exec("DELETE FROM competitions WHERE id = :c", "c", id);
    }

    public void approveCompetition(int id, boolean approved) {
        if (db.exec("UPDATE competitions SET approved = :a WHERE id = :c", "a", approved, "c", id) == 0) throw ApiException.notFound("找不到競賽");
    }

    // ---------- 教師 ----------
    public record Teacher(int id, String name, String title, Integer departmentId, String department, String college, String expertise, String research, String coaching,
                          String profileUrl, String sourceUrl, LocalDate crawledAt, boolean active, Map<Integer, Double> skills, Map<Integer, String> skillNames, int pendingSkills) {}

    private static final String TEACHER_SQL = """
            SELECT t.id, t.name, t.title, t.department_id, d.name department, c.name college, t.expertise, t.research, t.coaching,
                   t.profile_url, t.source_url, t.crawled_at, t.active
            FROM teachers t LEFT JOIN departments d ON d.id = t.department_id LEFT JOIN colleges c ON c.id = d.college_id""";

    private Teacher teacher(Map<String, Object> r, Map<Integer, Double> skills, Map<Integer, String> names, int pending) {
        return new Teacher(Db.i(r.get("id")), (String) r.get("name"), (String) r.get("title"), intOrNull(r.get("department_id")), (String) r.get("department"), (String) r.get("college"),
                (String) r.get("expertise"), (String) r.get("research"), (String) r.get("coaching"), (String) r.get("profile_url"), (String) r.get("source_url"),
                date(r.get("crawled_at")), Boolean.TRUE.equals(r.get("active")), skills, names, pending);
    }

    /** 全部教師與已核准的專長技能（教師 Agent 用） */
    public List<Teacher> teachers(boolean activeOnly) {
        Map<Integer, Map<Integer, Double>> skills = new HashMap<>();
        Map<Integer, Map<Integer, String>> names = new HashMap<>();
        Map<Integer, Integer> pending = new HashMap<>();
        for (var r : db.list("SELECT ts.teacher_id, ts.skill_id, s.name, ts.confidence, ts.approved FROM teacher_skills ts JOIN skills s ON s.id = ts.skill_id ORDER BY ts.confidence DESC, s.name")) {
            int tid = Db.i(r.get("teacher_id"));
            if (!Boolean.TRUE.equals(r.get("approved"))) { pending.merge(tid, 1, Integer::sum); continue; }
            skills.computeIfAbsent(tid, k -> new LinkedHashMap<>()).put(Db.i(r.get("skill_id")), Db.d(r.get("confidence")));
            names.computeIfAbsent(tid, k -> new LinkedHashMap<>()).put(Db.i(r.get("skill_id")), (String) r.get("name"));
        }
        return db.list(TEACHER_SQL + (activeOnly ? " WHERE t.active" : "") + " ORDER BY c.id NULLS LAST, d.name, t.name").stream()
                .map(r -> teacher(r, skills.getOrDefault(Db.i(r.get("id")), Map.of()), names.getOrDefault(Db.i(r.get("id")), Map.of()), pending.getOrDefault(Db.i(r.get("id")), 0))).toList();
    }

    public Map<String, Object> view(Teacher t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", t.id()); m.put("name", t.name()); m.put("title", t.title()); m.put("departmentId", t.departmentId()); m.put("department", t.department()); m.put("college", t.college());
        m.put("expertise", t.expertise()); m.put("research", t.research()); m.put("coaching", t.coaching());
        m.put("profileUrl", t.profileUrl()); m.put("sourceUrl", t.sourceUrl()); m.put("crawledAt", t.crawledAt()); m.put("active", t.active());
        m.put("skills", t.skills().entrySet().stream().map(e -> { Map<String, Object> x = new LinkedHashMap<>();
            x.put("skillId", e.getKey()); x.put("name", t.skillNames().get(e.getKey())); x.put("confidence", e.getValue()); return x; }).toList());
        m.put("pendingSkills", t.pendingSkills());
        return m;
    }

    public void setTeacherActive(int id, boolean active) {
        if (db.exec("UPDATE teachers SET active = :a WHERE id = :id", "a", active, "id", id) == 0) throw ApiException.notFound("找不到教師");
    }

    public Map<String, Object> teacherDetail(int id) {
        Teacher t = teachers(false).stream().filter(x -> x.id() == id).findFirst().orElseThrow(() -> ApiException.notFound("找不到教師"));
        Map<String, Object> m = view(t);
        m.put("allSkills", db.list("""
                SELECT ts.skill_id "skillId", s.name, ts.confidence, ts.source, ts.approved FROM teacher_skills ts JOIN skills s ON s.id = ts.skill_id
                WHERE ts.teacher_id = :t ORDER BY ts.approved DESC, ts.confidence DESC""", "t", id));
        m.put("platformTeams", db.count("SELECT count(*) FROM cases WHERE advisor_teacher_id = :t AND status IN ('OPEN','FORMED','IN_PROGRESS','CLOSING')", "t", id));
        return m;
    }

    public record TeacherIn(String name, String title, Integer departmentId, String expertise, String research, String coaching, String profileUrl, String sourceUrl,
                            Boolean active, List<SkillReq> skills) {}

    private static final java.util.regex.Pattern CONTACT = java.util.regex.Pattern.compile("[\\w.+-]+@[\\w-]+\\.[\\w.-]+|\\(?0\\d{1,2}\\)?[-\\s]?\\d{3,4}[-\\s]?\\d{3,4}|分機\\s*\\d+");

    @Transactional
    public Map<String, Object> saveTeacher(Integer id, TeacherIn in, String source) {
        if (in.name() == null || in.name().isBlank()) throw ApiException.badRequest("姓名為必填");
        if (in.departmentId() != null && db.count("SELECT count(*) FROM departments WHERE id = :d", "d", in.departmentId()) == 0) throw ApiException.badRequest("系所不存在");
        for (String txt : new String[]{in.expertise(), in.research(), in.coaching()})
            if (txt != null && CONTACT.matcher(txt).find()) throw ApiException.badRequest("教師資料只收公開的專長、研究方向與指導經歷，請移除 Email／電話／分機");
        int tid;
        if (id == null) {
            if (db.count("SELECT count(*) FROM teachers WHERE name = :n AND department_id IS NOT DISTINCT FROM cast(:d AS int)", "n", in.name().trim(), "d", in.departmentId()) > 0)
                throw ApiException.conflict("DUPLICATE", "同系所已有同名教師");
            tid = db.insertReturningId("""
                    INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at, active)
                    VALUES (:n, :t, :d, :e, :r, :c, :p, :s, :today, :a) RETURNING id""",
                    "n", in.name().trim(), "t", blank(in.title()), "d", in.departmentId(), "e", cut(in.expertise(), 1000), "r", cut(in.research(), 1000), "c", cut(in.coaching(), 1000),
                    "p", blank(in.profileUrl()), "s", blank(in.sourceUrl()), "today", today(), "a", in.active() == null || in.active());
        } else {
            tid = id;
            int n = db.exec("""
                    UPDATE teachers SET name = :n, title = :t, department_id = :d, expertise = :e, research = :r, coaching = :c, profile_url = :p, source_url = :s, active = :a
                    WHERE id = :id""",
                    "n", in.name().trim(), "t", blank(in.title()), "d", in.departmentId(), "e", cut(in.expertise(), 1000), "r", cut(in.research(), 1000), "c", cut(in.coaching(), 1000),
                    "p", blank(in.profileUrl()), "s", blank(in.sourceUrl()), "a", in.active() == null || in.active(), "id", id);
            if (n == 0) throw ApiException.notFound("找不到教師");
        }
        if (in.skills() != null) {
            db.exec("DELETE FROM teacher_skills WHERE teacher_id = :t", "t", tid);
            int auto = profile.param("llm_auto_approve_pct", 80);
            for (SkillReq s : in.skills()) {
                if (s.skillId() == null || db.count("SELECT count(*) FROM skills WHERE id = :s", "s", s.skillId()) == 0) throw ApiException.badRequest("技能不存在：" + s.skillId());
                double conf = s.confidence() == null ? 1.0 : Math.max(0.01, Math.min(1.0, s.confidence()));
                boolean approved = !"LLM".equals(source) || conf * 100 >= auto;          // AI 擷取：信心達門檻自動生效，否則待核准
                db.exec("INSERT INTO teacher_skills VALUES (:t, :s, :c, :src, :a) ON CONFLICT DO NOTHING", "t", tid, "s", s.skillId(), "c", conf, "src", source, "a", approved);
            }
        }
        return teacherDetail(tid);
    }

    public void approveTeacherSkill(int teacherId, int skillId, boolean approved) {
        if (approved) db.exec("UPDATE teacher_skills SET approved = TRUE WHERE teacher_id = :t AND skill_id = :s", "t", teacherId, "s", skillId);
        else db.exec("DELETE FROM teacher_skills WHERE teacher_id = :t AND skill_id = :s", "t", teacherId, "s", skillId);
    }

    // ---------- 小工具 ----------
    private static Integer intOrNull(Object o) { return o == null ? null : ((Number) o).intValue(); }
    private static LocalDate date(Object o) { return o == null ? null : ((Date) o).toLocalDate(); }
    private static String blank(String s) { return s == null || s.isBlank() ? null : s.trim(); }
    private static String cut(String s, int n) { s = s == null ? "" : s.trim(); return s.length() > n ? s.substring(0, n) : s; }
    private static String cut2(String s, int n) { return s == null || s.isBlank() ? null : cut(s, n); }
    private static LocalDate parse(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { throw ApiException.badRequest("日期格式須為 YYYY-MM-DD"); }
    }
}
