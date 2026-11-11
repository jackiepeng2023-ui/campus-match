package tw.edu.fcu.campus.agent;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.agent.AgentModels.Need;
import tw.edu.fcu.campus.agent.AgentModels.NeedIn;
import tw.edu.fcu.campus.agent.CatalogService.Comp;
import tw.edu.fcu.campus.agent.CatalogService.Teacher;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;

import java.util.*;

import static tw.edu.fcu.campus.agent.AgentModels.round1;
import static tw.edu.fcu.campus.agent.AgentModels.round3;

/**
 * 教師 Agent（專長媒合）：學生需求 × 教師專長 × 研究方向 × 指導經驗 → 推薦教師、專長契合原因、待確認條件。
 *
 * 契合度 = 100 × (0.55 × E 專長 + 0.20 × G 指導經驗 + 0.15 × D 系所 + 0.10 × K 研究方向)
 *   E 專長     = Σ 權重 × 教師該技能的信心 ÷ Σ 權重（核心技能權重 2、輔助 1；教師技能由系所公開的專長文字對到 Skill ID）
 *   G 指導經驗 = 指導經歷提到這個競賽 1.0｜提到同類競賽 0.7｜有其他競賽指導經歷 0.4｜沒有紀錄 0
 *   D 系所     = 與學生同系 1.0｜同學院 0.6｜其他 0.3（跨系指導可行，但要另外確認）
 *   K 研究方向 = 專長與研究方向文字中，提到幾項需求技能（名稱或別名）
 * 至少一項需求技能相符（E > 0）才會推薦。教師不是平台使用者：平台只給建議與待確認清單，由學生自己聯絡。
 */
@Service
public class TeacherAgent {
    private final Db db;
    private final CatalogService catalog;

    public TeacherAgent(Db db, CatalogService catalog) { this.db = db; this.catalog = catalog; }

    public record Req(Integer competitionId, Integer caseId, List<NeedIn> skills, String topic, Integer limit) {}

    private static final Map<String, List<String>> CATEGORY_WORDS = Map.ofEntries(
            Map.entry("資訊應用", List.of("資訊", "軟體", "App", "系統", "應用", "創新")), Map.entry("AI 與資料", List.of("AI", "人工智慧", "資料", "機器學習", "深度學習", "數據")),
            Map.entry("程式設計", List.of("程式", "ICPC", "演算法", "CPE")), Map.entry("資安", List.of("資安", "資訊安全", "CTF", "金盾")),
            Map.entry("創新創業", List.of("創新", "創業", "創意")), Map.entry("商管企劃", List.of("企劃", "行銷", "商業", "個案", "管理")),
            Map.entry("設計", List.of("設計")), Map.entry("工程實作", List.of("專題", "實作", "機器人", "創客", "自走車", "工程")),
            Map.entry("土木建築", List.of("土木", "建築", "結構", "橋", "營建")), Map.entry("語文", List.of("英語", "英文", "日語", "演講", "寫作")),
            Map.entry("跨域", List.of("跨域", "跨領域", "永續", "創新")));

    public record Score(double fit, double e, double g, double d, double k, List<Need> matched, List<Need> missing, String coachingHit) {}

