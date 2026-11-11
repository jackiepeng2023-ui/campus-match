package tw.edu.fcu.campus.user;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DbInit;
import tw.edu.fcu.campus.llm.ExtractService;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class UserController {
    private final UserService users;
    private final Db db;
    private final DbInit dbInit;
    private final ExtractService extract;

    public UserController(UserService users, Db db, DbInit dbInit, ExtractService extract) { this.users = users; this.db = db; this.dbInit = dbInit; this.extract = extract; }

    // ----- 公開 -----
    @PostMapping("/auth/register") public Map<String, Object> register(@RequestBody UserService.RegisterIn in) { return users.register(in); }
    @PostMapping("/auth/login") public Map<String, Object> login(@RequestBody UserService.LoginIn in) { return users.login(in); }
    @GetMapping("/health") public Map<String, Object> health() { return Map.of("status", dbInit.ready ? "ok" : "starting", "ready", dbInit.ready); }

    /** 表單用參考資料 */
    @GetMapping("/meta")
    public Map<String, Object> meta() {
        return Map.ofEntries(Map.entry("colleges", db.list("SELECT id, name FROM colleges ORDER BY id")),
                Map.entry("departments", db.list("SELECT d.id, d.name, d.college_id \"collegeId\", c.name college FROM departments d JOIN colleges c ON c.id = d.college_id ORDER BY c.id, d.id")),
                Map.entry("skills", db.list("SELECT id, name, category, description FROM skills ORDER BY category, id")),
                Map.entry("currentAcademicYear", users.currentAcademicYear()),      // 科目清單改由 GET /courses 依 系所×學制×入學學年度 查詢（全校兩萬多筆，不再隨 /meta 回傳）
                Map.entry("caseTypes", List.of(Map.of("code", "PROJECT", "label", "專題"), Map.of("code", "COMPETITION", "label", "競賽"),
                        Map.of("code", "SHORT_TERM", "label", "短期支援"), Map.of("code", "RESEARCH", "label", "研究協作"))),
                Map.entry("levelBands", db.list("SELECT degree_group \"degreeGroup\", tier, name, min_score \"minScore\" FROM level_bands ORDER BY degree_group, tier")),
                Map.entry("maxSkillsPerEvidence", db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = 'max_skills_per_evidence'")),
                Map.entry("termsVersion", UserService.TERMS_VERSION),
                Map.entry("certificateCatalog", db.list("""
                        SELECT c.id, c.name, c.issuer, c.score, c.note,
                               (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM certificate_catalog_skills cs JOIN skills s ON s.id = cs.skill_id WHERE cs.catalog_id = c.id) skills
                        FROM certificate_catalog c ORDER BY c.issuer NULLS LAST, c.score, c.name""")),
                Map.entry("awardMatrix", db.list("SELECT rank, level, score FROM award_matrix ORDER BY rank, level")));
    }

    // ----- 本人 -----
    @GetMapping("/me") public Map<String, Object> me() { return users.me(Current.id()); }
    @PutMapping("/me/grades")
    public Map<String, Object> grades(@RequestBody List<UserService.GradeIn> in) {
        int uid = Current.id();
        Map<String, Object> me = users.upsertGrades(uid, in);
        // 還沒有任何技能對照的課：背景擷取課綱並由 AI（或關鍵字）對到 Skill 資料庫的 1–5 個技能，完成後通知學生
        for (UserService.GradeIn g : in) if (g.courseId() != null) extract.enqueueIfUnmapped(g.courseId(), uid);
        return me;
    }
    @DeleteMapping("/me/grades/{id}") public Map<String, Object> deleteGrade(@PathVariable int id) { return users.deleteGrade(Current.id(), id); }
    @PutMapping("/me/skills") public Map<String, Object> skills(@RequestBody List<UserService.SkillIn> in) { return users.upsertSkills(Current.id(), in); }
    @DeleteMapping("/me/skills/{skillId}") public Map<String, Object> deleteSkill(@PathVariable int skillId) { return users.deleteSkill(Current.id(), skillId); }
    /** 證照／作品集／自我評估：自述證據，可附證明連結，由管理員驗證後成為「已驗證」 */
    @PostMapping("/me/credentials") public Map<String, Object> credential(@RequestBody SkillProfileService.CredentialIn in) { return users.addCredential(Current.id(), in); }
    @DeleteMapping("/me/credentials/{id}") public Map<String, Object> deleteCredential(@PathVariable int id) { return users.deleteCredential(Current.id(), id); }
    public record ConsentIn(Boolean agree) {}
    /** AI 助理同意（可隨時撤回；未同意時助理只用規則模式，不呼叫外部 AI） */
    @PostMapping("/me/consents/ai") public Map<String, Object> aiConsent(@RequestBody ConsentIn in) { return users.setAiConsent(Current.id(), in.agree() != null && in.agree()); }
    @PostMapping("/me/awards") public Map<String, Object> award(@RequestBody UserService.AwardIn in) { return users.addAward(Current.id(), in); }
    @DeleteMapping("/me/awards/{id}") public Map<String, Object> deleteAward(@PathVariable int id) { return users.deleteAward(Current.id(), id); }
    @PutMapping("/me/availability") public Map<String, Object> availability(@RequestBody UserService.AvailabilityIn in) { return users.updateAvailability(Current.id(), in); }
    @PostMapping("/me/graduation") public Map<String, Object> graduation(@RequestBody UserService.GraduationIn in) { return users.confirmGraduation(Current.id(), in); }

    @DeleteMapping("/me")
    public ResponseEntity<Void> deleteMe() { users.deleteAccount(Current.id()); return ResponseEntity.noContent().build(); }

    /** 公開檔案：只回傳技能階級與「自述／已驗證」，絕不含分數與原始成績（D16） */
    @GetMapping("/users/{id}") public Map<String, Object> publicProfile(@PathVariable int id) { return users.publicProfile(id); }
}
