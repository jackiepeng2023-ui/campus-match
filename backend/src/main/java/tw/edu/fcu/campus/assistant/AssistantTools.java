package tw.edu.fcu.campus.assistant;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.agent.AgentModels.NeedIn;
import tw.edu.fcu.campus.agent.CatalogService;
import tw.edu.fcu.campus.agent.CompetitionAgent;
import tw.edu.fcu.campus.agent.StudentAgent;
import tw.edu.fcu.campus.agent.TeacherAgent;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.profile.SkillProfileService;
import tw.edu.fcu.campus.ranking.RankingService;
import tw.edu.fcu.campus.user.StatsService;

import java.time.LocalDate;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * AI 助理可以呼叫的工具：能力盤點模組＋三個媒合 Agent＋「待確認動作」。
 *
 * 每個工具回傳兩份內容：
 *   forModel  給語言模型看的精簡結果 —— 其他學生一律以代號（[[S1]]）出現，沒有姓名、學號、分數；只有階級與可信狀態。
 *   card      給畫面用的完整結果（含姓名），由伺服器直接組成，不經過語言模型，所以數字與名單不會被改寫。
 * 會改變資料的事（建立案件、送邀請）只產生待確認動作（agent_actions，PENDING），使用者按下確認才執行。
 */
@Service
public class AssistantTools {
    private final Db db;
    private final CatalogService catalog;
    private final CompetitionAgent competitionAgent;
    private final StudentAgent studentAgent;
    private final TeacherAgent teacherAgent;
    private final SkillProfileService profile;
    private final RankingService ranking;
    private final StatsService stats;
    /** 日期一律輸出成 ISO 字串（2026-11-20）：卡片、工具結果、軌跡與輸出檢核都用同一種寫法，不會出現 [2026,11,20] 這種陣列 */
    private final ObjectMapper json = new ObjectMapper().findAndRegisterModules().disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public AssistantTools(Db db, CatalogService catalog, CompetitionAgent competitionAgent, StudentAgent studentAgent, TeacherAgent teacherAgent,
                          SkillProfileService profile, RankingService ranking, StatsService stats) {
        this.db = db; this.catalog = catalog; this.competitionAgent = competitionAgent; this.studentAgent = studentAgent; this.teacherAgent = teacherAgent;
        this.profile = profile; this.ranking = ranking; this.stats = stats;
    }

    public record Result(String agent, String summary, JsonNode forModel, Map<String, Object> card, boolean error) {}

    /** 一個對話的可變脈絡：學生代號表與最近談到的對象（存回 agent_sessions） */
    public static final class Turn {
        public final int uid, sessionId;
        public final Map<String, Integer> aliases;
        public final Map<String, Object> state;
        public Turn(int uid, int sessionId, Map<String, Integer> aliases, Map<String, Object> state) { this.uid = uid; this.sessionId = sessionId; this.aliases = aliases; this.state = state; }

        public String alias(int userId) {
            for (var e : aliases.entrySet()) if (e.getValue() == userId) return "[[" + e.getKey() + "]]";
            String a = "S" + (aliases.size() + 1);
            aliases.put(a, userId);
            return "[[" + a + "]]";
        }
        public Integer userOf(String token) {
            if (token == null) return null;
            Matcher m = Pattern.compile("S\\d+").matcher(token.toUpperCase());
            return m.find() ? aliases.get(m.group()) : null;
        }
    }

    // ---------- 工具定義 ----------
    public static final List<String> CATEGORIES = List.of("資訊應用", "AI 與資料", "程式設計", "資安", "創新創業", "商管企劃", "設計", "工程實作", "土木建築", "語文", "跨域");

