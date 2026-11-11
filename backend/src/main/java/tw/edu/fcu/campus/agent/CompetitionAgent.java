package tw.edu.fcu.campus.agent;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.agent.AgentModels.Need;
import tw.edu.fcu.campus.agent.AgentModels.SkillItem;
import tw.edu.fcu.campus.agent.CatalogService.Comp;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.ranking.RankingService;
import tw.edu.fcu.campus.ranking.RankingService.SkillSet;
import tw.edu.fcu.campus.user.StatsService;

import java.time.LocalDate;
import java.util.*;

import static tw.edu.fcu.campus.agent.AgentModels.round1;
import static tw.edu.fcu.campus.agent.AgentModels.round3;
import static tw.edu.fcu.campus.agent.AgentModels.tier;

/**
 * 競賽 Agent（競賽需求）：學生 Skill × 競賽資格 × 競賽所需 Skill → 推薦競賽、優點、弱項、能力缺口。
 *
 * 資格閘門  E1 學制不符｜E2 報名已截止｜E3 技能檔與需求沒有交集
 * 契合度    = 100 × (0.75 × 涵蓋率 + 0.25 × 證據強度)
 *   涵蓋率   = Σ 權重 × 符合度 ÷ Σ 權重（核心技能權重 2、輔助 1；達到需求階級 = 1，持有但未達 = 0.5 × 分數 ÷ 門檻，沒有 = 0）
 *   證據強度 = 達標技能的平均分數 ÷ 100 × 可信度係數（D38）
 * 分數全部由規則算出；語言模型只負責把這裡的理由改寫成自然語言，不能改數字。
 */
@Service
public class CompetitionAgent {
    private final Db db;
    private final CatalogService catalog;
    private final RankingService ranking;
    private final StatsService stats;

    public CompetitionAgent(Db db, CatalogService catalog, RankingService ranking, StatsService stats) {
        this.db = db; this.catalog = catalog; this.ranking = ranking; this.stats = stats;
    }

    public record Fit(boolean eligible, List<String> blockedBy, double fit, double coverage, double depth, int coreMet, int coreTotal,
                      List<SkillItem> strengths, List<SkillItem> weaknesses, List<SkillItem> gaps, List<String> reasons, Integer daysLeft) {}

    /** 純函式：一位學生對一個競賽的評估 */
    public static Fit evaluate(Comp c, String degree, SkillSet sk, double credibility, LocalDate today) {
        List<String> blocked = new ArrayList<>(), reasons = new ArrayList<>();
        List<SkillItem> strengths = new ArrayList<>(), weaknesses = new ArrayList<>(), gaps = new ArrayList<>();
        if (!c.degrees().contains(degree))
            blocked.add("E1：參賽資格不含" + degreeName(degree) + (c.eligibilityNote() == null || c.eligibilityNote().isBlank() ? "" : "（" + c.eligibilityNote() + "）"));
        Integer daysLeft = c.daysLeft(today);
        if (daysLeft != null && daysLeft < 0) blocked.add("E2：報名已於 " + c.deadline() + " 截止");

        double wsum = 0, msum = 0, dsum = 0;
        int met = 0, coreMet = 0, coreTotal = 0;
        for (Need n : c.needs()) {
            int score = sk.score(n.skillId()), lv = sk.level(n.skillId());
            SkillItem item = new SkillItem(n.skillId(), n.name(), n.core(), tier(n.minTier()), score == 0 ? null : tier(lv), sk.trust().get(n.skillId()));
            double m;
            if (lv >= n.minTier()) { m = 1; strengths.add(item); met++; dsum += score / 100.0; if (n.core()) coreMet++; }
            else if (score > 0) { m = 0.5 * score / Math.max(n.minScore(), 1); weaknesses.add(item); }
            else { m = 0; gaps.add(item); }
            if (n.core()) coreTotal++;
            wsum += n.weight(); msum += n.weight() * m;
        }
        double coverage = wsum == 0 ? 0 : msum / wsum;
        double depth = met == 0 ? 0 : dsum / met * credibility;
        if (strengths.isEmpty() && weaknesses.isEmpty()) blocked.add("E3：你的 Skill Profile 與這個競賽的需求技能沒有交集");
        double fit = 100 * (0.75 * coverage + 0.25 * depth);

        // 理由（優點 → 弱項 → 缺口 → 組隊與時程）
        if (!strengths.isEmpty()) {
            reasons.add("核心技能 " + coreTotal + " 項中 " + coreMet + " 項達標" + (strengths.size() > coreMet ? "，另有 " + (strengths.size() - coreMet) + " 項輔助技能達標" : "")
                    + "：" + join(strengths, 5));
            if (strengths.stream().allMatch(s -> "自述".equals(s.trust()))) reasons.add("達標的技能目前都是自述，建議補上證明連結或以結案紀錄取得驗證");
        }
        if (!weaknesses.isEmpty()) reasons.add("弱項（有基礎但未達需求）：" + String.join("、", weaknesses.stream().map(w -> w.name() + "（目前" + w.mine() + "，需求" + w.required() + "）").toList()));
        if (!gaps.isEmpty()) reasons.add("能力缺口：" + String.join("、", gaps.stream().map(g -> g.name() + (g.core() ? "（核心）" : "")).toList())
                + (c.team() ? " → 可以找互補的隊友補上" : " → 個人賽，需自行補強"));
        if (c.teamMin() != null || c.teamMax() != null)
            reasons.add((c.team() ? "組隊 " + (c.teamMin() == null ? 1 : c.teamMin()) + "–" + (c.teamMax() == null ? "不限" : c.teamMax()) + " 人" : "個人賽")
                    + (Boolean.TRUE.equals(c.advisorRequired()) ? "，需要指導老師" : ""));
        if (daysLeft == null) reasons.add("報名日期尚未公告或未收錄，請以官方網站為準");
        else if (daysLeft >= 0) reasons.add("距報名截止還有 " + daysLeft + " 天（" + c.deadline() + "）");
        if (credibility < 1) reasons.add("可信度係數 " + credibility + "（過去合作中被評為能力與檔案不符）");
        return new Fit(blocked.isEmpty(), blocked, round1(fit), round3(coverage), round3(depth), coreMet, coreTotal, strengths, weaknesses, gaps, reasons, daysLeft);
    }

