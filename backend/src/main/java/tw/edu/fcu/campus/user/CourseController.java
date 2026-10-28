package tw.edu.fcu.campus.user;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;

import java.util.*;

/**
 * 正式科目表查詢（學生「我的檔案」點選科目用）。
 * 清單來源：逢甲大學註冊課務組各入學學年度「必修科目表／應修學分表」，每個 系所 × 學制 × 入學學年度 一份；
 * 校共同必修與通識（department_id 為 NULL）全校共用。
 */
@RestController
@RequestMapping("/api/v1/courses")
public class CourseController {
    private final Db db;
    private final UserService users;

    public CourseController(Db db, UserService users) { this.db = db; this.users = users; }

    /** 某系所／學制有科目表的入學學年度；另回傳本人的預設選項與最接近的年度（例如 111 入學 → 112 科目表） */
    @GetMapping("/options")
    public Map<String, Object> options(@RequestParam(required = false) Integer departmentId, @RequestParam(required = false) String degree) {
        var me = db.required("SELECT department_id, degree, entry_year FROM users WHERE id = :u", "找不到使用者", "u", Current.id());
        int dep = departmentId != null ? departmentId : Db.i(me.get("department_id"));
        String deg = degree != null ? degree : (String) me.get("degree");
        List<Integer> years = db.jdbc.queryForList("SELECT DISTINCT entry_year FROM courses WHERE department_id = :d AND degree = :g AND entry_year IS NOT NULL ORDER BY entry_year DESC",
                Db.params("d", dep, "g", deg), Integer.class);
        Integer myYear = me.get("entry_year") == null ? null : Db.i(me.get("entry_year"));
        Integer nearest = null;
        if (!years.isEmpty()) {
            int target = myYear != null ? myYear : users.currentAcademicYear();
            nearest = years.stream().min(Comparator.comparingInt((Integer y) -> Math.abs(y - target)).thenComparing(Comparator.reverseOrder())).orElse(null);
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("departmentId", dep); m.put("degree", deg); m.put("entryYear", myYear); m.put("years", years); m.put("nearestYear", nearest);
        m.put("currentAcademicYear", users.currentAcademicYear());
        return m;
    }

    /**
     * 科目清單。requirement：REQUIRED／ELECTIVE／GENERAL（校共同必修＋通識）／省略 = 全部。
     * 每筆附上已核准的技能對照（skills）與待核准的對照（pendingSkills），以及本人已填的分數（myScore／mySemester）。
     */
    @GetMapping
    public List<Map<String, Object>> list(@RequestParam(required = false) Integer departmentId, @RequestParam(required = false) String degree,
                                          @RequestParam(required = false) Integer entryYear, @RequestParam(required = false) String requirement,
                                          @RequestParam(required = false) String q, @RequestParam(defaultValue = "500") int limit) {
        if (q != null && !q.isBlank()) {                                   // 全校搜尋（外系選修、找不到時用）
            return db.list("""
                    SELECT co.id, co.code, co.name, co.requirement, co.group_code "groupCode", co.credits, co.grade_year "gradeYear", co.term, co.entry_year "entryYear",
                           co.degree, co.department_id "departmentId", d.name department,
                           (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map m JOIN skills s ON s.id = m.skill_id WHERE m.course_id = co.id AND m.approved) skills,
                           g.score "myScore", g.semester "mySemester"
                    FROM courses co LEFT JOIN departments d ON d.id = co.department_id
                    LEFT JOIN user_grades g ON g.course_id = co.id AND g.user_id = :u
                    WHERE co.name ILIKE :q OR co.code ILIKE :q
                    ORDER BY (co.entry_year IS NULL), co.entry_year DESC, co.department_id NULLS LAST, co.name LIMIT :n""",
                    "u", Current.id(), "q", "%" + q.trim() + "%", "n", Math.min(limit, 500));
        }
        if (entryYear == null) throw ApiException.badRequest("請指定 entryYear（入學學年度）或 q（關鍵字）");
        boolean general = "GENERAL".equals(requirement);
        if (departmentId == null) throw ApiException.badRequest("請指定 departmentId");
        String deg = degree == null ? "BACHELOR" : degree;
        // 校共同必修／通識：112–114 列在各系科目表內（department_id = 本系）；115 起為全校共用檔（department_id NULL）
        String where = general ? "(co.department_id IS NULL OR co.department_id = :d) AND co.requirement = 'GENERAL' AND co.entry_year = :y AND co.degree = :g"
                : "co.department_id = :d AND co.degree = :g AND co.entry_year = :y" + (requirement == null || requirement.isBlank() ? "" : " AND co.requirement = :r");
        return db.list("""
                SELECT co.id, co.code, co.name, co.requirement, co.group_code "groupCode", co.credits, co.grade_year "gradeYear", co.term, co.entry_year "entryYear",
                       co.degree, co.department_id "departmentId",
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map m JOIN skills s ON s.id = m.skill_id WHERE m.course_id = co.id AND m.approved) skills,
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map m JOIN skills s ON s.id = m.skill_id WHERE m.course_id = co.id AND NOT m.approved) "pendingSkills",
                       g.score "myScore", g.semester "mySemester"
                FROM courses co LEFT JOIN user_grades g ON g.course_id = co.id AND g.user_id = :u
                """ + "WHERE " + where + "\n" + """
                ORDER BY CASE co.requirement WHEN 'REQUIRED' THEN 1 WHEN 'ELECTIVE' THEN 2 ELSE 3 END, co.grade_year NULLS LAST, co.term NULLS LAST, co.group_code NULLS FIRST, co.name
                LIMIT :n""",
                "u", Current.id(), "d", departmentId, "g", deg, "y", entryYear, "r", requirement, "n", Math.min(limit, 2000));
    }
}