    public ArrayNode definitions() {
        ArrayNode tools = json.createArrayNode();
        tool(tools, "get_my_skill_profile",
                "能力盤點模組：讀取目前使用者的 Skill Profile —— 每項技能的階級（初階／中階／進階）、可信狀態（已驗證／修課成績／自述）、證據類型，以及學制、系所、每週可投入時數。"
                        + "規劃任何推薦之前先呼叫一次，回覆時用它說明使用者的強項與不足。", obj());
        ObjectNode p = obj();
        p.with("properties").putObject("category").put("type", "string").put("description", "只看某一類競賽（選填）").set("enum", json.valueToTree(CATEGORIES));
        p.with("properties").putObject("limit").put("type", "integer").put("description", "回傳幾筆，預設 5");
        tool(tools, "recommend_competitions",
                "競賽 Agent：依使用者的 Skill Profile、參賽資格與各競賽所需技能，推薦目前還能報名的競賽。每筆回傳契合度（0–100，由規則計算）、優點（已達標的技能）、弱項（有基礎但未達需求）、"
                        + "能力缺口（完全沒有的技能）、組隊人數、是否需要指導老師、報名截止日。使用者想找比賽、或沒有指定競賽時使用。", p);
        p = obj();
        p.with("properties").putObject("keyword").put("type", "string").put("description", "競賽名稱、簡稱或主辦單位的關鍵字");
        p.putArray("required").add("keyword");
        tool(tools, "search_competitions", "用關鍵字在競賽資料庫找競賽（使用者提到特定比賽名稱時先用這個取得 competition_id）。回傳競賽清單與報名狀態。", p);
        p = obj();
        p.with("properties").putObject("competition_id").put("type", "integer");
        p.putArray("required").add("competition_id");
        tool(tools, "get_competition", "取得一個競賽的完整資料（資格、組隊人數、時程、所需技能、官方連結）與使用者對這個競賽的契合度、優點、弱項、能力缺口。", p);
        p = obj();
        p.with("properties").putObject("competition_id").put("type", "integer").put("description", "依這個競賽的所需技能找隊友");
        p.with("properties").putObject("case_id").put("type", "integer").put("description", "依使用者已建立的案件找隊友（與 competition_id 擇一）");
        p.with("properties").set("skills", skillArray());
        p.with("properties").putObject("member_tokens").put("type", "array").put("description", "已經確定的隊友代號，例如 [[S2]]（選填）").putObject("items").put("type", "string");
        p.with("properties").putObject("hours_per_week").put("type", "integer").put("description", "每週需要投入的時數，預設 4");
        p.with("properties").putObject("limit").put("type", "integer").put("description", "回傳幾位候選人，預設 6");
        tool(tools, "recommend_teammates",
                "學生 Agent：找技能互補的隊友。先算出團隊缺口（需求技能中，使用者與已確定隊友都沒達到需求階級的項目），再推薦能補上缺口的學生，"
                        + "回傳每位候選人補上哪些缺口、互補原因、媒合分數，以及一組建議組合與補完後仍缺的技能。候選人以代號（[[S1]]）表示，回覆時請原樣引用代號。", p);
        p = obj();
        p.with("properties").putObject("competition_id").put("type", "integer");
        p.with("properties").putObject("case_id").put("type", "integer");
        p.with("properties").set("skills", skillArray());
        p.with("properties").putObject("topic").put("type", "string").put("description", "主題關鍵字，例如「醫療影像 深度學習」（選填）");
        p.with("properties").putObject("limit").put("type", "integer").put("description", "回傳幾位，預設 3");
        tool(tools, "recommend_teachers",
                "教師 Agent：依需求技能、教師專長、研究方向與競賽指導經驗推薦指導老師，回傳專長契合原因與「待確認條件」（平台無法得知、需要學生自己向老師確認的事）。"
                        + "教師資料來自系所公開網頁；教師不是平台使用者，平台不會替學生聯絡老師。", p);
        p = obj();
        p.with("properties").putObject("competition_id").put("type", "integer");
        p.with("properties").putObject("invite_tokens").put("type", "array").put("description", "要邀請的學生代號（來自 recommend_teammates），例如 [\"[[S1]]\",\"[[S3]]\"]").putObject("items").put("type", "string");
        p.with("properties").putObject("advisor_teacher_id").put("type", "integer").put("description", "使用者已經決定的指導老師（選填；未決定就不要填）");
        p.with("properties").putObject("hours_per_week").put("type", "integer");
        p.with("properties").putObject("title").put("type", "string").put("description", "案件標題（選填，預設用競賽名稱）");
        p.with("properties").putObject("description").put("type", "string").put("description", "案件說明（選填）");
        p.putArray("required").add("competition_id");
        tool(tools, "draft_team_case",
                "產生「建立競賽組隊案件並送出邀請」的待確認動作。這個工具不會真的建立案件：它只把草稿交給使用者，使用者在畫面上按「確認」後系統才會建立並發布案件、送出邀請。"
                        + "只有在使用者表達要組隊或要邀請特定人選時才呼叫；呼叫後請提醒使用者檢查草稿並按確認，不可說成已經完成。", p);
        return tools;
    }

    private ObjectNode obj() { ObjectNode o = json.createObjectNode(); o.put("type", "object"); o.putObject("properties"); o.put("additionalProperties", false); return o; }
    private ObjectNode skillArray() {
        ObjectNode a = json.createObjectNode(); a.put("type", "array").put("description", "自訂需求技能（沒有競賽或案件時使用）；skill 必須是 Skill 資料庫裡的名稱");
        ObjectNode it = a.putObject("items"); it.put("type", "object"); it.put("additionalProperties", false);
        it.with("properties").putObject("skill").put("type", "string");
        it.with("properties").putObject("min_tier").put("type", "integer").put("description", "1 初階、2 中階、3 進階；預設 2");
        it.with("properties").putObject("importance").put("type", "string").putArray("enum").add("CORE").add("SUPPORT");
        it.putArray("required").add("skill");
        return a;
    }
    private void tool(ArrayNode tools, String name, String description, ObjectNode schema) {
        ObjectNode t = tools.addObject(); t.put("name", name); t.put("description", description); t.set("input_schema", schema);
    }