    /**
     * 純函式：一位教師對一組需求的契合度。
     * aliases：skillId → 名稱與別名（用來在研究方向文字裡找關鍵字）；compNames：競賽名稱與簡稱；category：競賽分類。
     */
    public static Score score(Teacher t, List<Need> needs, Map<Integer, List<String>> aliases, String studentDept, String studentCollege,
                              List<String> compNames, String category, List<String> topicWords) {
        double wsum = 0, esum = 0;
        List<Need> matched = new ArrayList<>(), missing = new ArrayList<>();
        String text = (nz(t.expertise()) + " " + nz(t.research())).toLowerCase();
        int kHits = 0, kTotal = 0;
        for (Need n : needs) {
            Double conf = t.skills().get(n.skillId());
            wsum += n.weight();
            if (conf != null) { esum += n.weight() * conf; matched.add(n); } else missing.add(n);
            kTotal++;
            for (String a : aliases.getOrDefault(n.skillId(), List.of(n.name())))
                if (a.length() >= 2 && text.contains(a.toLowerCase())) { kHits++; break; }
        }
        for (String wd : topicWords) { kTotal++; if (wd.length() >= 2 && text.contains(wd.toLowerCase())) kHits++; }
        double e = wsum == 0 ? 0 : esum / wsum;
        double k = kTotal == 0 ? 0 : (double) kHits / kTotal;

        String coaching = nz(t.coaching());
        double g = 0; String hit = null;
        if (!coaching.isBlank()) {
            g = 0.4; hit = "有競賽指導經歷";
            for (String wd : CATEGORY_WORDS.getOrDefault(nz(category), List.of()))
                if (coaching.toLowerCase().contains(wd.toLowerCase())) { g = 0.7; hit = "指導過同類競賽（" + wd + "）"; break; }
            for (String name : compNames)
                if (name != null && name.length() >= 3 && coaching.toLowerCase().contains(name.toLowerCase())) { g = 1.0; hit = "指導過這個競賽（" + name + "）"; break; }
        }
        double d = t.department() != null && t.department().equals(studentDept) ? 1.0 : t.college() != null && t.college().equals(studentCollege) ? 0.6 : 0.3;
        double fit = 100 * (0.55 * e + 0.20 * g + 0.15 * d + 0.10 * k);
        return new Score(round1(fit), round3(e), round3(g), round3(d), round3(k), matched, missing, hit);
    }

    private static String nz(String s) { return s == null ? "" : s; }
    private static String excerpt(String s, int n) { s = nz(s).trim(); return s.length() <= n ? s : s.substring(0, n) + "…"; }

