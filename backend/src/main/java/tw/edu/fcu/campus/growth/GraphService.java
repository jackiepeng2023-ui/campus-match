package tw.edu.fcu.campus.growth;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * 成長儀表板的「知識圖譜」：證據（科目、證照與作品、得獎、結案案件）→ 技能 → 分類，也就是 Skill Profile 的 Evidence → Skill → Level。
 * 同一份資料有兩種輸出：/me/growth/graph（App 內力導向圖）與 /me/growth/obsidian（Obsidian Vault，.md 檔以 [[連結]] 相連，Graph view 直接可看）。
 * 只用本人的資料；案件只到名稱與角色，不含隊友姓名與評語（D32 同一原則）。
 */
@Service
public class GraphService {
    private final Db db;
    private final SkillProfileService profile;

    public GraphService(Db db, SkillProfileService profile) { this.db = db; this.profile = profile; }

    public record Node(String id, String type, String label, Map<String, Object> data) {}
    public record Edge(String source, String target, String kind, double weight) {}

    public static final class Graph {
        public final List<Node> nodes = new ArrayList<>();
        public final List<Edge> edges = new ArrayList<>();
        private final Set<String> ids = new HashSet<>();
        void node(String id, String type, String label, Map<String, Object> data) { if (ids.add(id)) nodes.add(new Node(id, type, label, data)); }
        void edge(String s, String t, String kind, double w) { if (ids.contains(s) && ids.contains(t)) edges.add(new Edge(s, t, kind, w)); }
    }

