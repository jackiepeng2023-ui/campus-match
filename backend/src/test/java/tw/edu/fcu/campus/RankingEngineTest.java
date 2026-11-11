package tw.edu.fcu.campus;

import org.junit.jupiter.api.Test;
import tw.edu.fcu.campus.ranking.RankingEngine;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/** 推薦排序引擎：閘門與公式的單元測試（對應 D37、D38、D41、D53） */
class RankingEngineTest {
    private final RankingEngine engine = new RankingEngine();
    private final LocalDate s = LocalDate.of(2026, 11, 9), e = LocalDate.of(2026, 12, 20);
    // Vue 必要、至少中階（70）；資料視覺化 加分、至少初階（60）
    private final RankingEngine.Role role = new RankingEngine.Role(6, s, e,
            List.of(new RankingEngine.RoleSkill(8, "Vue", 2, 70, true), new RankingEngine.RoleSkill(13, "資料視覺化", 1, 60, false)),
            "商學院", "企業管理學系", true, 1);

    private static int tier(int score) { return score >= 85 ? 3 : score >= 70 ? 2 : score >= 60 ? 1 : 0; }

    private RankingEngine.Candidate cand(Map<Integer, Integer> scores, int hours, Double peer, double award, double resp, double cred,
                                         String college, String dept, boolean owner, boolean member, boolean pending) {
        Map<Integer, Integer> levels = new HashMap<>();
        Map<Integer, String> trust = new HashMap<>();
        scores.forEach((k, v) -> { levels.put(k, tier(v)); trust.put(k, "修課成績"); });
        return new RankingEngine.Candidate(1, "A", college, dept, scores, levels, trust, hours, s.minusDays(10), e.plusDays(10),
                peer, award, resp, cred, owner, member, pending, 0);
    }

    @Test
    void passesAllGatesAndScoresByFormula() {
        var r = engine.evaluate(role, cand(Map.of(8, 95, 13, 80), 8, null, 0, 1.0, 1.0, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertTrue(r.passed(), r.blockedBy().toString());
        // S = (2×0.95 + 1×0.80)/3 = 0.9；T = 1；R = 0.75×0.5 = 0.375；P = 1；C = 1
        double expected = 100 * (0.40 * 0.9 + 0.20 * 1 + 0.20 * 0.375 + 0.10 * 1 + 0.10 * 1);
        assertEquals(expected, r.score(), 0.05);
        assertEquals(0.9, r.breakdown().get("S"), 0.001);
        assertEquals(1.0, r.breakdown().get("C"));
    }

    @Test
    void reasonsShowTierAndTrustButNeverScores() {
        var r = engine.evaluate(role, cand(Map.of(8, 95, 13, 80), 8, null, 0, 1.0, 1.0, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        String all = String.join("｜", r.reasons());
        assertTrue(all.contains("Vue 進階・修課成績（需求 中階）"), all);
        assertFalse(all.contains("95"), "理由不得揭露技能分數（D16）：" + all);
    }

    @Test
    void requiredSkillBelowTierIsBlocked() {
        var r = engine.evaluate(role, cand(Map.of(8, 65), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertFalse(r.passed());
        assertEquals("G2：Vue 初階，未達 中階", r.blockedBy().get(0));
        var none = engine.evaluate(role, cand(Map.of(13, 90), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertEquals("G2：缺少必要技能 Vue", none.blockedBy().get(0));
    }

    @Test
    void optionalSkillBelowTierCountsHalfProportionally() {
        // 加分技能 50 分（未達初階 60）：0.5 × 50/60 = 0.4167；S = (2×0.9 + 0.4167)/3
        var r = engine.evaluate(role, cand(Map.of(8, 90, 13, 50), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertTrue(r.passed());
        assertEquals((2 * 0.9 + 0.5 * 50 / 60.0) / 3, r.breakdown().get("S"), 0.001);
    }

    @Test
    void insufficientHoursIsBlockedByTimeGate() {
        var r = engine.evaluate(role, cand(Map.of(8, 95), 2, null, 0, 1, 1, "創意設計學院", "創意設計學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertFalse(r.passed());
        assertTrue(r.blockedBy().stream().anyMatch(b -> b.startsWith("G3")));
    }

    @Test
    void ownerMemberAndPendingAreBlockedByIdentityGate() {
        assertFalse(engine.evaluate(role, cand(Map.of(8, 95), 8, null, 0, 1, 1, "x", "y", true, false, false), RankingEngine.Weights.DEFAULT).passed());
        assertFalse(engine.evaluate(role, cand(Map.of(8, 95), 8, null, 0, 1, 1, "x", "y", false, true, false), RankingEngine.Weights.DEFAULT).passed());
        assertFalse(engine.evaluate(role, cand(Map.of(8, 95), 8, null, 0, 1, 1, "x", "y", false, false, true), RankingEngine.Weights.DEFAULT).passed());
    }

    @Test
    void credibilityCoefficientLowersSkillScore() {
        var honest = engine.evaluate(role, cand(Map.of(8, 93), 8, 0.9, 0, 1, 1.0, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        var inflated = engine.evaluate(role, cand(Map.of(8, 93), 8, 0.9, 0, 1, 0.6, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertTrue(inflated.score() < honest.score());
        assertEquals(honest.breakdown().get("S") * 0.6, inflated.breakdown().get("S"), 0.01);
    }

    @Test
    void awardsLiftColdStartAboveNewcomerWithoutAwards() {
        var plain = engine.evaluate(role, cand(Map.of(8, 80), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        var awarded = engine.evaluate(role, cand(Map.of(8, 80), 8, null, 0.8, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertEquals(0.375, plain.breakdown().get("R"), 0.001);
        assertEquals(0.575, awarded.breakdown().get("R"), 0.001);
        assertTrue(awarded.score() > plain.score());
    }

    @Test
    void crossDepartmentBonusTiers() {
        double other = engine.evaluate(role, cand(Map.of(8, 80), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT).breakdown().get("C");
        double sameCollege = engine.evaluate(role, cand(Map.of(8, 80), 8, null, 0, 1, 1, "商學院", "行銷學系", false, false, false), RankingEngine.Weights.DEFAULT).breakdown().get("C");
        double sameDept = engine.evaluate(role, cand(Map.of(8, 80), 8, null, 0, 1, 1, "商學院", "企業管理學系", false, false, false), RankingEngine.Weights.DEFAULT).breakdown().get("C");
        assertEquals(1.0, other); assertEquals(0.5, sameCollege); assertEquals(0.0, sameDept);
    }

    @Test
    void fullRoleIsBlockedBySeatGate() {
        var full = new RankingEngine.Role(6, s, e, role.skills(), "商學院", "企業管理學系", true, 0);
        var r = engine.evaluate(full, cand(Map.of(8, 95), 8, null, 0, 1, 1, "資電學院", "資訊工程學系", false, false, false), RankingEngine.Weights.DEFAULT);
        assertTrue(r.blockedBy().stream().anyMatch(b -> b.startsWith("G4")));
    }
}
