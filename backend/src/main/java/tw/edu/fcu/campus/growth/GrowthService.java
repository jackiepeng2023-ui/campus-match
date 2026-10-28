package tw.edu.fcu.campus.growth;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.user.StatsService;

import java.util.*;

/** M5 成長儀表板（D30）與 AI Prompt（D31–D33） */
@Service
public class GrowthService {
    private final Db db;
    private final StatsService stats;

    public GrowthService(Db db, StatsService stats) { this.db = db; this.stats = stats; }

    public Map<String, Object> growth(int uid) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("radar", db.list("""
                SELECT s.category, round(avg(us.level), 2) "avgLevel", max(us.level) "maxLevel", count(*) n
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u GROUP BY s.category ORDER BY s.category""", "u", uid));
        m.put("skills", db.list("""
                SELECT us.skill_id "skillId", s.name, s.category, us.default_level "defaultLevel", us.level, us.source,
                       (SELECT count(*) FROM skill_level_history h WHERE h.user_id = us.user_id AND h.skill_id = us.skill_id) changes
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY s.category, us.level DESC""", "u", uid));
        m.put("timeline", db.list("""
                SELECT * FROM (
                  SELECT h.changed_at ts, 'SKILL' kind, s.name || '：' || coalesce(h.old_level::text, '—') || ' → ' || h.new_level ||
                         CASE h.reason WHEN 'GRADE' THEN '（成績換算）' WHEN 'SELF_ADJUST' THEN '（自評調整）' WHEN 'SELF_DECLARE' THEN '（自行宣告）' WHEN 'CASE_CLOSED' THEN '（結案驗證）' ELSE '' END AS text,
                         NULL::int AS ref
                  FROM skill_level_history h JOIN skills s ON s.id = h.skill_id WHERE h.user_id = :u
                  UNION ALL
                  SELECT m.joined_at, 'CASE_JOINED', '加入「' || c.title || '」' || coalesce('（' || r.role_name || '）', ''), c.id
                  FROM case_members m JOIN cases c ON c.id = m.case_id LEFT JOIN case_roles r ON r.id = m.case_role_id WHERE m.user_id = :u AND NOT m.is_owner
                  UNION ALL
                  SELECT c.created_at, 'CASE_OWNED', '發起「' || c.title || '」', c.id FROM cases c WHERE c.owner_id = :u AND c.status <> 'DRAFT'
                  UNION ALL
                  SELECT c.closed_at, 'CASE_CLOSED', '「' || c.title || '」結案（' || CASE c.close_result WHEN 'COMPLETED' THEN '完成' ELSE '未完成' END || '）', c.id
                  FROM case_members m JOIN cases c ON c.id = m.case_id WHERE m.user_id = :u AND c.status = 'CLOSED'
                  UNION ALL
                  SELECT a.award_date::timestamptz, 'AWARD', a.competition || ' ' || CASE a.rank WHEN 'FIRST' THEN '第一名' WHEN 'TOP3' THEN '前三名' WHEN 'HONORABLE' THEN '佳作' ELSE '入圍' END, a.id
                  FROM user_awards a WHERE a.user_id = :u
                  UNION ALL
                  SELECT max(r.revealed_at), 'REVIEW', '「' || c.title || '」隊友評價 ' || round(avg((r.satisfaction + r.on_time + r.communication) / 3.0), 1) || '／5，相符度 ' || round(avg(r.match_score), 1), c.id
                  FROM reviews r JOIN cases c ON c.id = r.case_id WHERE r.reviewee_id = :u AND r.revealed_at IS NOT NULL AND r.submitted_at IS NOT NULL
                    AND (SELECT count(*) FROM case_members cm WHERE cm.case_id = c.id) >= 3
                  GROUP BY c.id
                ) t WHERE ts IS NOT NULL ORDER BY ts DESC LIMIT 100""", "u", uid));
        m.put("stats", stats.of(uid).toMap());
        m.put("semesters", db.list("""
                SELECT to_char(h.changed_at AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') AS month, s.category, max(h.new_level) AS level
                FROM skill_level_history h JOIN skills s ON s.id = h.skill_id WHERE h.user_id = :u GROUP BY 1, 2 ORDER BY 1, 2""", "u", uid));
        return m;
    }

    public record PromptIn(String goal, String question) {}

    /** 只放本人的彙總資料（D32）；不含評價者、評語、案件名稱、隊友姓名 */
    public Map<String, Object> prompt(int uid, PromptIn in) {
        if (in.goal() == null || in.goal().isBlank() || in.question() == null || in.question().isBlank())
            throw ApiException.badRequest("請先填寫成長目標與想問的問題");
        var u = db.required("""
                SELECT u.degree, u.year, d.name dept, c.name college, u.expected_graduation grad
                FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges c ON c.id = d.college_id WHERE u.id = :u""", "找不到使用者", "u", uid);
        StringBuilder sb = new StringBuilder();
        sb.append("你是一位大學生涯與技能發展顧問。請根據以下學生資料，提供具體、可執行的成長建議。\n");
        sb.append("資料由學生本人從校園媒合平台匯出，技能等級為 1–5 級。\n\n");
        sb.append("【基本資料】\n學制：").append(degree((String) u.get("degree"))).append("，").append(u.get("year")).append(" 年級，")
          .append(u.get("college")).append("／").append(u.get("dept")).append("，預計畢業：").append(u.get("grad")).append("\n\n");
        sb.append("【技能現況與變化】\n");
        for (var s : db.list("""
                SELECT s.name, us.level, us.default_level dl, us.source,
                       (SELECT string_agg(to_char(h.changed_at AT TIME ZONE 'Asia/Taipei', 'YYYY-MM') || ' ' || coalesce(h.old_level::text, '—') || '→' || h.new_level || '(' ||
                          CASE h.reason WHEN 'GRADE' THEN '成績' WHEN 'SELF_ADJUST' THEN '自評' WHEN 'SELF_DECLARE' THEN '自填' ELSE '結案' END || ')', '、' ORDER BY h.changed_at)
                        FROM skill_level_history h WHERE h.user_id = us.user_id AND h.skill_id = us.skill_id) hist
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY us.level DESC, s.name""", "u", uid))
            sb.append("- ").append(s.get("name")).append("：目前 ").append(s.get("level")).append(" 級").append(s.get("hist") == null ? "" : "；變化：" + s.get("hist")).append("\n");
        sb.append("\n【修課成績】（只有本人可見）\n");
        for (var g : db.list("""
                SELECT co.name, g.score, g.semester, (SELECT string_agg(s.name, '、') FROM course_skill_map m JOIN skills s ON s.id = m.skill_id WHERE m.course_id = co.id AND m.approved) sk
                FROM user_grades g JOIN courses co ON co.id = g.course_id WHERE g.user_id = :u ORDER BY g.semester, co.name""", "u", uid))
            sb.append("- ").append(g.get("name")).append("（").append(g.get("semester")).append("）：").append(g.get("score")).append(" 分").append(g.get("sk") == null ? "" : " → " + g.get("sk")).append("\n");
        sb.append("\n【得獎紀錄】\n");
        var awards = db.list("SELECT competition, level, rank, award_date FROM user_awards WHERE user_id = :u ORDER BY award_date", "u", uid);
        if (awards.isEmpty()) sb.append("- 無\n");
        for (var a : awards) sb.append("- ").append(a.get("competition")).append("，").append(level((String) a.get("level"))).append("，").append(rank((String) a.get("rank"))).append("，").append(a.get("award_date")).append("\n");
        sb.append("\n【合作經歷】\n");
        var exp = db.list("""
                SELECT c.type, coalesce(r.role_name, '發案方') role, count(*) n FROM case_members m JOIN cases c ON c.id = m.case_id LEFT JOIN case_roles r ON r.id = m.case_role_id
                WHERE m.user_id = :u AND c.status IN ('FORMED','IN_PROGRESS','CLOSING','CLOSED') GROUP BY 1, 2 ORDER BY 3 DESC""", "u", uid);
        if (exp.isEmpty()) sb.append("- 尚無成案經歷\n");
        for (var e : exp) sb.append("- ").append(type((String) e.get("type"))).append(" × ").append(e.get("role")).append("：").append(e.get("n")).append(" 次\n");
        var st = stats.of(uid);
        sb.append("隊友評價平均：").append(st.avgRating() == null ? "尚無" : st.avgRating() + "／5").append("；能力與檔案相符度平均：").append(st.avgMatch() == null ? "尚無" : st.avgMatch() + "／5")
          .append("；回應率：").append(Math.round(st.responseRate() * 100)).append("%；完成案件：").append(st.closedCases()).append(" 件\n\n");
        sb.append("【成長目標】\n").append(in.goal().trim()).append("\n\n【我想問的問題】\n").append(in.question().trim()).append("\n\n");
        sb.append("請依序回答：\n1. 目前能力與目標之間的落差（引用上面的具體資料）\n2. 未來一學期最值得補強的 3 項技能，以及原因\n3. 建議修習的課程類型、可參加的競賽或專案類型\n4. 在合作評價上可以改進的地方\n若資料不足以判斷，請直接說明缺少什麼，不要猜測。");
        return Map.of("prompt", sb.toString(), "notice", "此內容將由你選擇的外部 AI 服務處理，適用該服務的隱私政策。內容不含隊友姓名、評語原文與案件名稱；複製前可自行刪改。");
    }

    private static String degree(String d) { return switch (d) { case "MASTER" -> "碩士"; case "PHD" -> "博士"; default -> "學士"; }; }
    private static String level(String l) { return switch (l) { case "NATIONAL" -> "全國"; case "INTERNATIONAL" -> "國際"; default -> "校內"; }; }
    private static String rank(String r) { return switch (r) { case "FIRST" -> "第一名"; case "TOP3" -> "前三名"; case "HONORABLE" -> "佳作"; default -> "入圍"; }; }
    static String type(String t) { return switch (t) { case "COMPETITION" -> "競賽"; case "SHORT_TERM" -> "短期支援"; case "RESEARCH" -> "研究協作"; default -> "專題"; }; }
}