    // ---------- 執行 ----------
    public Result run(Turn t, String name, JsonNode in) {
        try {
            return switch (name) {
                case "get_my_skill_profile" -> profileTool(t);
                case "recommend_competitions" -> competitions(t, text(in, "category"), intOr(in, "limit", 5));
                case "search_competitions" -> search(t, text(in, "keyword"));
                case "get_competition" -> competition(t, need(in, "competition_id"));
                case "recommend_teammates" -> teammates(t, intOrNull(in, "competition_id"), intOrNull(in, "case_id"), needs(in.get("skills")), tokens(t, in.get("member_tokens")),
                        intOrNull(in, "hours_per_week"), intOr(in, "limit", 6));
                case "recommend_teachers" -> teachers(t, intOrNull(in, "competition_id"), intOrNull(in, "case_id"), needs(in.get("skills")), text(in, "topic"), intOr(in, "limit", 3));
                case "draft_team_case" -> draft(t, t.sessionId, need(in, "competition_id"), tokens(t, in.get("invite_tokens")), intOrNull(in, "advisor_teacher_id"), intOrNull(in, "hours_per_week"),
                        text(in, "title"), text(in, "description"));
                default -> error("TOOL", "沒有這個工具：" + name);
            };
        } catch (ApiException e) {
            return error(agentOf(name), e.getMessage() + (e.reasons.isEmpty() ? "" : "（" + String.join("；", e.reasons) + "）"));
        } catch (Exception e) {
            return error(agentOf(name), "工具執行失敗：" + e.getClass().getSimpleName());
        }
    }

    public static String agentOf(String tool) {
        return switch (tool) {
            case "get_my_skill_profile" -> "PROFILE";
            case "recommend_competitions", "search_competitions", "get_competition" -> "COMPETITION";
            case "recommend_teammates" -> "STUDENT";
            case "recommend_teachers" -> "TEACHER";
            case "draft_team_case" -> "ACTION";
            default -> "TOOL";
        };
    }

    private Result error(String agent, String message) {
        ObjectNode n = json.createObjectNode(); n.put("error", message);
        return new Result(agent, "失敗：" + message, n, null, true);
    }

    // ----- 能力盤點 -----
    public Result profileTool(Turn t) {
        var u = db.required("""
                SELECT u.degree, u.year, d.name dept, c.name college, coalesce(a.hours_per_week, 0) hours
                FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges c ON c.id = d.college_id LEFT JOIN user_availability a ON a.user_id = u.id
                WHERE u.id = :u""", "找不到使用者", "u", t.uid);
        List<Map<String, Object>> skills = profile.ownerSkills(t.uid);
        var st = stats.of(t.uid);
        var bands = profile.bands();
        ObjectNode m = json.createObjectNode();
        m.put("degree", degree((String) u.get("degree")) + " " + u.get("year") + " 年級"); m.put("department", (String) u.get("dept")); m.put("college", (String) u.get("college"));
        m.put("hours_per_week", Db.i(u.get("hours")));
        m.put("level_scale", bands.nameOf(1) + " " + bands.minScore(1) + "–" + (bands.minScore(2) - 1) + "、" + bands.nameOf(2) + " " + bands.minScore(2) + "–" + (bands.minScore(3) - 1) + "、" + bands.nameOf(3) + " " + bands.minScore(3) + "–100");
        ArrayNode arr = m.putArray("skills");
        Map<String, Integer> byTier = new LinkedHashMap<>(), byTrust = new LinkedHashMap<>();
        for (var s : skills) {
            ObjectNode x = arr.addObject();
            x.put("skill", (String) s.get("name")); x.put("category", (String) s.get("category")); x.put("tier", (String) s.get("tier")); x.put("trust", (String) s.get("trustLabel"));
            Set<String> types = new LinkedHashSet<>();
            for (var e : (List<Map<String, Object>>) s.get("evidence")) types.add((String) e.get("typeLabel"));
            x.set("evidence", json.valueToTree(types));
            byTier.merge((String) s.get("tier"), 1, Integer::sum); byTrust.merge((String) s.get("trustLabel"), 1, Integer::sum);
        }
        ObjectNode sx = m.putObject("collaboration");
        sx.put("completed_cases", st.closedCases()); sx.put("credibility", st.credibility());
        if (st.avgRating() != null) sx.put("peer_rating_out_of_5", st.avgRating());
        sx.put("response_rate", st.responseRate());
        Map<String, Object> card = new LinkedHashMap<>();
        card.put("type", "profile"); card.put("byTier", byTier); card.put("byTrust", byTrust); card.put("total", skills.size());
        card.put("top", skills.stream().limit(8).map(s -> Map.of("name", s.get("name"), "tier", s.get("tier"), "trust", s.get("trust"), "trustLabel", s.get("trustLabel"), "score", s.get("score"))).toList());
        card.put("trace", List.of("彙整證據 → Skill Profile：" + skills.size() + " 項技能", "同一技能多筆證據不疊加，取最高分；等級三階 " + m.get("level_scale").asText()));
        return new Result("PROFILE", "能力盤點：" + skills.size() + " 項技能（" + join(byTier) + "；" + join(byTrust) + "）", m, card, false);
    }