    private static String join(List<SkillItem> items, int max) {
        List<String> s = items.stream().limit(max).map(SkillItem::label).toList();
        return String.join("、", s) + (items.size() > max ? " 等 " + items.size() + " 項" : "");
    }

    static String degreeName(String d) { return switch (d) { case "MASTER" -> "碩士生"; case "PHD" -> "博士生"; default -> "學士生"; }; }

    private record Me(String degree, SkillSet skills, double credibility) {}

    private Me me(int uid) {
        String degree = db.scalar(String.class, "SELECT degree FROM users WHERE id = :u", "u", uid);
        if (degree == null) throw ApiException.notFound("找不到使用者");
        SkillSet sk = ranking.loadSkills(uid).getOrDefault(uid, SkillSet.EMPTY);
        return new Me(degree, sk, stats.of(uid).credibility());
    }

    private Map<String, Object> item(Comp c, Fit f) {
        Map<String, Object> m = catalog.view(c);
        m.put("fit", f.fit()); m.put("eligible", f.eligible()); m.put("blockedBy", f.blockedBy());
        m.put("coverage", f.coverage()); m.put("depth", f.depth()); m.put("coreMet", f.coreMet()); m.put("coreTotal", f.coreTotal());
        m.put("strengths", f.strengths()); m.put("weaknesses", f.weaknesses()); m.put("gaps", f.gaps()); m.put("reasons", f.reasons());
        return m;
    }

    /** 推薦競賽：通過資格閘門者依契合度排序；被擋下的另列並說明原因 */
    public Map<String, Object> recommend(int uid, Integer limit, String category) {
        Me me = me(uid);
        LocalDate today = catalog.today();
        List<Comp> all = catalog.competitions(true);
        List<Map<String, Object>> ok = new ArrayList<>(), blocked = new ArrayList<>();
        int closed = 0, ineligible = 0, unrelated = 0;
        for (Comp c : all) {
            if (category != null && !category.isBlank() && !category.equals(c.category())) continue;
            Fit f = evaluate(c, me.degree(), me.skills(), me.credibility(), today);
            if (f.eligible()) ok.add(item(c, f));
            else {
                String first = f.blockedBy().get(0);
                if (first.startsWith("E2")) closed++; else if (first.startsWith("E1")) ineligible++; else unrelated++;
                if (!first.startsWith("E2")) blocked.add(item(c, f));
            }
        }
        ok.sort(Comparator.<Map<String, Object>>comparingDouble(m -> -(double) m.get("fit"))
                .thenComparingInt(m -> m.get("daysLeft") == null ? Integer.MAX_VALUE : (int) m.get("daysLeft")));
        int n = limit == null ? 10 : Math.max(1, Math.min(limit, 50));
        long verified = me.skills().trust().values().stream().filter("已驗證"::equals).count(), self = me.skills().trust().values().stream().filter("自述"::equals).count();
        List<String> trace = List.of(
                "讀取 Skill Profile：" + me.skills().scores().size() + " 項技能（已驗證 " + verified + "、自述 " + self + "）",
                "競賽資料庫 " + all.size() + " 筆 → 資格閘門：報名已截止 " + closed + "、學制不符 " + ineligible + "、技能無交集 " + unrelated + " → 可報名 " + ok.size() + " 筆",
                "逐一計算契合度 = 75% 涵蓋率（核心技能權重 2、輔助 1）+ 25% 證據強度",
                "依契合度排序，回傳前 " + Math.min(n, ok.size()) + " 筆與優點／弱項／能力缺口");
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("agent", "COMPETITION");
        out.put("recommended", ok.subList(0, Math.min(n, ok.size())));
        out.put("totalEligible", ok.size());
        out.put("blocked", blocked.subList(0, Math.min(10, blocked.size())));
        out.put("skipped", Map.of("closed", closed, "ineligible", ineligible, "unrelated", unrelated));
        out.put("trace", trace);
        return out;
    }

    /** 單一競賽對我的評估（競賽詳情頁、AI 助理的 get_competition 工具） */
    public Map<String, Object> fitFor(int uid, int competitionId) {
        Me me = me(uid);
        Comp c = catalog.competition(competitionId);
        return item(c, evaluate(c, me.degree(), me.skills(), me.credibility(), catalog.today()));
    }
}