    public Graph build(int uid) {
        Graph g = new Graph();
        // 技能與分類
        var bands = profile.bands();
        var skills = db.list("""
                SELECT us.skill_id id, s.name, s.category, us.score, us.level, us.trust, us.source, us.evidence_count n
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY s.category, us.score DESC, s.name""", "u", uid);
        Map<String, List<Integer>> byCat = new LinkedHashMap<>();
        for (var s : skills) byCat.computeIfAbsent((String) s.get("category"), k -> new ArrayList<>()).add(Db.i(s.get("score")));
        for (var e : byCat.entrySet()) {
            double avg = e.getValue().stream().mapToInt(Integer::intValue).average().orElse(0);
            g.node("cat:" + e.getKey(), "CATEGORY", e.getKey(), Map.of("avgScore", Math.round(avg * 10) / 10.0, "n", e.getValue().size()));
        }
        for (var s : skills) {
            Map<String, Object> d = new LinkedHashMap<>();
            String trust = (String) s.get("trust");
            d.put("score", s.get("score")); d.put("level", s.get("level")); d.put("tier", bands.nameOf(Db.i(s.get("level"))));
            d.put("trust", trust); d.put("trustLabel", SkillProfileService.trustLabel(trust));
            d.put("category", s.get("category")); d.put("source", SkillProfileService.typeLabel((String) s.get("source"))); d.put("evidenceCount", s.get("n"));
            g.node("skill:" + s.get("id"), "SKILL", (String) s.get("name"), d);
            g.edge("skill:" + s.get("id"), "cat:" + s.get("category"), "CATEGORY", 1.0);
        }
        // 科目（本人成績）→ 技能（只有已核准、且列入證據的對照）
        var courses = db.list("""
                SELECT co.id, co.name, co.code, co.requirement, co.credits, co.entry_year "entryYear", d.name department, g.score, g.semester
                FROM user_grades g JOIN courses co ON co.id = g.course_id LEFT JOIN departments d ON d.id = co.department_id
                WHERE g.user_id = :u ORDER BY g.semester, co.name""", "u", uid);
        for (var c : courses) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("score", c.get("score")); d.put("semester", c.get("semester")); d.put("requirement", c.get("requirement")); d.put("credits", c.get("credits"));
            d.put("department", c.get("department")); d.put("code", c.get("code")); d.put("entryYear", c.get("entryYear"));
            g.node("course:" + c.get("id"), "COURSE", (String) c.get("name"), d);
        }
        for (var m : db.list("""
                SELECT g.course_id cid, e.skill_id sid, coalesce(m.confidence, 1.0) confidence
                FROM skill_evidence e JOIN user_grades g ON g.id = e.ref_id AND g.user_id = e.user_id
                LEFT JOIN course_skill_map m ON m.course_id = g.course_id AND m.skill_id = e.skill_id
                WHERE e.user_id = :u AND e.type = 'COURSE'""", "u", uid))
            g.edge("course:" + m.get("cid"), "skill:" + m.get("sid"), "GRADE", Db.d(m.get("confidence")));
        // 證照與作品集 → 技能（自我評估沒有實體佐證，不成為節點）
        for (var c : db.list("""
                SELECT c.id, c.type, c.title, c.issuer, c.obtained_on "obtainedOn", c.claimed_score score, c.verified, c.proof_url "proofUrl",
                       (SELECT string_agg(cs.skill_id::text, ',') FROM credential_skills cs WHERE cs.credential_id = c.id) sids
                FROM user_credentials c WHERE c.user_id = :u AND c.type IN ('CERTIFICATE','PORTFOLIO') ORDER BY c.id""", "u", uid)) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("kind", SkillProfileService.typeLabel((String) c.get("type"))); d.put("issuer", c.get("issuer"));
            d.put("date", c.get("obtainedOn") == null ? null : String.valueOf(c.get("obtainedOn"))); d.put("score", c.get("score"));
            d.put("tier", bands.nameOf(bands.tierOf(Db.i(c.get("score"))))); d.put("verified", c.get("verified")); d.put("proofUrl", c.get("proofUrl"));
            g.node("cred:" + c.get("id"), "CREDENTIAL", (String) c.get("title"), d);
            if (c.get("sids") != null) for (String sid : ((String) c.get("sids")).split(",")) g.edge("cred:" + c.get("id"), "skill:" + sid, "CREDENTIAL", 1.0);
        }
        // 得獎 → 技能
        for (var a : db.list("""
                SELECT a.id, a.competition, a.level, a.rank, a.award_date "awardDate", am.score, a.verified,
                       (SELECT string_agg(ak.skill_id::text, ',') FROM award_skills ak WHERE ak.award_id = a.id) sids
                FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level WHERE a.user_id = :u ORDER BY a.award_date""", "u", uid)) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("level", a.get("level")); d.put("rank", a.get("rank")); d.put("date", String.valueOf(a.get("awardDate"))); d.put("score", a.get("score"));
            d.put("verified", a.get("verified"));
            g.node("award:" + a.get("id"), "AWARD", (String) a.get("competition"), d);
            if (a.get("sids") != null) for (String sid : ((String) a.get("sids")).split(",")) g.edge("award:" + a.get("id"), "skill:" + sid, "AWARD", 1.0);
        }
        // 結案案件：本人擔任的角色所需技能；隊友互評相符度達門檻者成為「已驗證」證據（實線 1.0），其餘只表示參與（0.5）
        Set<String> caseEvidence = new HashSet<>();
        for (var e : db.list("SELECT ref_id, skill_id FROM skill_evidence WHERE user_id = :u AND type = 'CASE'", "u", uid)) caseEvidence.add(e.get("ref_id") + ":" + e.get("skill_id"));
        for (var c : db.list("""
                SELECT c.id, c.title, c.type, c.close_result "result", c.closed_at "closedAt", r.role_name role, m.is_owner "isOwner",
                       (SELECT string_agg(rs.skill_id::text, ',') FROM case_role_skills rs WHERE rs.case_role_id = m.case_role_id) sids
                FROM case_members m JOIN cases c ON c.id = m.case_id LEFT JOIN case_roles r ON r.id = m.case_role_id
                WHERE m.user_id = :u AND c.status = 'CLOSED' ORDER BY c.closed_at""", "u", uid)) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("caseType", c.get("type")); d.put("result", c.get("result")); d.put("role", c.get("role")); d.put("isOwner", c.get("isOwner"));
            d.put("closedAt", c.get("closedAt") == null ? null : Db.instant(c.get("closedAt")).toString());
            g.node("case:" + c.get("id"), "CASE", (String) c.get("title"), d);
            if (c.get("sids") != null) for (String sid : ((String) c.get("sids")).split(","))
                g.edge("case:" + c.get("id"), "skill:" + sid, "CASE", caseEvidence.contains(c.get("id") + ":" + sid) ? 1.0 : 0.5);
        }
        return g;
    }

    public Map<String, Object> graph(int uid) {
        Graph g = build(uid);
        Map<String, Integer> summary = new LinkedHashMap<>();
        for (Node n : g.nodes) summary.merge(n.type(), 1, Integer::sum);
        return Map.of("nodes", g.nodes, "edges", g.edges, "summary", summary);
    }

    // ---------- Obsidian Vault ----------
    private static final Map<String, String> FOLDER = Map.of("COURSE", "科目", "SKILL", "技能", "CATEGORY", "分類", "AWARD", "得獎", "CASE", "案件", "CREDENTIAL", "證照與作品");
    private static final Map<String, Integer> COLOR = Map.of("科目", 0x0A84FF, "技能", 0x34C759, "分類", 0x5E5CE6, "得獎", 0xFF9F0A, "案件", 0x8E8E93, "證照與作品", 0x30B0C7);

    static String safe(String name) { return name.replaceAll("[\\\\/:*?\"<>|#^\\[\\]]", "_").trim(); }

    static String link(Node n) { return "[[" + FOLDER.get(n.type()) + "/" + safe(n.label()) + "|" + n.label() + "]]"; }

    public byte[] obsidianZip(int uid, String ownerName) throws Exception {
        Graph g = build(uid);
        Map<String, Node> byId = new HashMap<>();
        for (Node n : g.nodes) byId.put(n.id(), n);
        Map<String, List<Edge>> out = new HashMap<>(), in = new HashMap<>();
        for (Edge e : g.edges) { out.computeIfAbsent(e.source(), k -> new ArrayList<>()).add(e); in.computeIfAbsent(e.target(), k -> new ArrayList<>()).add(e); }
        String root = "成長儀表板-" + safe(ownerName) + "/";
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try (ZipOutputStream zip = new ZipOutputStream(bos, StandardCharsets.UTF_8)) {
            for (Node n : g.nodes) {
                StringBuilder sb = new StringBuilder("---\n");
                sb.append("type: ").append(FOLDER.get(n.type())).append("\n");
                for (var e : n.data().entrySet()) if (e.getValue() != null) sb.append(yamlKey(e.getKey())).append(": ").append(yaml(e.getValue())).append("\n");
                sb.append("tags: [").append(FOLDER.get(n.type()));
                if (n.data().get("category") != null) sb.append(", ").append(safe(String.valueOf(n.data().get("category"))));
                sb.append("]\n---\n# ").append(n.label()).append("\n\n");
                switch (n.type()) {
                    case "COURSE" -> {
                        sb.append("分數 **").append(n.data().get("score")).append("**　學期 ").append(n.data().get("semester"))
                          .append("　").append(req(String.valueOf(n.data().get("requirement"))));
                        if (n.data().get("department") != null) sb.append("　").append(n.data().get("department"));
                        sb.append("\n\n## 換算成的技能\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    case "SKILL" -> {
                        sb.append("**").append(n.data().get("tier")).append("**（").append(n.data().get("score")).append(" 分，").append(n.data().get("trustLabel"))
                          .append("；最高分證據：").append(n.data().get("source")).append("；共 ").append(n.data().get("evidenceCount")).append(" 筆證據，不疊加）　分類 ")
                          .append(link(byId.get("cat:" + n.data().get("category")))).append("\n\n");
                        sb.append("## 課程證據\n"); section(sb, filter(in.get(n.id()), "GRADE"), byId, false);
                        sb.append("\n## 證照與作品\n"); section(sb, filter(in.get(n.id()), "CREDENTIAL"), byId, false);
                        sb.append("\n## 競賽得獎\n"); section(sb, filter(in.get(n.id()), "AWARD"), byId, false);
                        sb.append("\n## 結案案件\n"); section(sb, filter(in.get(n.id()), "CASE"), byId, false);
                    }
                    case "CATEGORY" -> {
                        sb.append("平均 **").append(n.data().get("avgScore")).append(" 分**（").append(n.data().get("n")).append(" 項技能）\n\n## 技能\n");
                        section(sb, in.get(n.id()), byId, false);
                    }
                    case "CREDENTIAL" -> {
                        sb.append(n.data().get("kind")).append("　").append(opt(n.data().get("issuer"))).append("　").append(opt(n.data().get("date")))
                          .append("　").append(n.data().get("tier")).append("（").append(Boolean.TRUE.equals(n.data().get("verified")) ? "已驗證" : "自述，尚未驗證").append("）");
                        if (n.data().get("proofUrl") != null) sb.append("\n\n證明：").append(n.data().get("proofUrl"));
                        sb.append("\n\n## 對應技能\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    case "AWARD" -> {
                        sb.append(lvl(String.valueOf(n.data().get("level")))).append("・").append(rank(String.valueOf(n.data().get("rank")))).append("　").append(n.data().get("date"))
                          .append("　得獎分 +").append(n.data().get("score")).append("\n\n## 對應技能\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    case "CASE" -> {
                        sb.append("角色 ").append(opt(n.data().get("role"))).append("　結果 ").append("COMPLETED".equals(n.data().get("result")) ? "完成" : "未完成")
                          .append("　結案 ").append(opt(n.data().get("closedAt")) .replaceAll("T.*", "")).append("\n\n## 角色所需技能（實線＝隊友互評確認）\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    default -> {}
                }
                put(zip, root + FOLDER.get(n.type()) + "/" + safe(n.label()) + ".md", sb.toString());
            }
            // MOC 索引
            StringBuilder moc = new StringBuilder("---\ntags: [索引]\n---\n# 我的成長地圖\n\n由跨系資源媒合平台匯出。開啟左側「Graph view」即可看到 證據（科目、證照與作品、得獎、結案案件）→ 技能 → 分類；顏色已預設（科目藍、證照與作品青、技能綠、分類紫、得獎橘、案件灰）。技能分數取最高分的證據，不疊加。\n\n");
            for (Node cat : g.nodes) if (cat.type().equals("CATEGORY")) {
                moc.append("## ").append(link(cat)).append("（平均 ").append(cat.data().get("avgScore")).append(" 分）\n");
                for (Edge e : in.getOrDefault(cat.id(), List.of())) {
                    Node sk = byId.get(e.source());
                    moc.append("- ").append(link(sk)).append(" 【").append(sk.data().get("tier")).append("・").append(sk.data().get("trustLabel")).append("】");
                    List<String> srcs = new ArrayList<>();
                    for (Edge ie : in.getOrDefault(sk.id(), List.of())) srcs.add(link(byId.get(ie.source())));
                    if (!srcs.isEmpty()) moc.append(" ← ").append(String.join("、", srcs));
                    moc.append("\n");
                }
                moc.append("\n");
            }
            long awards = g.nodes.stream().filter(n -> n.type().equals("AWARD")).count(), cases = g.nodes.stream().filter(n -> n.type().equals("CASE")).count();
            moc.append("## 得獎（").append(awards).append("）\n");
            for (Node n : g.nodes) if (n.type().equals("AWARD")) moc.append("- ").append(link(n)).append("\n");
            moc.append("\n## 證照與作品\n");
            for (Node n : g.nodes) if (n.type().equals("CREDENTIAL")) moc.append("- ").append(link(n)).append("\n");
            moc.append("\n## 結案案件（").append(cases).append("）\n");
            for (Node n : g.nodes) if (n.type().equals("CASE")) moc.append("- ").append(link(n)).append("\n");
            put(zip, root + "我的成長地圖.md", moc.toString());
            put(zip, root + "README.md", """
                    # 使用方式
                    1. 在 Obsidian 選「Open folder as vault」，指到這個資料夾。
                    2. 左側工具列「Open graph view」：科目（藍）、證照與作品（青）、得獎（橘）、結案案件（灰）→ 技能（綠）→ 分類（紫）。
                    3. 在 Graph view 的 Filters 輸入 `path:技能` 只看技能，`tag:#後端` 只看某分類；Local graph 可只看某一門科目周圍。
                    4. 每個 .md 的 frontmatter 有分數／階級／可信狀態／學期，可用 Dataview 等外掛再做表格。

                    資料只含你本人的成績、技能、證照與作品、得獎與參與過的結案案件（名稱與角色），不含隊友姓名與評語。重新匯出會得到最新版本，直接覆蓋資料夾即可。
                    """);
            // Obsidian 圖譜顏色設定
            StringBuilder cg = new StringBuilder();
            for (var e : COLOR.entrySet()) cg.append(cg.length() > 0 ? "," : "").append("{\"query\":\"path:").append(e.getKey()).append("\",\"color\":{\"a\":1,\"rgb\":").append(e.getValue()).append("}}");
            put(zip, root + ".obsidian/graph.json", "{\"collapse-filter\":true,\"search\":\"\",\"showTags\":false,\"showAttachments\":false,\"hideUnresolved\":false,\"showOrphans\":true,"
                    + "\"collapse-color\":false,\"colorGroups\":[" + cg + "],\"collapse-display\":false,\"showArrow\":true,\"textFadeMultiplier\":0,\"nodeSizeMultiplier\":1.2,\"lineSizeMultiplier\":1,"
                    + "\"collapse-forces\":false,\"centerStrength\":0.5,\"repelStrength\":12,\"linkStrength\":1,\"linkDistance\":180,\"scale\":1,\"close\":false}");
            put(zip, root + ".obsidian/app.json", "{}");
        }
        return bos.toByteArray();
    }

    private static List<Edge> filter(List<Edge> es, String kind) { return es == null ? List.of() : es.stream().filter(e -> e.kind().equals(kind)).toList(); }

    private static void section(StringBuilder sb, List<Edge> es, Map<String, Node> byId, boolean target) {
        if (es == null || es.isEmpty()) { sb.append("（無）\n"); return; }
        for (Edge e : es) {
            Node n = byId.get(target ? e.target() : e.source());
            sb.append("- ").append(link(n));
            if (n.type().equals("COURSE")) sb.append("　").append(n.data().get("score")).append(" 分・").append(n.data().get("semester"));
            if (n.type().equals("SKILL")) sb.append("　").append(n.data().get("tier")).append("・").append(n.data().get("trustLabel"));
            if (n.type().equals("CREDENTIAL")) sb.append("　").append(n.data().get("kind")).append("・").append(Boolean.TRUE.equals(n.data().get("verified")) ? "已驗證" : "自述");
            if (e.kind().equals("CASE")) sb.append(e.weight() >= 1.0 ? "　（隊友互評確認）" : "　（參與）");
            if (e.kind().equals("GRADE") && e.weight() < 1.0) sb.append("　（規則信心 ").append(e.weight()).append("）");
            sb.append("\n");
        }
    }

    private static void put(ZipOutputStream zip, String path, String content) throws Exception {
        zip.putNextEntry(new ZipEntry(path)); zip.write(content.getBytes(StandardCharsets.UTF_8)); zip.closeEntry();
    }
    private static String yamlKey(String k) { return k.replaceAll("([A-Z])", "_$1").toLowerCase(); }
    private static String yaml(Object v) { String s = String.valueOf(v); return v instanceof Number || v instanceof Boolean ? s : "\"" + s.replace("\"", "\\\"") + "\""; }
    private static String opt(Object v) { return v == null ? "—" : String.valueOf(v); }
    private static String req(String r) { return switch (r) { case "REQUIRED" -> "必修"; case "GENERAL" -> "校共同／通識"; default -> "選修"; }; }
    private static String lvl(String s) { return switch (s) { case "CAMPUS" -> "校內"; case "NATIONAL" -> "全國"; default -> "國際"; }; }
    private static String rank(String s) { return switch (s) { case "FIRST" -> "第一名"; case "TOP3" -> "前三名"; case "HONORABLE" -> "佳作"; default -> "入圍"; }; }
}