    private static String join(Map<String, Integer> m) { List<String> l = new ArrayList<>(); m.forEach((k, v) -> l.add(k + " " + v)); return String.join("、", l); }

    // ----- 競賽 Agent -----
    public Result competitions(Turn t, String category, int limit) {
        Map<String, Object> r = competitionAgent.recommend(t.uid, limit, category);
        List<Map<String, Object>> rec = (List<Map<String, Object>>) r.get("recommended");
        ObjectNode m = json.createObjectNode();
        m.put("today", catalog.today().toString());
        m.put("total_eligible", (Integer) r.get("totalEligible"));
        m.set("skipped", json.valueToTree(r.get("skipped")));
        ArrayNode arr = m.putArray("recommended");
        for (var c : rec) arr.add(compactCompetition(c));
        if (!rec.isEmpty()) { t.state.put("competitionId", rec.get(0).get("id")); t.state.put("competitionName", rec.get(0).get("name")); }
        Map<String, Object> card = new LinkedHashMap<>(r); card.put("type", "competitions");
        return new Result("COMPETITION", "競賽 Agent：可報名 " + r.get("totalEligible") + " 筆，回傳前 " + rec.size() + " 筆"
                + (rec.isEmpty() ? "" : "（最高：" + rec.get(0).get("shortName") + " " + rec.get(0).get("fit") + " 分）"), m, card, false);
    }

    private ObjectNode compactCompetition(Map<String, Object> c) {
        ObjectNode x = json.createObjectNode();
        x.put("competition_id", (Integer) c.get("id")); x.put("name", (String) c.get("name")); x.put("short_name", (String) c.get("shortName"));
        x.put("category", (String) c.get("category")); x.put("level", (String) c.get("level"));
        x.put("organizer", (String) c.get("organizer"));
        if (c.get("applyDeadline") != null) x.put("apply_deadline", String.valueOf(c.get("applyDeadline")));
        if (c.get("daysLeft") != null) x.put("days_left", (Integer) c.get("daysLeft"));
        if (c.get("eventDate") != null) x.put("event_date", String.valueOf(c.get("eventDate")));
        x.put("team", (c.get("teamMin") == null ? "?" : c.get("teamMin")) + "–" + (c.get("teamMax") == null ? "?" : c.get("teamMax")) + " 人");
        if (c.get("advisorRequired") != null) x.put("advisor_required", (Boolean) c.get("advisorRequired"));
        if (c.containsKey("fit")) {
            x.put("fit", (Double) c.get("fit")); x.put("eligible", (Boolean) c.get("eligible"));
            x.put("core_skills_met", c.get("coreMet") + "/" + c.get("coreTotal"));
            x.set("strengths", labels(c.get("strengths"))); x.set("weaknesses", labels(c.get("weaknesses"))); x.set("gaps", labels(c.get("gaps")));
            x.set("reasons", json.valueToTree(c.get("reasons")));
            if (!((List<?>) c.get("blockedBy")).isEmpty()) x.set("blocked_by", json.valueToTree(c.get("blockedBy")));
        }
        return x;
    }

    private ArrayNode labels(Object items) {
        ArrayNode a = json.createArrayNode();
        for (Object o : (List<?>) items) {
            var s = (tw.edu.fcu.campus.agent.AgentModels.SkillItem) o;
            a.add(s.name() + (s.core() ? "［核心］" : "") + (s.mine() == null ? "（需求" + s.required() + "）" : "（" + s.mine() + (s.trust() == null ? "" : "・" + s.trust()) + "，需求" + s.required() + "）"));
        }
        return a;
    }

