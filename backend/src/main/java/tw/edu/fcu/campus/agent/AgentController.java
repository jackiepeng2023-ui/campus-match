package tw.edu.fcu.campus.agent;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;

import java.util.*;

/**
 * 三個媒合 Agent 與其資料（競賽、教師）的 API。
 * Agent 都可以單獨呼叫（網頁的「競賽」「找隊友」「找老師」頁），也可以由 AI 助理當成工具串起來用（/assistant）。
 */
@RestController
@RequestMapping("/api/v1")
public class AgentController {
    private final Db db;
    private final CatalogService catalog;
    private final CompetitionAgent competitionAgent;
    private final StudentAgent studentAgent;
    private final TeacherAgent teacherAgent;
    private final tw.edu.fcu.campus.notify.NotificationService notify;

    public AgentController(Db db, CatalogService catalog, CompetitionAgent competitionAgent, StudentAgent studentAgent, TeacherAgent teacherAgent,
                           tw.edu.fcu.campus.notify.NotificationService notify) {
        this.db = db; this.catalog = catalog; this.competitionAgent = competitionAgent; this.studentAgent = studentAgent; this.teacherAgent = teacherAgent; this.notify = notify;
    }

    // ----- 競賽 Agent -----
    /** 推薦競賽：優點、弱項、能力缺口 */
    @GetMapping("/agents/competitions")
    public Map<String, Object> recommendCompetitions(@RequestParam(required = false) Integer limit, @RequestParam(required = false) String category) {
        return competitionAgent.recommend(Current.id(), limit, category);
    }

    /** 競賽清單（全部已核准的競賽；status=open 只看還能報名的） */
    @GetMapping("/competitions")
    public List<Map<String, Object>> competitions(@RequestParam(required = false) String status, @RequestParam(required = false) String category, @RequestParam(required = false) String q) {
        String kw = q == null || q.isBlank() ? null : q.trim().toLowerCase();
        return catalog.competitions(true).stream().map(catalog::view)
                .filter(m -> status == null || status.isBlank() || "all".equalsIgnoreCase(status) || ("open".equalsIgnoreCase(status) ? !"CLOSED".equals(m.get("status")) : status.equalsIgnoreCase((String) m.get("status"))))
                .filter(m -> category == null || category.isBlank() || category.equals(m.get("category")))
                .filter(m -> kw == null || (m.get("name") + " " + m.get("shortName") + " " + m.get("organizer") + " " + m.get("description")).toLowerCase().contains(kw))
                .toList();
    }

    /** 競賽詳情＋我的契合度（學生）；管理員只看資料 */
    @GetMapping("/competitions/{id}")
    public Map<String, Object> competition(@PathVariable int id) {
        if (Current.isAdmin()) return catalog.view(catalog.competition(id));
        Map<String, Object> m = competitionAgent.fitFor(Current.id(), id);
        m.put("myCases", db.list("""
                SELECT c.id, c.title, c.status FROM cases c WHERE c.competition_id = :c AND c.status NOT IN ('CANCELLED','EXPIRED')
                  AND EXISTS (SELECT 1 FROM case_members m WHERE m.case_id = c.id AND m.user_id = :u) ORDER BY c.id DESC""", "c", id, "u", Current.id()));
        m.put("openTeams", db.list("""
                SELECT c.id, c.title, u.name "ownerName", c.apply_deadline "applyDeadline",
                       (SELECT coalesce(sum(r.headcount - r.filled_count), 0) FROM case_roles r WHERE r.case_id = c.id) seats
                FROM cases c JOIN users u ON u.id = c.owner_id WHERE c.competition_id = :c AND c.status = 'OPEN' ORDER BY c.apply_deadline""", "c", id));
        return m;
    }

    // ----- 學生 Agent -----
    /** 推薦互補隊友：互補原因、團隊缺口、建議組合 */
    @PostMapping("/agents/teammates")
    public Map<String, Object> teammates(@RequestBody StudentAgent.Req req) { return studentAgent.recommend(Current.id(), req); }

    // ----- 教師 Agent -----
    /** 推薦指導老師：專長契合原因、待確認條件 */
    @PostMapping("/agents/teachers")
    public Map<String, Object> recommendTeachers(@RequestBody TeacherAgent.Req req) { return teacherAgent.recommend(Current.id(), req); }

