package tw.edu.fcu.campus.growth;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.common.Db;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

/**
 * 成長儀表板的「知識圖譜」：科目 → 技能 → 分類，再加上得獎與結案案件對技能的驗證。
 * 同一份資料有兩種輸出：/me/growth/graph（App 內力導向圖）與 /me/growth/obsidian（Obsidian Vault，.md 檔以 [[連結]] 相連，Graph view 直接可看）。
 * 只用本人的資料；案件只到名稱與角色，不含隊友姓名與評語（D32 同一原則）。
 */
@Service
public class GraphService {
    private final Db db;

    public GraphService(Db db) { this.db = db; }

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
        var skills = db.list("""
                SELECT us.skill_id id, s.name, s.category, us.level, us.default_level "defaultLevel", us.source
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY s.category, us.level DESC, s.name""", "u", uid);
        Map<String, List<Integer>> byCat = new LinkedHashMap<>();
        for (var s : skills) byCat.computeIfAbsent((String) s.get("category"), k -> new ArrayList<>()).add(Db.i(s.get("level")));
        for (var e : byCat.entrySet()) {
            double avg = e.getValue().stream().mapToInt(Integer::intValue).average().orElse(0);
            g.node("cat:" + e.getKey(), "CATEGORY", e.getKey(), Map.of("avgLevel", Math.round(avg * 100) / 100.0, "n", e.getValue().size()));
        }
        for (var s : skills) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("level", s.get("level")); d.put("defaultLevel", s.get("defaultLevel")); d.put("category", s.get("category")); d.put("source", s.get("source"));
            g.node("skill:" + s.get("id"), "SKILL", (String) s.get("name"), d);
            g.edge("skill:" + s.get("id"), "cat:" + s.get("category"), "CATEGORY", 1.0);
        }
        // 科目（本人成績）→ 技能（只有已核准的對照）
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
                SELECT g.course_id cid, m.skill_id sid, m.confidence FROM user_grades g JOIN course_skill_map m ON m.course_id = g.course_id AND m.approved
                WHERE g.user_id = :u AND m.skill_id IN (SELECT skill_id FROM user_skills WHERE user_id = :u)""", "u", uid))
            g.edge("course:" + m.get("cid"), "skill:" + m.get("sid"), "GRADE", Db.d(m.get("confidence")));
        // 得獎 → 技能
        for (var a : db.list("""
                SELECT a.id, a.competition, a.level, a.rank, a.award_date "awardDate", am.score,
                       (SELECT string_agg(ak.skill_id::text, ',') FROM award_skills ak WHERE ak.award_id = a.id) sids
                FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level WHERE a.user_id = :u ORDER BY a.award_date""", "u", uid)) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("level", a.get("level")); d.put("rank", a.get("rank")); d.put("date", String.valueOf(a.get("awardDate"))); d.put("score", a.get("score"));
            g.node("award:" + a.get("id"), "AWARD", (String) a.get("competition"), d);
            if (a.get("sids") != null) for (String sid : ((String) a.get("sids")).split(",")) g.edge("award:" + a.get("id"), "skill:" + sid, "AWARD", 1.0);
        }
        // 結案案件（本人擔任的角色所需技能 = 被實作驗證過的技能）
        for (var c : db.list("""
                SELECT c.id, c.title, c.type, c.close_result "result", c.closed_at "closedAt", r.role_name role, m.is_owner "isOwner",
                       (SELECT string_agg(rs.skill_id::text, ',') FROM case_role_skills rs WHERE rs.case_role_id = m.case_role_id) sids
                FROM case_members m JOIN cases c ON c.id = m.case_id LEFT JOIN case_roles r ON r.id = m.case_role_id
                WHERE m.user_id = :u AND c.status = 'CLOSED' ORDER BY c.closed_at""", "u", uid)) {
            Map<String, Object> d = new LinkedHashMap<>();
            d.put("type", c.get("type")); d.put("result", c.get("result")); d.put("role", c.get("role")); d.put("isOwner", c.get("isOwner"));
            d.put("closedAt", c.get("closedAt") == null ? null : Db.instant(c.get("closedAt")).toString());
            g.node("case:" + c.get("id"), "CASE", (String) c.get("title"), d);
            if (c.get("sids") != null) for (String sid : ((String) c.get("sids")).split(",")) g.edge("case:" + c.get("id"), "skill:" + sid, "CASE", 1.0);
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
    private static final Map<String, String> FOLDER = Map.of("COURSE", "科目", "SKILL", "技能", "CATEGORY", "分類", "AWARD", "得獎", "CASE", "案件");
    private static final Map<String, Integer> COLOR = Map.of("科目", 0x0A84FF, "技能", 0x34C759, "分類", 0x5E5CE6, "得獎", 0xFF9F0A, "案件", 0x8E8E93);

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
                        sb.append("等級 **").append(n.data().get("level")).append("／5**（預設 ").append(opt(n.data().get("defaultLevel"))).append("，來源 ")
                          .append(src(String.valueOf(n.data().get("source")))).append("）　分類 ").append(link(byId.get("cat:" + n.data().get("category")))).append("\n\n");
                        sb.append("## 來源科目\n"); section(sb, filter(in.get(n.id()), "GRADE"), byId, false);
                        sb.append("\n## 得獎驗證\n"); section(sb, filter(in.get(n.id()), "AWARD"), byId, false);
                        sb.append("\n## 結案驗證\n"); section(sb, filter(in.get(n.id()), "CASE"), byId, false);
                    }
                    case "CATEGORY" -> {
                        sb.append("平均等級 **").append(n.data().get("avgLevel")).append("**（").append(n.data().get("n")).append(" 項技能）\n\n## 技能\n");
                        section(sb, in.get(n.id()), byId, false);
                    }
                    case "AWARD" -> {
                        sb.append(lvl(String.valueOf(n.data().get("level")))).append("・").append(rank(String.valueOf(n.data().get("rank")))).append("　").append(n.data().get("date"))
                          .append("　得獎分 +").append(n.data().get("score")).append("\n\n## 對應技能\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    case "CASE" -> {
                        sb.append("角色 ").append(opt(n.data().get("role"))).append("　結果 ").append("COMPLETED".equals(n.data().get("result")) ? "完成" : "未完成")
                          .append("　結案 ").append(opt(n.data().get("closedAt")) .replaceAll("T.*", "")).append("\n\n## 實作驗證的技能\n");
                        section(sb, out.get(n.id()), byId, true);
                    }
                    default -> {}
                }
                put(zip, root + FOLDER.get(n.type()) + "/" + safe(n.label()) + ".md", sb.toString());
            }
            // MOC 索引
            StringBuilder moc = new StringBuilder("---\ntags: [索引]\n---\n# 我的成長地圖\n\n由跨系資源媒合平台匯出。開啟左側「Graph view」即可看到 科目 → 技能 → 分類，以及得獎與結案案件對技能的驗證；顏色已預設（科目藍、技能綠、分類紫、得獎橘、案件灰）。\n\n");
            for (Node cat : g.nodes) if (cat.type().equals("CATEGORY")) {
                moc.append("## ").append(link(cat)).append("（平均 ").append(cat.data().get("avgLevel")).append("）\n");
                for (Edge e : in.getOrDefault(cat.id(), List.of())) {
                    Node sk = byId.get(e.source());
                    moc.append("- ").append(link(sk)).append(" ").append("★".repeat(Db.i(sk.data().get("level")))).append("☆".repeat(5 - Db.i(sk.data().get("level"))));
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
            moc.append("\n## 結案案件（").append(cases).append("）\n");
            for (Node n : g.nodes) if (n.type().equals("CASE")) moc.append("- ").append(link(n)).append("\n");
            put(zip, root + "我的成長地圖.md", moc.toString());
            put(zip, root + "README.md", """
                    # 使用方式
                    1. 在 Obsidian 選「Open folder as vault」，指到這個資料夾。
                    2. 左側工具列「Open graph view」：科目（藍）→ 技能（綠）→ 分類（紫）；得獎（橘）與結案案件（灰）連到被驗證的技能。
                    3. 在 Graph view 的 Filters 輸入 `path:技能` 只看技能，`tag:#後端` 只看某分類；Local graph 可只看某一門科目周圍。
                    4. 每個 .md 的 frontmatter 有分數／等級／學期，可用 Dataview 等外掛再做表格。

                    資料只含你本人的成績、技能、得獎與參與過的結案案件（名稱與角色），不含隊友姓名與評語。重新匯出會得到最新版本，直接覆蓋資料夾即可。
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
            if (n.type().equals("SKILL")) sb.append("　等級 ").append(n.data().get("level"));
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
    private static String src(String s) { return switch (s) { case "GRADE" -> "成績換算"; case "CASE" -> "結案驗證"; default -> "自填"; }; }
    private static String lvl(String s) { return switch (s) { case "CAMPUS" -> "校內"; case "NATIONAL" -> "全國"; default -> "國際"; }; }
    private static String rank(String s) { return switch (s) { case "FIRST" -> "第一名"; case "TOP3" -> "前三名"; case "HONORABLE" -> "佳作"; default -> "入圍"; }; }
}