    public Result search(Turn t, String keyword) {
        if (keyword == null || keyword.isBlank()) throw ApiException.badRequest("keyword 為必填");
        String kw = keyword.trim().toLowerCase();
        List<Map<String, Object>> hits = catalog.competitions(true).stream()
                .filter(c -> (c.name() + " " + c.display() + " " + c.organizer()).toLowerCase().contains(kw)).map(catalog::view).limit(8).toList();
        ObjectNode m = json.createObjectNode();
        ArrayNode arr = m.putArray("competitions");
        for (var c : hits) { ObjectNode x = compactCompetition(c); x.put("status", (String) c.get("status")); arr.add(x); }
        if (hits.size() == 1) { t.state.put("competitionId", hits.get(0).get("id")); t.state.put("competitionName", hits.get(0).get("name")); }
        Map<String, Object> card = new LinkedHashMap<>(); card.put("type", "competition_list"); card.put("keyword", keyword); card.put("items", hits);
        return new Result("COMPETITION", "競賽搜尋「" + keyword + "」：" + hits.size() + " 筆", m, card, false);
    }

    public Result competition(Turn t, int id) {
        Map<String, Object> c = competitionAgent.fitFor(t.uid, id);
        ObjectNode m = compactCompetition(c);
        m.put("description", (String) c.get("description")); m.put("eligibility", (String) c.get("eligibilityNote"));
        if (c.get("scheduleNote") != null) m.put("schedule_note", (String) c.get("scheduleNote"));
        if (c.get("prize") != null) m.put("prize", (String) c.get("prize"));
        if (c.get("url") != null) m.put("official_url", (String) c.get("url"));
        m.put("data_checked_at", String.valueOf(c.get("checkedAt")));
        t.state.put("competitionId", id); t.state.put("competitionName", c.get("name"));
        Map<String, Object> card = new LinkedHashMap<>(c); card.put("type", "competition");
        return new Result("COMPETITION", "競賽 Agent：「" + c.get("shortName") + "」契合度 " + c.get("fit") + "，核心技能 " + c.get("coreMet") + "／" + c.get("coreTotal"), m, card, false);
    }

    // ----- 學生 Agent -----
    public Result teammates(Turn t, Integer competitionId, Integer caseId, List<NeedIn> needs, List<Integer> members, Integer hours, int limit) {
        if (competitionId == null && caseId == null && needs.isEmpty() && t.state.get("competitionId") != null) competitionId = (Integer) t.state.get("competitionId");
        Map<String, Object> r = studentAgent.recommend(t.uid, new StudentAgent.Req(competitionId, caseId, needs, members, hours, null, limit));
        ObjectNode m = json.createObjectNode();
        m.set("context", json.valueToTree(r.get("context")));
        ArrayNode cov = m.putArray("team_coverage");
        for (var c : (List<Map<String, Object>>) r.get("coverage")) {
            ObjectNode x = cov.addObject();
            x.put("skill", (String) c.get("name")); x.put("importance", (String) c.get("importance")); x.put("required", (String) c.get("required")); x.put("status", (String) c.get("status"));
            if (c.get("best") != null) x.put("best_in_team", (String) c.get("best"));
        }
        List<Map<String, Object>> stored = new ArrayList<>();
        ArrayNode cands = m.putArray("candidates");
        for (var c : (List<Map<String, Object>>) r.get("candidates")) {
            int uid = (Integer) c.get("userId");
            ObjectNode x = cands.addObject();
            // 給模型的候選人資訊：代號、學院與系所（說明跨系互補用）、媒合分數、補位技能的階級。不給學制與年級：系所＋年級在小系所可能指向特定人
            x.put("student", t.alias(uid)); x.put("department", (String) c.get("department")); x.put("college", (String) c.get("college"));
            x.put("score", (Double) c.get("score"));
            x.set("fills", labels(c.get("fills"))); x.set("partial", labels(c.get("partial")));
            x.set("why", json.valueToTree(c.get("complementReasons")));
            List<String> extra = ((List<String>) c.get("reasons")).stream().filter(s -> s.startsWith("每週") || s.startsWith("隊友評價") || s.startsWith("尚無互評") || s.startsWith("可信度")).toList();
            x.set("other", json.valueToTree(extra));
            stored.add(Map.of("userId", uid, "name", c.get("name")));
        }
        Map<String, Object> sug = (Map<String, Object>) r.get("suggestedTeam");
        ObjectNode s = m.putObject("suggested_team");
        ArrayNode picks = s.putArray("picks");
        List<Integer> pickIds = new ArrayList<>();
        for (var pk : (List<Map<String, Object>>) sug.get("picks")) {
            ObjectNode x = picks.addObject(); x.put("student", t.alias((Integer) pk.get("userId"))); x.set("fills", json.valueToTree(pk.get("fills")));
            pickIds.add((Integer) pk.get("userId"));
        }
        s.set("remaining_gaps", json.valueToTree(sug.get("remainingGaps")));
        s.put("covered_after", sug.get("coveredAfter") + "/" + sug.get("total"));
        m.put("note", "候選人以代號表示；回覆時原樣引用代號（例如 [[S1]]），畫面會自動換成姓名。");
        Map<String, Object> ctx = (Map<String, Object>) r.get("context");
        if ("COMPETITION".equals(ctx.get("type"))) { t.state.put("competitionId", ctx.get("id")); t.state.put("competitionName", ctx.get("title")); }
        t.state.put("suggested", pickIds); t.state.put("hours", ctx.get("hoursPerWeek"));
        Map<String, Object> card = new LinkedHashMap<>(r); card.put("type", "teammates");
        List<?> gaps = (List<?>) r.get("gaps");
        return new Result("STUDENT", "學生 Agent：團隊缺口 " + gaps.size() + " 項，候選人 " + r.get("totalCandidates") + " 位，建議組合 " + pickIds.size() + " 人"
                + (((List<?>) sug.get("remainingGaps")).isEmpty() ? "（可補齊）" : "（仍缺 " + ((List<?>) sug.get("remainingGaps")).size() + " 項）"), m, card, false);
    }