    @GetMapping("/teachers")
    public List<Map<String, Object>> teachers(@RequestParam(required = false) Integer departmentId, @RequestParam(required = false) Integer skillId, @RequestParam(required = false) String q) {
        String kw = q == null || q.isBlank() ? null : q.trim().toLowerCase();
        return catalog.teachers(!Current.isAdmin()).stream()
                .filter(t -> departmentId == null || departmentId.equals(t.departmentId()))
                .filter(t -> skillId == null || t.skills().containsKey(skillId))
                .filter(t -> kw == null || (t.name() + " " + t.department() + " " + t.expertise() + " " + t.research()).toLowerCase().contains(kw))
                .map(catalog::view).toList();
    }

    @GetMapping("/teachers/{id}")
    public Map<String, Object> teacher(@PathVariable int id) {
        Map<String, Object> t = catalog.teacherDetail(id);
        if (!Boolean.TRUE.equals(t.get("active")) && !Current.isAdmin()) throw tw.edu.fcu.campus.common.ApiException.notFound("找不到教師");   // 已下架的教師只有管理員看得到
        return t;
    }

    // ----- 管理：競賽與教師資料（人工維護；AI 擷取的草稿見 /admin/extract/*） -----
    @GetMapping("/admin/competitions")
    public List<Map<String, Object>> adminCompetitions() { return catalog.competitions(false).stream().map(catalog::view).toList(); }

    @PostMapping("/admin/competitions")
    public Map<String, Object> addCompetition(@RequestBody CatalogService.CompIn in) { return catalog.saveCompetition(null, in, "MANUAL"); }

    @PutMapping("/admin/competitions/{id}")
    public Map<String, Object> updateCompetition(@PathVariable int id, @RequestBody CatalogService.CompIn in) { return catalog.saveCompetition(id, in, "MANUAL"); }

    public record ApproveIn(Boolean approved) {}

    @PutMapping("/admin/competitions/{id}/approval")
    public Map<String, Object> approveCompetition(@PathVariable int id, @RequestBody ApproveIn in) {
        catalog.approveCompetition(id, in.approved() == null || in.approved());
        return catalog.view(catalog.competition(id));
    }

    @DeleteMapping("/admin/competitions/{id}")
    public Map<String, Object> deleteCompetition(@PathVariable int id) { catalog.deleteCompetition(id); return Map.of("ok", true); }

    @PostMapping("/admin/teachers")
    public Map<String, Object> addTeacher(@RequestBody CatalogService.TeacherIn in) { return catalog.saveTeacher(null, in, "ADMIN"); }

    @PutMapping("/admin/teachers/{id}")
    public Map<String, Object> updateTeacher(@PathVariable int id, @RequestBody CatalogService.TeacherIn in) { return catalog.saveTeacher(id, in, "ADMIN"); }

    public record ActiveIn(Boolean active) {}

    /** 教師要求下架（或恢復）：停用後不出現在名單與教師 Agent 的推薦裡；資料列保留，之後重新匯入公開網頁也不會被加回來 */
    @PutMapping("/admin/teachers/{id}/active")
    public Map<String, Object> setTeacherActive(@PathVariable int id, @RequestBody ActiveIn in) {
        boolean active = in.active() == null || in.active();
        catalog.setTeacherActive(id, active);
        notify.log(Current.id(), "teacher", id, active ? "ACTIVATE" : "DEACTIVATE", null);
        return catalog.teacherDetail(id);
    }

    /** 核准或退回 AI 對到的教師技能（信心未達門檻者） */
    @PutMapping("/admin/teachers/{id}/skills/{skillId}")
    public Map<String, Object> approveTeacherSkill(@PathVariable int id, @PathVariable int skillId, @RequestBody ApproveIn in) {
        catalog.approveTeacherSkill(id, skillId, in.approved() == null || in.approved());
        return catalog.teacherDetail(id);
    }

    /** 待核准的教師技能（AI 擷取、信心未達門檻） */
    @GetMapping("/admin/teacher-skills/pending")
    public List<Map<String, Object>> pendingTeacherSkills() {
        return db.list("""
                SELECT t.id "teacherId", t.name teacher, d.name department, ts.skill_id "skillId", s.name skill, ts.confidence, ts.source, left(t.expertise, 120) expertise
                FROM teacher_skills ts JOIN teachers t ON t.id = ts.teacher_id JOIN skills s ON s.id = ts.skill_id LEFT JOIN departments d ON d.id = t.department_id
                WHERE NOT ts.approved ORDER BY ts.confidence DESC, t.name LIMIT 300""");
    }
}
