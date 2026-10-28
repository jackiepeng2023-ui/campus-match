package tw.edu.fcu.campus.admin;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DbInit;
import tw.edu.fcu.campus.config.DemoClock;

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
    private final boolean demoClock;

    public AdminController(Db db, DemoClock clock, SchedulerService scheduler, DbInit dbInit, UserService users, @Value("${app.demo-clock}") boolean demoClock) {
        this.db = db; this.clock = clock; this.scheduler = scheduler; this.dbInit = dbInit; this.users = users; this.demoClock = demoClock;
    }

    @GetMapping("/params")
    public Map<String, Object> params() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("weights", db.list("SELECT key, value, label FROM ranking_weights ORDER BY CASE key WHEN 'S' THEN 1 WHEN 'T' THEN 2 WHEN 'R' THEN 3 WHEN 'P' THEN 4 ELSE 5 END"));
        m.put("credibility", db.list("SELECT match_level \"matchLevel\", coefficient FROM credibility_coefficients ORDER BY match_level DESC"));
        m.put("awardMatrix", db.list("SELECT rank, level, score FROM award_matrix ORDER BY CASE rank WHEN 'FIRST' THEN 1 WHEN 'TOP3' THEN 2 WHEN 'HONORABLE' THEN 3 ELSE 4 END, CASE level WHEN 'CAMPUS' THEN 1 WHEN 'NATIONAL' THEN 2 ELSE 3 END"));
        m.put("params", db.list("SELECT key, value, label FROM system_params ORDER BY key"));
        return m;
    }

    public record ParamsIn(Map<String, Double> weights, Map<String, Double> credibility, Map<String, Integer> params, Map<String, Double> awardMatrix) {}

    @PutMapping("/params")
    public Map<String, Object> update(@RequestBody ParamsIn in) {
        if (in.weights() != null) {
            double sum = in.weights().values().stream().mapToDouble(Double::doubleValue).sum();
            if (Math.abs(sum - 1.0) > 0.001) throw ApiException.badRequest("權重總和必須為 1.0（目前 " + sum + "）");
            for (var e : in.weights().entrySet()) db.exec("UPDATE ranking_weights SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
        }
        if (in.credibility() != null) for (var e : in.credibility().entrySet()) db.exec("UPDATE credibility_coefficients SET coefficient = :v WHERE match_level = :k", "v", e.getValue(), "k", Integer.parseInt(e.getKey()));
        if (in.params() != null) for (var e : in.params().entrySet()) db.exec("UPDATE system_params SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
        if (in.awardMatrix() != null) for (var e : in.awardMatrix().entrySet()) {
            String[] rl = e.getKey().split("/");
            db.exec("UPDATE award_matrix SET score = :v WHERE rank = :r AND level = :l", "v", e.getValue(), "r", rl[0], "l", rl[1]);
        }
        return params();
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

    /** 新增或核准對照（approved=true 才會換算技能等級）；核准後重算受影響學生的預設等級 */
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

    private int recomputeFor(int courseId) {
        var uids = db.list("SELECT DISTINCT user_id FROM user_grades WHERE course_id = :c", "c", courseId);
        for (var r : uids) users.recomputeDefaults(Db.i(r.get("user_id")));
        return uids.size();
    }

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