    // ----- 教師 Agent -----
    public Result teachers(Turn t, Integer competitionId, Integer caseId, List<NeedIn> needs, String topic, int limit) {
        if (competitionId == null && caseId == null && needs.isEmpty() && (topic == null || topic.isBlank()) && t.state.get("competitionId") != null) competitionId = (Integer) t.state.get("competitionId");
        Map<String, Object> r = teacherAgent.recommend(t.uid, new TeacherAgent.Req(competitionId, caseId, needs, topic, limit));
        ObjectNode m = json.createObjectNode();
        m.set("context", json.valueToTree(r.get("context")));
        ArrayNode arr = m.putArray("teachers");
        List<Integer> ids = new ArrayList<>();
        for (var x : (List<Map<String, Object>>) r.get("teachers")) {
            ObjectNode o = arr.addObject();
            o.put("teacher_id", (Integer) x.get("teacherId")); o.put("name", (String) x.get("name")); o.put("title", (String) x.get("title")); o.put("department", (String) x.get("department"));
            o.put("fit", (Double) x.get("fit"));
            o.set("matched_skills", json.valueToTree(((List<Map<String, Object>>) x.get("matchedSkills")).stream().map(k -> k.get("name")).toList()));
            o.set("missing_skills", json.valueToTree(x.get("missingSkills")));
            o.put("expertise", (String) x.get("expertise")); o.put("research", (String) x.get("research")); o.put("coaching", (String) x.get("coaching"));
            o.set("reasons", json.valueToTree(x.get("reasons"))); o.set("to_confirm", json.valueToTree(x.get("toConfirm")));
            ids.add((Integer) x.get("teacherId"));
        }
        m.put("total_matched", (Integer) r.get("totalMatched"));
        m.put("note", "教師資料取自系所公開網頁；平台不會替學生聯絡老師，請提醒使用者自行聯絡並確認 to_confirm 的事項。");
        t.state.put("teacherIds", ids);
        Map<String, Object> card = new LinkedHashMap<>(r); card.put("type", "teachers");
        List<Map<String, Object>> list = (List<Map<String, Object>>) r.get("teachers");
        return new Result("TEACHER", "教師 Agent：專長相符 " + r.get("totalMatched") + " 位，回傳前 " + list.size() + " 位"
                + (list.isEmpty() ? "" : "（最高：" + list.get(0).get("name") + " " + list.get(0).get("fit") + " 分）"), m, card, false);
    }

