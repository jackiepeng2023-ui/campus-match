package tw.edu.fcu.campus.growth;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;

import java.util.LinkedHashMap;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class GrowthController {
    private final GrowthService growth;
    private final Db db;

    private final GraphService graphs;

    public GrowthController(GrowthService growth, GraphService graphs, Db db) { this.growth = growth; this.graphs = graphs; this.db = db; }

    @GetMapping("/me/growth") public Map<String, Object> growth() { return growth.growth(Current.id()); }

    /** 知識圖譜：科目 → 技能 → 分類 ＋ 得獎／結案案件 → 技能（App 內力導向圖用） */
    @GetMapping("/me/growth/graph") public Map<String, Object> graph() { return graphs.graph(Current.id()); }

    /** 同一份圖譜匯出成 Obsidian Vault（zip 內含 .md 與 [[連結]]、預設圖譜顏色） */
    @GetMapping(value = "/me/growth/obsidian", produces = "application/zip")
    public ResponseEntity<byte[]> obsidian() throws Exception {
        var p = Current.principal();
        byte[] zip = graphs.obsidianZip(p.id(), p.name());
        String ascii = "growth-vault-" + p.id() + ".zip", utf8 = URLEncoder.encode("成長儀表板-" + p.name() + ".zip", StandardCharsets.UTF_8).replace("+", "%20");
        return ResponseEntity.ok().header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + ascii + "\"; filename*=UTF-8''" + utf8)
                .contentType(MediaType.parseMediaType("application/zip")).body(zip);
    }
    @PostMapping("/me/growth-prompt") public Map<String, Object> prompt(@RequestBody GrowthService.PromptIn in) { return growth.prompt(Current.id(), in); }

    // ----- 資料分析（ADMIN） -----
    @GetMapping("/analytics/overview")
    public Map<String, Object> overview() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("students", db.count("SELECT count(*) FROM users WHERE role = 'STUDENT' AND deidentified_at IS NULL"));
        m.put("casesByStatus", db.list("SELECT status, count(*) n FROM cases GROUP BY status ORDER BY status"));
        m.put("casesByType", db.list("SELECT type, count(*) n FROM cases WHERE status <> 'DRAFT' GROUP BY type ORDER BY type"));
        m.put("engagementsByStatus", db.list("SELECT direction, status, count(*) n FROM engagements GROUP BY direction, status ORDER BY direction, status"));
        m.put("reviews", db.one("SELECT count(*) total, count(*) FILTER (WHERE submitted_at IS NOT NULL) submitted, count(*) FILTER (WHERE missed) missed, round(avg(match_score), 2) \"avgMatch\" FROM reviews"));
        m.put("degrees", db.list("SELECT degree, count(*) n FROM users WHERE role = 'STUDENT' AND deidentified_at IS NULL GROUP BY degree ORDER BY degree"));
        return m;
    }

    /** 技能供需缺口：供給 = 等級 ≥ 3 的人數，需求 = 招募中角色尚缺名額 */
    @GetMapping("/analytics/skill-gap")
    public List<Map<String, Object>> skillGap() {
        return db.list("""
                SELECT s.category, s.name skill,
                       (SELECT count(*) FROM user_skills us JOIN users u ON u.id = us.user_id WHERE us.skill_id = s.id AND us.level >= 3 AND u.deidentified_at IS NULL) supply,
                       (SELECT coalesce(sum(r.headcount - r.filled_count), 0) FROM case_role_skills rs JOIN case_roles r ON r.id = rs.case_role_id JOIN cases c ON c.id = r.case_id
                        WHERE rs.skill_id = s.id AND c.status = 'OPEN') demand
                FROM skills s ORDER BY demand DESC, supply ASC, s.category, s.name""");
    }

    /** 媒合漏斗：發布 → 有申請或邀請 → 有成立 → 成案 → 結案 */
    @GetMapping("/analytics/funnel")
    public List<Map<String, Object>> funnel() {
        return db.list("""
                SELECT '發布' stage, count(*) n FROM cases WHERE status <> 'DRAFT'
                UNION ALL SELECT '有申請或邀請', count(DISTINCT r.case_id) FROM engagements e JOIN case_roles r ON r.id = e.case_role_id
                UNION ALL SELECT '有成立', count(DISTINCT r.case_id) FROM engagements e JOIN case_roles r ON r.id = e.case_role_id WHERE e.status = 'ACCEPTED'
                UNION ALL SELECT '成案', count(*) FROM cases WHERE status IN ('FORMED','IN_PROGRESS','CLOSING','CLOSED')
                UNION ALL SELECT '結案', count(*) FROM cases WHERE status = 'CLOSED'""");
    }

    /** 跨系合作網絡：成案成員兩兩配對的學院組合 */
    @GetMapping("/analytics/network")
    public List<Map<String, Object>> network() {
        return db.list("""
                SELECT least(c1.name, c2.name) a, greatest(c1.name, c2.name) b, count(*) n
                FROM case_members m1 JOIN case_members m2 ON m1.case_id = m2.case_id AND m1.user_id < m2.user_id
                JOIN cases cs ON cs.id = m1.case_id AND cs.status IN ('FORMED','IN_PROGRESS','CLOSING','CLOSED')
                JOIN users u1 ON u1.id = m1.user_id JOIN departments d1 ON d1.id = u1.department_id JOIN colleges c1 ON c1.id = d1.college_id
                JOIN users u2 ON u2.id = m2.user_id JOIN departments d2 ON d2.id = u2.department_id JOIN colleges c2 ON c2.id = d2.college_id
                GROUP BY 1, 2 ORDER BY n DESC""");
    }

    /** 推薦品質：被核准者在推薦快照中的名次 */
    @GetMapping("/analytics/recommendation-quality")
    public Map<String, Object> quality() {
        var r = db.one("""
                SELECT count(*) accepted, count(rc.rank) "inSnapshot", round(avg(rc.rank), 2) "avgRank",
                       count(*) FILTER (WHERE rc.rank <= 5) "top5"
                FROM engagements e LEFT JOIN recommendations rc ON rc.case_role_id = e.case_role_id AND rc.user_id = e.user_id
                WHERE e.status = 'ACCEPTED'""");
        return r == null ? Map.of() : r;
    }
}
