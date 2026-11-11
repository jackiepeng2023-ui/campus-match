package tw.edu.fcu.campus.admin;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DbInit;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import tw.edu.fcu.campus.user.UserService;

/** M6 管理：權重、係數、參數、Demo 時鐘、重置資料 */
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    private final Db db;
    private final DemoClock clock;
    private final SchedulerService scheduler;
    private final DbInit dbInit;
    private final UserService users;
    private final SkillProfileService profile;
    private final boolean demoClock;

    /** 會影響 Skill Profile 的參數：變更後全體重新盤點 */
    private static final Set<String> PROFILE_PARAMS = Set.of("self_declared_cap", "course_grade_verified", "max_skills_per_evidence",
            "case_evidence_min_match_x10", "case_confirm_match_x10");

    public AdminController(Db db, DemoClock clock, SchedulerService scheduler, DbInit dbInit, UserService users, SkillProfileService profile,
                           @Value("${app.demo-clock}") boolean demoClock) {
        this.db = db; this.clock = clock; this.scheduler = scheduler; this.dbInit = dbInit; this.users = users; this.profile = profile; this.demoClock = demoClock;
    }

    @GetMapping("/params")
    public Map<String, Object> params() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("weights", db.list("SELECT key, value, label FROM ranking_weights ORDER BY CASE key WHEN 'S' THEN 1 WHEN 'T' THEN 2 WHEN 'R' THEN 3 WHEN 'P' THEN 4 ELSE 5 END"));
        m.put("credibility", db.list("SELECT match_level \"matchLevel\", coefficient FROM credibility_coefficients ORDER BY match_level DESC"));
        m.put("awardMatrix", db.list("SELECT rank, level, score FROM award_matrix ORDER BY CASE rank WHEN 'FIRST' THEN 1 WHEN 'TOP3' THEN 2 WHEN 'HONORABLE' THEN 3 ELSE 4 END, CASE level WHEN 'CAMPUS' THEN 1 WHEN 'NATIONAL' THEN 2 ELSE 3 END"));
        m.put("params", db.list("SELECT key, value, label FROM system_params ORDER BY key"));
        m.put("levelBands", db.list("SELECT degree_group \"degreeGroup\", tier, name, min_score \"minScore\" FROM level_bands ORDER BY degree_group, tier"));
        return m;
    }

    public record BandIn(String degreeGroup, Integer tier, String name, Integer minScore) {}
    public record ParamsIn(Map<String, Double> weights, Map<String, Double> credibility, Map<String, Integer> params, Map<String, Double> awardMatrix,
                           List<BandIn> levelBands) {}

    @PutMapping("/params")
    public Map<String, Object> update(@RequestBody ParamsIn in) {
        if (in.weights() != null) {
            double sum = in.weights().values().stream().mapToDouble(Double::doubleValue).sum();
            if (Math.abs(sum - 1.0) > 0.001) throw ApiException.badRequest("權重總和必須為 1.0（目前 " + sum + "）");
            for (var e : in.weights().entrySet()) db.exec("UPDATE ranking_weights SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
        }
        if (in.credibility() != null) for (var e : in.credibility().entrySet()) db.exec("UPDATE credibility_coefficients SET coefficient = :v WHERE match_level = :k", "v", e.getValue(), "k", Integer.parseInt(e.getKey()));
        boolean reprofile = false;
        if (in.params() != null) for (var e : in.params().entrySet()) {
            db.exec("UPDATE system_params SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
            reprofile |= PROFILE_PARAMS.contains(e.getKey());
        }
        if (in.awardMatrix() != null) for (var e : in.awardMatrix().entrySet()) {
            String[] rl = e.getKey().split("/");
            db.exec("UPDATE award_matrix SET score = :v WHERE rank = :r AND level = :l", "v", e.getValue(), "r", rl[0], "l", rl[1]);
            reprofile = true;
        }
        if (in.levelBands() != null && !in.levelBands().isEmpty()) {      // 等級三階的門檻（教師討論後可調）：須遞增且落在 1–100
            Map<String, int[]> next = new LinkedHashMap<>();
            for (var r : db.list("SELECT degree_group, tier, min_score FROM level_bands"))
                next.computeIfAbsent((String) r.get("degree_group"), k -> new int[4])[Db.i(r.get("tier"))] = Db.i(r.get("min_score"));
            for (BandIn b : in.levelBands()) {
                if (b.degreeGroup() == null || !next.containsKey(b.degreeGroup()) || b.tier() == null || b.tier() < 1 || b.tier() > 3 || b.minScore() == null)
                    throw ApiException.badRequest("levelBands 須含 degreeGroup（BACHELOR／GRADUATE）、tier（1–3）、minScore");
                next.get(b.degreeGroup())[b.tier()] = b.minScore();
            }
            for (var e : next.entrySet()) {
                int[] v = e.getValue();
                if (v[1] < 1 || v[3] > 100 || v[1] >= v[2] || v[2] >= v[3]) throw ApiException.badRequest("等級門檻須遞增且介於 1–100（初階 < 中階 < 進階）");
            }
            for (BandIn b : in.levelBands()) {
                db.exec("UPDATE level_bands SET min_score = :m WHERE degree_group = :g AND tier = :t", "m", b.minScore(), "g", b.degreeGroup(), "t", b.tier());
                if (b.name() != null && !b.name().isBlank()) db.exec("UPDATE level_bands SET name = :n WHERE degree_group = :g AND tier = :t", "n", b.name().trim(), "g", b.degreeGroup(), "t", b.tier());
            }
            reprofile = true;
        }
        Map<String, Object> out = params();
        if (reprofile) out.put("reprofiledStudents", profile.rebuildAll(true));
        return out;
    }

    // ----- 證據驗證（自述 → 已驗證）：證照、作品集、得獎 -----

    /** 待驗證／已驗證的證據清單（自我評估不需驗證，不列入） */
    @GetMapping("/evidence")
    public Object evidence(@RequestParam(defaultValue = "false") boolean verified, @RequestParam(defaultValue = "200") int limit) {
        return db.list("""
                SELECT * FROM (
                  SELECT 'CREDENTIAL' kind, c.id, c.type, c.title, c.issuer detail, c.proof_url "proofUrl", c.obtained_on "occurredOn", c.claimed_score score,
                         c.verified, c.created_at "createdAt", u.id "userId", u.name "userName", d.name department,
                         (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM credential_skills cs JOIN skills s ON s.id = cs.skill_id WHERE cs.credential_id = c.id) skills
                  FROM user_credentials c JOIN users u ON u.id = c.user_id LEFT JOIN departments d ON d.id = u.department_id
                  WHERE c.type <> 'SELF' AND u.purged_at IS NULL
                  UNION ALL
                  SELECT 'AWARD', a.id, 'COMPETITION', a.competition, a.level || '/' || a.rank, a.proof_url, a.award_date, 60 + round(40 * am.score)::int,
                         a.verified, NULL, u.id, u.name, d.name,
                         (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM award_skills k JOIN skills s ON s.id = k.skill_id WHERE k.award_id = a.id)
                  FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level
                  JOIN users u ON u.id = a.user_id LEFT JOIN departments d ON d.id = u.department_id WHERE u.purged_at IS NULL) x
                WHERE verified = :v ORDER BY ("proofUrl" IS NULL), "createdAt" DESC NULLS LAST, id DESC LIMIT :n""", "v", verified, "n", Math.min(limit, 1000));
    }

    public record VerifyIn(Boolean verified) {}

    @PutMapping("/evidence/credential/{id}")
    public Map<String, Object> verifyCredential(@PathVariable int id, @RequestBody VerifyIn in) {
        profile.verifyCredential(id, Current.id(), in.verified() == null || in.verified());
        return Map.of("ok", true);
    }

    @PutMapping("/evidence/award/{id}")
    public Map<String, Object> verifyAward(@PathVariable int id, @RequestBody VerifyIn in) {
        profile.verifyAward(id, Current.id(), in.verified() == null || in.verified());
        return Map.of("ok", true);
    }

    // ----- 證照對照表（證照 → 技能與分數） -----

    public record CatalogIn(String name, String issuer, Integer score, String note, List<Integer> skillIds) {}

    @PostMapping("/certificates")
    public Map<String, Object> addCertificate(@RequestBody CatalogIn in) {
        int max = Math.max(1, profile.param("max_skills_per_evidence", 5));
        if (in.name() == null || in.name().isBlank() || in.score() == null || in.score() < 1 || in.score() > 100) throw ApiException.badRequest("name、score（1–100）為必填");
        if (in.skillIds() == null || in.skillIds().isEmpty() || in.skillIds().size() > max) throw ApiException.badRequest("請對應 1–" + max + " 個技能");
        Integer id = db.scalar(Integer.class, "INSERT INTO certificate_catalog (name, issuer, score, note) VALUES (:n, :i, :s, :no) ON CONFLICT (name) DO NOTHING RETURNING id",
                "n", in.name().trim(), "i", in.issuer(), "s", in.score(), "no", in.note());
        if (id == null) throw ApiException.conflict("DUPLICATE", "對照表已有同名證照");
        for (Integer sk : in.skillIds()) db.exec("INSERT INTO certificate_catalog_skills VALUES (:c, :s) ON CONFLICT DO NOTHING", "c", id, "s", sk);
        return Map.of("id", id);
    }

    @DeleteMapping("/certificates/{id}")
    public Map<String, Object> deleteCertificate(@PathVariable int id) {
        if (db.count("SELECT count(*) FROM user_credentials WHERE catalog_id = :id", "id", id) > 0) throw ApiException.conflict("IN_USE", "已有學生使用這張證照，不能刪除");
        db.exec("DELETE FROM certificate_catalog_skills WHERE catalog_id = :id", "id", id);
        db.exec("DELETE FROM certificate_catalog WHERE id = :id", "id", id);
        return Map.of("ok", true);
    }

    @GetMapping("/clock")
    public Map<String, Object> clock() { return Map.of("now", clock.instant().toString(), "offsetHours", clock.offset().toHours(), "enabled", demoClock); }

    public record ClockIn(Integer hours) {}

    /** Demo：時間快轉並立即執行所有排程，現場展示逾時、提醒、自動結案 */
    @PostMapping("/clock")
    public Map<String, Object> advance(@RequestBody ClockIn in) {
        if (!demoClock) throw ApiException.forbidden("正式環境不允許調整時鐘");
        if (in.hours() == null || in.hours() < 0 || in.hours() > 24 * 365) throw ApiException.badRequest("hours 須介於 0–8760");
        clock.advance(Duration.ofHours(in.hours()));
        Map<String, Object> m = new LinkedHashMap<>(scheduler.runAll());
        m.put("offsetHours", clock.offset().toHours());
        return m;
    }

    @PostMapping("/clock/reset")
    public Map<String, Object> resetClock() { clock.reset(); return clock(); }

    @PostMapping("/run-jobs")
    public Map<String, Object> runJobs() { return scheduler.runAll(); }

    /** 重建 schema 與種子資料（彩排之間使用） */
    @PostMapping("/reset")
    public Map<String, Object> reset() throws Exception {
        if (!demoClock) throw ApiException.forbidden("正式環境不允許重置");
        clock.reset();
        dbInit.reload();
        return Map.of("ok", true, "now", clock.instant().toString());
    }

    // ----- 科目表與科目→技能對照（正式上線：資料來源為學校公告的科目表，對照以規則建議 + 管理員核准） -----

    /** 科目表總覽：各系所 × 學制 × 入學學年度的科目數、已對照技能數 */
    @GetMapping("/courses/summary")
    public Map<String, Object> courseSummary() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("totals", db.one("""
                SELECT count(*) courses, count(*) FILTER (WHERE department_id IS NULL) general,
                       (SELECT count(DISTINCT course_id) FROM course_skill_map WHERE approved) mapped,
                       (SELECT count(*) FROM course_skill_map WHERE NOT approved) pending,
                       (SELECT count(*) FROM departments) departments FROM courses"""));
        m.put("byYear", db.list("SELECT entry_year \"entryYear\", count(*) courses, count(DISTINCT department_id) departments FROM courses WHERE entry_year IS NOT NULL GROUP BY 1 ORDER BY 1 DESC"));
        m.put("programs", db.list("""
                SELECT d.id \"departmentId\", d.name department, c.id \"collegeId\", c.name college, co.degree, co.entry_year \"entryYear\",
                       count(*) courses, count(*) FILTER (WHERE co.requirement = 'REQUIRED') required,
                       count(DISTINCT m.course_id) mapped
                FROM courses co JOIN departments d ON d.id = co.department_id JOIN colleges c ON c.id = d.college_id
                LEFT JOIN course_skill_map m ON m.course_id = co.id AND m.approved
                WHERE co.entry_year IS NOT NULL GROUP BY 1, 2, 3, 4, 5, 6 ORDER BY c.id, d.name, co.degree, co.entry_year DESC"""));
        return m;
    }

    /** 待核准／已核准的對照清單（學生自填 SELF、LLM 建議、規則 RULE） */
    @GetMapping("/course-skills")
    public Object courseSkills(@RequestParam(defaultValue = "false") boolean approved, @RequestParam(required = false) String source,
                               @RequestParam(required = false) String q, @RequestParam(defaultValue = "200") int limit) {
        return db.list("""
                SELECT m.course_id \"courseId\", co.name course, co.code, co.entry_year \"entryYear\", co.degree, d.name department,
                       m.skill_id \"skillId\", s.name skill, s.category, m.source, m.confidence, m.approved,
                       (SELECT count(*) FROM user_grades g WHERE g.course_id = co.id) students
                FROM course_skill_map m JOIN courses co ON co.id = m.course_id JOIN skills s ON s.id = m.skill_id
                LEFT JOIN departments d ON d.id = co.department_id
                WHERE m.approved = :a AND (:src::text IS NULL OR m.source = :src::text) AND (:q::text IS NULL OR co.name ILIKE :q::text OR s.name ILIKE :q::text)
                ORDER BY students DESC, co.entry_year DESC NULLS LAST, co.name, s.name LIMIT :n""",
                "a", approved, "src", source, "q", q == null || q.isBlank() ? null : "%" + q.trim() + "%", "n", Math.min(limit, 1000));
    }

    public record MapIn(Integer courseId, Integer skillId, Boolean approved, Double confidence) {}

    /** 新增或核准對照（approved=true 才會成為課程證據）；核准後重新盤點受影響學生的 Skill Profile */
    @PutMapping("/course-skills")
    public Map<String, Object> upsertMap(@RequestBody MapIn in) {
        if (in.courseId() == null || in.skillId() == null) throw ApiException.badRequest("courseId、skillId 為必填");
        if (db.count("SELECT count(*) FROM courses WHERE id = :c", "c", in.courseId()) == 0) throw ApiException.badRequest("科目不存在");
        if (db.count("SELECT count(*) FROM skills WHERE id = :s", "s", in.skillId()) == 0) throw ApiException.badRequest("技能不存在");
        boolean approved = in.approved() == null || in.approved();
        db.exec("""
                INSERT INTO course_skill_map (course_id, skill_id, source, confidence, approved) VALUES (:c, :s, 'ADMIN', :cf, :a)
                ON CONFLICT (course_id, skill_id) DO UPDATE SET approved = excluded.approved, confidence = excluded.confidence,
                    source = CASE WHEN excluded.approved THEN course_skill_map.source ELSE course_skill_map.source END""",
                "c", in.courseId(), "s", in.skillId(), "cf", in.confidence() == null ? 1.0 : in.confidence(), "a", approved);
        int n = recomputeFor(in.courseId());
        return Map.of("ok", true, "recomputedStudents", n);
    }

    /** 退回／刪除對照 */
    @DeleteMapping("/course-skills/{courseId}/{skillId}")
    public Map<String, Object> deleteMap(@PathVariable int courseId, @PathVariable int skillId) {
        db.exec("DELETE FROM course_skill_map WHERE course_id = :c AND skill_id = :s", "c", courseId, "s", skillId);
        return Map.of("ok", true, "recomputedStudents", recomputeFor(courseId));
    }

    private int recomputeFor(int courseId) { return profile.rebuildForCourse(courseId); }

    public record CourseIn(Integer departmentId, String code, String name, String degree, Integer entryYear, String requirement, String groupCode, Double credits, Integer gradeYear, Integer term, List<Integer> skillIds) {}

    /** 手動新增科目（科目表缺漏、外校／跨校課程） */
    @PostMapping("/courses")
    public Map<String, Object> addCourse(@RequestBody CourseIn in) {
        if (in.name() == null || in.name().isBlank() || in.entryYear() == null) throw ApiException.badRequest("name、entryYear 為必填");
        String deg = in.degree() == null ? "BACHELOR" : in.degree(), req = in.requirement() == null ? "ELECTIVE" : in.requirement();
        if (!Set.of("BACHELOR", "MASTER", "PHD").contains(deg) || !Set.of("REQUIRED", "ELECTIVE", "GENERAL").contains(req)) throw ApiException.badRequest("degree／requirement 不合法");
        Integer id = db.scalar(Integer.class, """
                INSERT INTO courses (department_id, code, name, degree, entry_year, requirement, group_code, credits, grade_year, term, source_url)
                VALUES (:d, :code, :n, :deg, :y, :r, :gc, :cr, :gy, :t, 'manual') ON CONFLICT DO NOTHING RETURNING id""",
                "d", in.departmentId(), "code", in.code(), "n", in.name().trim(), "deg", deg, "y", in.entryYear(), "r", req, "gc", in.groupCode(), "cr", in.credits(), "gy", in.gradeYear(), "t", in.term());
        if (id == null) throw ApiException.conflict("DUPLICATE", "同系所／學制／年度已有同名科目");
        if (in.skillIds() != null) for (Integer sk : in.skillIds()) db.exec("INSERT INTO course_skill_map (course_id, skill_id, source, confidence, approved) VALUES (:c, :s, 'ADMIN', 1.0, TRUE) ON CONFLICT DO NOTHING", "c", id, "s", sk);
        return Map.of("id", id);
    }

    public record DeptIn(String name, Integer collegeId) {}

    /** 修正系所名稱／所屬學院（科目表索引頁的學院標題對部分研究所不準） */
    @PutMapping("/departments/{id}")
    public Map<String, Object> renameDepartment(@PathVariable int id, @RequestBody DeptIn in) {
        if (in.name() != null && !in.name().isBlank()) db.exec("UPDATE departments SET name = :n WHERE id = :id", "n", in.name().trim(), "id", id);
        if (in.collegeId() != null) db.exec("UPDATE departments SET college_id = :c WHERE id = :id", "c", in.collegeId(), "id", id);
        return db.required("SELECT d.id, d.name, d.college_id \"collegeId\", c.name college FROM departments d JOIN colleges c ON c.id = d.college_id WHERE d.id = :id", "系所不存在", "id", id);
    }

    @GetMapping("/event-logs")
    public Object logs(@RequestParam(defaultValue = "100") int limit) {
        return db.list("SELECT l.id, l.actor_id \"actorId\", u.name actor, l.entity, l.entity_id \"entityId\", l.action, l.payload::text payload, l.created_at \"createdAt\" FROM event_logs l LEFT JOIN users u ON u.id = l.actor_id ORDER BY l.id DESC LIMIT :n", "n", Math.min(limit, 500));
    }
}