    // ----- 待確認動作：建立競賽組隊案件並送出邀請 -----
    public Result draft(Turn t, Integer sessionId, int competitionId, List<Integer> invitees, Integer advisorTeacherId, Integer hours, String title, String description) {
        var comp = catalog.competition(competitionId);
        LocalDate today = catalog.today();
        Integer left = comp.daysLeft(today);
        if (left != null && left < 0) throw ApiException.badRequest("這個競賽的報名已經截止（" + comp.deadline() + "）");
        int h = hours != null ? Math.max(1, Math.min(40, hours)) : t.state.get("hours") instanceof Integer i ? i : 4;
        if (invitees.isEmpty() && t.state.get("suggested") instanceof List<?> l) for (Object o : l) invitees.add(((Number) o).intValue());
        invitees.remove((Integer) t.uid);
        int max = comp.teamMax() == null ? 5 : comp.teamMax();
        if (invitees.size() > max - 1) invitees = new ArrayList<>(invitees.subList(0, max - 1));

        // 我自己沒達標的需求 = 要靠隊友補的缺口；每位受邀者一個角色，技能條件 = 他能補的缺口
        Map<Integer, RankingService.SkillSet> skills = ranking.loadSkills(null);
        var mine = skills.getOrDefault(t.uid, RankingService.SkillSet.EMPTY);
        var gaps = comp.needs().stream().filter(n -> mine.level(n.skillId()) < n.minTier()).toList();
        List<Map<String, Object>> roles = new ArrayList<>();
        Set<String> names = new HashSet<>();
        Set<Integer> covered = new HashSet<>();
        for (int uid : invitees) {
            var u = db.one("SELECT u.name, d.name dept FROM users u JOIN departments d ON d.id = u.department_id WHERE u.id = :u AND u.role = 'STUDENT' AND u.deidentified_at IS NULL", "u", uid);
            if (u == null) throw ApiException.badRequest("受邀者不存在");
            var sk = skills.getOrDefault(uid, RankingService.SkillSet.EMPTY);
            var fills = StudentAgent.fills(gaps, sk);
            if (fills.isEmpty()) fills = StudentAgent.fills(comp.needs(), sk);
            if (fills.isEmpty()) throw ApiException.badRequest(u.get("name") + " 沒有這個競賽需要的技能，無法以這個競賽邀請");
            var picked = fills.stream().sorted(Comparator.comparing((tw.edu.fcu.campus.agent.AgentModels.Need n) -> !n.core()).thenComparing(n -> covered.contains(n.skillId()))).limit(3).toList();
            String base = String.join("／", picked.stream().limit(2).map(tw.edu.fcu.campus.agent.AgentModels.Need::name).toList()), rn = base;
            for (int i = 2; !names.add(rn); i++) rn = base + " " + i;
            Map<String, Object> role = new LinkedHashMap<>();
            role.put("roleName", rn); role.put("headcount", 1); role.put("hoursPerWeek", h);
            boolean first = true;
            List<Map<String, Object>> rs = new ArrayList<>();
            for (var n : picked) { rs.add(Map.of("skillId", n.skillId(), "name", n.name(), "minLevel", n.minTier(), "isRequired", first || n.core())); first = false; covered.add(n.skillId()); }
            role.put("skills", rs); role.put("inviteUserId", uid); role.put("inviteName", u.get("name")); role.put("inviteDepartment", u.get("dept"));
            roles.add(role);
        }
        if (roles.isEmpty()) {            // 沒有指定人選：依缺口開放招募（核心缺口優先）
            var open = (gaps.isEmpty() ? comp.needs() : gaps).stream().sorted(Comparator.comparing((tw.edu.fcu.campus.agent.AgentModels.Need n) -> !n.core())).limit(Math.max(1, Math.min(max - 1, 3))).toList();
            for (var n : open) {
                Map<String, Object> role = new LinkedHashMap<>();
                role.put("roleName", n.name()); role.put("headcount", 1); role.put("hoursPerWeek", h);
                role.put("skills", List.of(Map.of("skillId", n.skillId(), "name", n.name(), "minLevel", n.minTier(), "isRequired", true)));
                roles.add(role);
            }
        }
        String advisor = null;
        if (advisorTeacherId != null) advisor = (String) db.required("SELECT name FROM teachers WHERE id = :t AND active", "找不到這位教師", "t", advisorTeacherId).get("name");
        LocalDate deadline = comp.deadline() == null ? today.plusDays(14) : comp.deadline().minusDays(3).isBefore(today.plusDays(14)) ? comp.deadline().minusDays(3) : today.plusDays(14);
        if (deadline.isBefore(today.plusDays(2))) deadline = comp.deadline() != null && comp.deadline().isBefore(today.plusDays(2)) ? comp.deadline() : today.plusDays(2);
        LocalDate end = comp.eventDate() != null && !comp.eventDate().isBefore(today) ? comp.eventDate() : comp.deadline() != null ? comp.deadline().plusDays(30) : today.plusDays(60);
        if (end.isBefore(deadline)) end = deadline.plusDays(30);
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("competitionId", comp.id()); payload.put("competitionName", comp.name());
        payload.put("title", title == null || title.isBlank() ? "【組隊】" + comp.display() : cut(title, 100));
        payload.put("description", description == null || description.isBlank()
                ? "參加「" + comp.name() + "」（" + comp.organizer() + "）。" + (comp.deadline() == null ? "" : "競賽報名截止 " + comp.deadline() + "。") + "由 AI 助理依技能互補草擬，角色與人選可在發布前修改。"
                : cut(description, 500));
        payload.put("teamSize", roles.size() + 1); payload.put("applyDeadline", deadline.toString()); payload.put("startDate", today.toString()); payload.put("endDate", end.toString());
        payload.put("advisorTeacherId", advisorTeacherId); payload.put("advisorName", advisor); payload.put("roles", roles);
        long invites = roles.stream().filter(r -> r.get("inviteUserId") != null).count();
        String actionTitle = "建立「" + payload.get("title") + "」" + (invites > 0 ? "並邀請 " + invites + " 位隊友" : "並公開招募 " + roles.size() + " 個角色");
        int id = db.insertReturningId("""
                INSERT INTO agent_actions (session_id, user_id, type, title, payload, status, created_at)
                VALUES (:s, :u, 'CREATE_TEAM_CASE', :t, cast(:p AS jsonb), 'PENDING', now()) RETURNING id""",
                "s", sessionId, "u", t.uid, "t", actionTitle, "p", write(payload));
        t.state.put("actionId", id);

        ObjectNode m = json.createObjectNode();
        m.put("action_id", id); m.put("status", "PENDING_USER_CONFIRMATION");
        ObjectNode pv = m.putObject("draft");
        pv.put("title", (String) payload.get("title")); pv.put("team_size", roles.size() + 1); pv.put("apply_deadline", deadline.toString()); pv.put("period", today + " ~ " + end);
        if (advisor != null) pv.put("advisor", advisor);
        ArrayNode ra = pv.putArray("roles");
        for (var r : roles) {
            ObjectNode x = ra.addObject(); x.put("role", (String) r.get("roleName"));
            if (r.get("inviteUserId") != null) x.put("invite", t.alias((Integer) r.get("inviteUserId"))); else x.put("invite", "公開招募");
            x.set("skills", json.valueToTree(((List<Map<String, Object>>) r.get("skills")).stream().map(k -> k.get("name")).toList()));
        }
        m.put("note", "草稿已交給使用者。使用者按下「確認」後，系統才會建立並發布案件、送出邀請（對方 72 小時內回覆）。指導老師不會收到通知，需由使用者自行聯絡。");
        Map<String, Object> card = new LinkedHashMap<>();
        card.put("type", "action"); card.put("actionId", id); card.put("actionType", "CREATE_TEAM_CASE"); card.put("title", actionTitle); card.put("status", "PENDING"); card.put("payload", payload);
        return new Result("ACTION", "待確認動作 #" + id + "：" + actionTitle, m, card, false);
    }