    public Map<String, Object> recommend(int uid, Req req) {
        var me = db.required("""
                SELECT d.name dept, c.name college FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges c ON c.id = d.college_id WHERE u.id = :u""", "找不到使用者", "u", uid);
        Comp comp = null;
        List<Need> needs;
        String title;
        if (req.competitionId() != null) { comp = catalog.competition(req.competitionId()); needs = comp.needs(); title = comp.display(); }
        else if (req.caseId() != null) {
            var c = db.required("SELECT title, competition_id FROM cases WHERE id = :c", "找不到案件", "c", req.caseId());
            needs = catalog.needsOfCase(req.caseId()); title = (String) c.get("title");
            if (c.get("competition_id") != null) comp = catalog.competition(Db.i(c.get("competition_id")));
        } else { needs = catalog.needs(req.skills()); title = req.topic() == null || req.topic().isBlank() ? "自訂需求" : req.topic().trim(); }
        List<String> topicWords = req.topic() == null ? List.of() : Arrays.stream(req.topic().split("[\\s,，、;；]+")).filter(x -> x.length() >= 2).limit(8).toList();
        if (needs.isEmpty() && topicWords.isEmpty()) throw ApiException.badRequest("請指定競賽（competitionId）、案件（caseId）、需求技能（skills）或主題關鍵字（topic）");

        Map<Integer, List<String>> aliases = new HashMap<>();
        for (var r : db.list("SELECT id, name, aliases FROM skills")) {
            List<String> a = new ArrayList<>(List.of((String) r.get("name")));
            for (String x : nz((String) r.get("aliases")).split(",")) if (!x.isBlank()) a.add(x.trim());
            aliases.put(Db.i(r.get("id")), a);
        }
        Map<Integer, Integer> load = new HashMap<>();
        for (var r : db.list("SELECT advisor_teacher_id t, count(*) n FROM cases WHERE advisor_teacher_id IS NOT NULL AND status IN ('OPEN','FORMED','IN_PROGRESS','CLOSING') GROUP BY 1"))
            load.put(Db.i(r.get("t")), Db.i(r.get("n")));
        List<String> compNames = comp == null ? List.of() : Arrays.asList(comp.name(), comp.shortName());
        List<Teacher> all = catalog.teachers(true);
        List<Map<String, Object>> out = new ArrayList<>();
        for (Teacher t : all) {
            Score s = score(t, needs, aliases, (String) me.get("dept"), (String) me.get("college"), compNames, comp == null ? null : comp.category(), topicWords);
            if (needs.isEmpty() ? s.k() == 0 : s.e() == 0) continue;            // 沒有任何專長相符：不推薦
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("teacherId", t.id()); m.put("name", t.name()); m.put("title", t.title()); m.put("department", t.department()); m.put("college", t.college());
            m.put("fit", s.fit()); m.put("breakdown", Map.of("E", s.e(), "G", s.g(), "D", s.d(), "K", s.k()));
            m.put("matchedSkills", s.matched().stream().map(n -> Map.of("skillId", n.skillId(), "name", n.name(), "importance", n.importance(), "confidence", t.skills().get(n.skillId()))).toList());
            m.put("missingSkills", s.missing().stream().map(Need::name).toList());
            m.put("expertise", excerpt(t.expertise(), 160)); m.put("research", excerpt(t.research(), 200)); m.put("coaching", excerpt(t.coaching(), 200));
            m.put("profileUrl", t.profileUrl()); m.put("sourceUrl", t.sourceUrl()); m.put("crawledAt", t.crawledAt());
            int teams = load.getOrDefault(t.id(), 0);
            m.put("platformTeams", teams);

            List<String> why = new ArrayList<>();
            if (!s.matched().isEmpty()) why.add("專長涵蓋需求技能 " + s.matched().size() + "／" + needs.size() + "：" + String.join("、", s.matched().stream().map(n -> n.name() + (n.core() ? "［核心］" : "")).toList()));
            if (!nz(t.expertise()).isBlank()) why.add("系所網頁列出的專長：" + excerpt(t.expertise(), 60));
            if (s.coachingHit() != null) why.add(s.coachingHit() + "：" + excerpt(t.coaching(), 60));
            why.add(s.d() == 1.0 ? "與你同系（" + t.department() + "）" : s.d() == 0.6 ? "與你同學院（" + t.department() + "）" : "跨學院（" + nz(t.college()) + "・" + nz(t.department()) + "）");
            m.put("reasons", why);

            List<String> confirm = new ArrayList<>();
            confirm.add("老師本學期是否還能指導隊伍（平台沒有教師的時間與名額資料）");
            if (comp != null && Boolean.TRUE.equals(comp.advisorRequired())) confirm.add("這個競賽必須有指導老師，報名前要先取得老師同意" + (comp.deadline() == null ? "" : "（報名截止 " + comp.deadline() + "）"));
            if (s.d() < 1.0) confirm.add("跨系指導：確認老師是否願意指導外系學生，以及系上是否有相關規定");
            if (nz(t.coaching()).isBlank()) confirm.add("系所網頁沒有列出競賽指導經歷，需當面確認");
            if (!s.missing().isEmpty()) confirm.add("需求中的 " + String.join("、", s.missing().stream().map(Need::name).limit(3).toList()) + " 不在老師公開的專長內，可能需要第二位老師或自行補強");
            if (teams > 0) confirm.add("平台上已有 " + teams + " 個進行中的隊伍填這位老師為指導老師");
            confirm.add("資料來自系所公開網頁" + (t.crawledAt() == null ? "" : "（擷取日 " + t.crawledAt() + "）") + "，請以老師本人說明為準");
            m.put("toConfirm", confirm);
            out.add(m);
        }
        out.sort(Comparator.<Map<String, Object>>comparingDouble(m -> -(double) m.get("fit")).thenComparingInt(m -> (int) m.get("platformTeams")));
        int limit = req.limit() == null ? 5 : Math.max(1, Math.min(req.limit(), 30));
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("agent", "TEACHER");
        Map<String, Object> ctx = new LinkedHashMap<>();
        ctx.put("title", title); ctx.put("competitionId", comp == null ? null : comp.id()); ctx.put("advisorRequired", comp == null ? null : comp.advisorRequired());
        res.put("context", ctx);
        res.put("needs", needs.stream().map(n -> Map.of("skillId", n.skillId(), "name", n.name(), "importance", n.importance())).toList());
        res.put("teachers", out.subList(0, Math.min(limit, out.size())));
        res.put("totalMatched", out.size());
        res.put("trace", List.of(
                "學生需求：「" + title + "」" + needs.size() + " 項技能" + (topicWords.isEmpty() ? "" : "＋關鍵字 " + String.join("、", topicWords)),
                "教師資料庫 " + all.size() + " 位（系所公開網頁）→ 至少一項專長相符 " + out.size() + " 位",
                "契合度 = 55% 專長 + 20% 指導經驗 + 15% 系所 + 10% 研究方向",
                "回傳前 " + Math.min(limit, out.size()) + " 位，各附專長契合原因與待確認條件"));
        return res;
    }
}
