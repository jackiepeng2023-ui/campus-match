package tw.edu.fcu.campus.ranking;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 推薦排序引擎（純 Java，無框架相依，可單元測試）。
 * 規則守門：G1 身分、G2 必要技能、G3 時間、G4 名額 全部通過才排序。
 * 分數 = 100 × (wS·S + wT·T + wR·R + wP·P + wC·C)，各項 0–1（D37）。
 * S 乘上可信度係數（D38）；R = 0.75×互評 + 0.25×得獎（D41）。
 */
public final class RankingEngine {

    public record Weights(double s, double t, double r, double p, double c) {
        public static final Weights DEFAULT = new Weights(0.40, 0.20, 0.20, 0.10, 0.10);
    }

    public record RoleSkill(int skillId, String name, int minLevel, boolean required) {}

    public record Role(int hoursPerWeek, LocalDate start, LocalDate end, List<RoleSkill> skills,
                       String ownerCollege, String ownerDept, boolean open, int remainingSeats) {}

    public record Candidate(int userId, String name, String college, String dept,
                            Map<Integer, Integer> skillLevels, int hoursPerWeek, LocalDate availFrom, LocalDate availTo,
                            Double peerScore,      // 0–1；null = 尚無互評（冷啟動 0.5）
                            double awardScore,     // 0–1
                            double responseRate,   // 0–1
                            double credibility,    // D38 係數
                            boolean isOwner, boolean isMember, boolean hasPending, int activeCases) {}

    public record Result(int userId, boolean passed, List<String> blockedBy, double score,
                         Map<String, Double> breakdown, List<String> reasons, int activeCases) {}

    public Result evaluate(Role role, Candidate c, Weights w) {
        List<String> blocked = new ArrayList<>();
        List<String> reasons = new ArrayList<>();

        // G1 身分
        if (c.isOwner()) blocked.add("G1：發案方本人");
        if (c.isMember()) blocked.add("G1：已是本案成員");
        if (c.hasPending()) blocked.add("G1：已有待處理的申請或邀請");

        // G2 必要技能 + S 技能符合度
        double wsum = 0, ssum = 0;
        for (RoleSkill rs : role.skills()) {
            int lv = c.skillLevels().getOrDefault(rs.skillId(), 0);
            double wgt = rs.required() ? 2 : 1;
            double s;
            if (lv >= rs.minLevel()) {
                s = lv / 5.0;
                reasons.add(rs.name() + " " + lv + " 級（需求 " + rs.minLevel() + "）");
            } else if (lv == 0) {
                s = 0;
                if (rs.required()) blocked.add("G2：缺少必要技能 " + rs.name());
                else reasons.add(rs.name() + " 無此技能（加分項）");
            } else {
                s = rs.required() ? 0 : 0.5 * lv / rs.minLevel();
                if (rs.required()) blocked.add("G2：" + rs.name() + " " + lv + " 級未達 " + rs.minLevel() + " 級");
                else reasons.add(rs.name() + " " + lv + " 級未達 " + rs.minLevel() + "（加分項，半計）");
            }
            wsum += wgt; ssum += wgt * s;
        }
        double sRaw = wsum == 0 ? 0 : ssum / wsum;
        double S = sRaw * c.credibility();
        if (c.credibility() < 1) reasons.add("可信度係數 " + c.credibility() + "（隊友評為與檔案不符）");

        // G3 時間 + T
        double hoursRatio = role.hoursPerWeek() <= 0 ? 1 : Math.min(c.hoursPerWeek() / (double) role.hoursPerWeek(), 1);
        double overlap = overlapRatio(role.start(), role.end(), c.availFrom(), c.availTo());
        if (c.hoursPerWeek() < role.hoursPerWeek())
            blocked.add("G3：每週可投入 " + c.hoursPerWeek() + " 小時，低於需求 " + role.hoursPerWeek() + " 小時");
        if (overlap <= 0) blocked.add("G3：可用期間與案件期間不重疊");
        double T = hoursRatio * overlap;
        if (T > 0) reasons.add("每週 " + c.hoursPerWeek() + " 小時（需求 " + role.hoursPerWeek() + "），期間重疊 " + Math.round(overlap * 100) + "%");

        // G4 名額
        if (!role.open()) blocked.add("G4：案件不在招募中");
        else if (role.remainingSeats() <= 0) blocked.add("G4：此角色名額已滿");

        // R 評價
        double peer = c.peerScore() == null ? 0.5 : c.peerScore();
        double R = 0.75 * peer + 0.25 * Math.min(c.awardScore(), 1.0);
        if (c.peerScore() == null) reasons.add("尚無互評紀錄（冷啟動 0.5）");
        else reasons.add("隊友評價 " + String.format("%.1f", peer * 5) + "／5");
        if (c.awardScore() > 0) reasons.add("得獎加成 " + String.format("%.2f", Math.min(c.awardScore(), 1.0)));

        // P 回應率
        double P = clamp(c.responseRate());
        reasons.add("回應率 " + Math.round(P * 100) + "%");

        // C 跨系互補
        double C;
        if (!safe(c.college()).equals(safe(role.ownerCollege()))) { C = 1; reasons.add("跨學院（" + c.college() + " ↔ " + role.ownerCollege() + "）"); }
        else if (!safe(c.dept()).equals(safe(role.ownerDept()))) { C = 0.5; reasons.add("同學院不同系（" + c.dept() + "）"); }
        else { C = 0; reasons.add("同系"); }

        double score = 100 * (w.s() * S + w.t() * T + w.r() * R + w.p() * P + w.c() * C);
        Map<String, Double> breakdown = new LinkedHashMap<>();
        breakdown.put("S", round(S)); breakdown.put("T", round(T)); breakdown.put("R", round(R));
        breakdown.put("P", round(P)); breakdown.put("C", round(C));
        breakdown.put("S_weighted", round(100 * w.s() * S)); breakdown.put("T_weighted", round(100 * w.t() * T));
        breakdown.put("R_weighted", round(100 * w.r() * R)); breakdown.put("P_weighted", round(100 * w.p() * P));
        breakdown.put("C_weighted", round(100 * w.c() * C));
        breakdown.put("credibility", c.credibility());
        return new Result(c.userId(), blocked.isEmpty(), blocked, Math.round(score * 10) / 10.0, breakdown, reasons, c.activeCases());
    }

    /** 可用期間與案件期間的重疊比例（以案件期間為分母） */
    static double overlapRatio(LocalDate cs, LocalDate ce, LocalDate as, LocalDate ae) {
        if (cs == null || ce == null) return 1;
        if (as == null || ae == null) return 0;
        LocalDate s = cs.isAfter(as) ? cs : as;
        LocalDate e = ce.isBefore(ae) ? ce : ae;
        long caseDays = ChronoUnit.DAYS.between(cs, ce) + 1;
        long ov = ChronoUnit.DAYS.between(s, e) + 1;
        if (caseDays <= 0 || ov <= 0) return 0;
        return Math.min(1.0, ov / (double) caseDays);
    }

    private static double clamp(double v) { return Math.max(0, Math.min(1, v)); }
    private static double round(double v) { return Math.round(v * 1000) / 1000.0; }
    private static String safe(String s) { return s == null ? "" : s; }
}