    // ---------- 小工具 ----------
    public String write(Object o) { try { return json.writeValueAsString(o); } catch (Exception e) { throw new IllegalStateException(e); } }
    public ObjectMapper mapper() { return json; }
    private static String cut(String s, int n) { s = s.trim(); return s.length() > n ? s.substring(0, n) : s; }
    static String degree(String d) { return switch (String.valueOf(d)) { case "MASTER" -> "碩士"; case "PHD" -> "博士"; default -> "學士"; }; }
    private static String text(JsonNode in, String k) { return in != null && in.hasNonNull(k) ? in.get(k).asText() : null; }
    private static Integer intOrNull(JsonNode in, String k) { return in != null && in.hasNonNull(k) && in.get(k).canConvertToInt() ? in.get(k).asInt() : null; }
    private static int intOr(JsonNode in, String k, int d) { Integer v = intOrNull(in, k); return v == null ? d : Math.max(1, Math.min(v, 20)); }
    private static int need(JsonNode in, String k) { Integer v = intOrNull(in, k); if (v == null) throw ApiException.badRequest(k + " 為必填"); return v; }

    private List<Integer> tokens(Turn t, JsonNode arr) {
        List<Integer> out = new ArrayList<>();
        if (arr != null && arr.isArray()) for (JsonNode n : arr) {
            Integer uid = t.userOf(n.asText());
            if (uid == null) throw ApiException.badRequest("不認得的學生代號：" + n.asText() + "（代號必須來自 recommend_teammates 的結果）");
            if (!out.contains(uid)) out.add(uid);
        }
        return out;
    }

    /** 模型以技能名稱指定需求 → Skill ID（名稱或別名相符） */
    private List<NeedIn> needs(JsonNode arr) {
        List<NeedIn> out = new ArrayList<>();
        if (arr == null || !arr.isArray()) return out;
        List<Map<String, Object>> all = db.list("SELECT id, name, aliases FROM skills");
        for (JsonNode n : arr) {
            String want = n.path("skill").asText("").trim();
            if (want.isEmpty()) continue;
            Integer id = null;
            for (var s : all) if (want.equalsIgnoreCase((String) s.get("name"))) id = Db.i(s.get("id"));
            if (id == null) for (var s : all) for (String a : String.valueOf(s.get("aliases")).split(",")) if (!a.isBlank() && a.trim().equalsIgnoreCase(want)) id = Db.i(s.get("id"));
            if (id == null) for (var s : all) if (((String) s.get("name")).toLowerCase().contains(want.toLowerCase()) || want.toLowerCase().contains(((String) s.get("name")).toLowerCase())) { id = Db.i(s.get("id")); break; }
            if (id == null) throw ApiException.badRequest("Skill 資料庫沒有「" + want + "」，請改用資料庫裡的技能名稱");
            out.add(new NeedIn(id, n.hasNonNull("min_tier") ? n.get("min_tier").asInt() : 2, n.path("importance").asText("CORE")));
        }
        return out;
    }
}
