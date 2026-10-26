package tw.edu.fcu.campus.user;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DbInit;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class UserController {
    private final UserService users;
    private final Db db;
    private final DbInit dbInit;

    public UserController(UserService users, Db db, DbInit dbInit) { this.users = users; this.db = db; this.dbInit = dbInit; }

    // ----- 公開 -----
    @PostMapping("/auth/register") public Map<String, Object> register(@RequestBody UserService.RegisterIn in) { return users.register(in); }
    @PostMapping("/auth/login") public Map<String, Object> login(@RequestBody UserService.LoginIn in) { return users.login(in); }
    @GetMapping("/health") public Map<String, Object> health() { return Map.of("status", dbInit.ready ? "ok" : "starting", "ready", dbInit.ready); }

    /** 表單用參考資料 */
    @GetMapping("/meta")
    public Map<String, Object> meta() {
        return Map.of(
                "colleges", db.list("SELECT id, name FROM colleges ORDER BY id"),
                "departments", db.list("SELECT d.id, d.name, d.college_id \"collegeId\", c.name college FROM departments d JOIN colleges c ON c.id = d.college_id ORDER BY d.id"),
                "skills", db.list("SELECT id, name, category FROM skills ORDER BY category, id"),
                "courses", db.list("""
                        SELECT co.id, co.name, co.department_id "departmentId", co.is_graduate "isGraduate",
                               (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map m JOIN skills s ON s.id = m.skill_id WHERE m.course_id = co.id) skills
                        FROM courses co ORDER BY co.department_id NULLS LAST, co.name"""),
                "caseTypes", List.of(Map.of("code", "PROJECT", "label", "專題"), Map.of("code", "COMPETITION", "label", "競賽"),
                        Map.of("code", "SHORT_TERM", "label", "短期支援"), Map.of("code", "RESEARCH", "label", "研究協作")),
                "gradeConversion", db.list("SELECT degree_group \"degreeGroup\", min_score \"minScore\", level FROM grade_conversion ORDER BY degree_group, min_score DESC"),
                "awardMatrix", db.list("SELECT rank, level, score FROM award_matrix ORDER BY rank, level"));
    }

    // ----- 本人 -----
    @GetMapping("/me") public Map<String, Object> me() { return users.me(Current.id()); }
    @PutMapping("/me/grades") public Map<String, Object> grades(@RequestBody List<UserService.GradeIn> in) { return users.upsertGrades(Current.id(), in); }
    @DeleteMapping("/me/grades/{id}") public Map<String, Object> deleteGrade(@PathVariable int id) { return users.deleteGrade(Current.id(), id); }
    @PutMapping("/me/skills") public Map<String, Object> skills(@RequestBody List<UserService.SkillIn> in) { return users.upsertSkills(Current.id(), in); }
    @DeleteMapping("/me/skills/{skillId}") public Map<String, Object> deleteSkill(@PathVariable int skillId) { return users.deleteSkill(Current.id(), skillId); }
    @PostMapping("/me/awards") public Map<String, Object> award(@RequestBody UserService.AwardIn in) { return users.addAward(Current.id(), in); }
    @DeleteMapping("/me/awards/{id}") public Map<String, Object> deleteAward(@PathVariable int id) { return users.deleteAward(Current.id(), id); }
    @PutMapping("/me/availability") public Map<String, Object> availability(@RequestBody UserService.AvailabilityIn in) { return users.updateAvailability(Current.id(), in); }
    @PostMapping("/me/graduation") public Map<String, Object> graduation(@RequestBody UserService.GraduationIn in) { return users.confirmGraduation(Current.id(), in); }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMe() { users.deleteAccount(Current.id()); return ResponseEntity.noContent().build(); }

    /** 公開檔案：只回傳技能等級，絕不含原始分數 */
    @GetMapping("/users/{id}") public Map<String, Object> publicProfile(@PathVariable int id) { return users.publicProfile(id); }
}
