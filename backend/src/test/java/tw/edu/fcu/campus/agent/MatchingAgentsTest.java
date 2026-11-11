package tw.edu.fcu.campus.agent;

import org.junit.jupiter.api.Test;
import tw.edu.fcu.campus.agent.AgentModels.Need;
import tw.edu.fcu.campus.agent.CatalogService.Comp;
import tw.edu.fcu.campus.agent.CatalogService.Teacher;
import tw.edu.fcu.campus.ranking.RankingService.SkillSet;

import java.time.LocalDate;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/** 三個媒合 Agent 的規則（純函式）：競賽契合度與資格閘門、團隊缺口與互補組合、教師專長契合度 */
class MatchingAgentsTest {
    private static final LocalDate TODAY = LocalDate.of(2026, 11, 21);
    private static final int PY = 1, ML = 2, SLIDE = 3, VIZ = 4, BIZ = 5;
    private static final Need N_PY = new Need(PY, "Python", 2, 70, true), N_ML = new Need(ML, "機器學習", 2, 70, true),
            N_SLIDE = new Need(SLIDE, "簡報設計", 1, 60, false), N_VIZ = new Need(VIZ, "資料視覺化", 2, 70, true), N_BIZ = new Need(BIZ, "商業企劃", 2, 70, false);

    private static int tier(int s) { return s >= 85 ? 3 : s >= 70 ? 2 : s >= 60 ? 1 : 0; }

    private static SkillSet skills(Object... kv) {       // skillId, score, trust, …
        Map<Integer, Integer> sc = new HashMap<>(), lv = new HashMap<>(); Map<Integer, String> tr = new HashMap<>();
        for (int i = 0; i < kv.length; i += 3) { sc.put((Integer) kv[i], (Integer) kv[i + 1]); lv.put((Integer) kv[i], tier((Integer) kv[i + 1])); tr.put((Integer) kv[i], (String) kv[i + 2]); }
        return new SkillSet(sc, lv, tr);
    }

    private static Comp comp(Set<String> degrees, LocalDate deadline, Integer teamMax, Boolean advisor, List<Need> needs) {
        return new Comp(1, "全國資料創新應用競賽", "資料創新賽", "主辦單位", "AI 與資料", "NATIONAL", null, "", degrees, "限大專校院在學學生", 2, teamMax, advisor,
                deadline, deadline == null ? null : deadline.plusDays(40), "", null, "SEED", "https://example.edu/contest", TODAY, true, needs);
    }

    // ---------- 競賽 Agent ----------
    @Test
    void competitionFitSplitsStrengthsWeaknessesAndGaps() {
        Comp c = comp(Set.of("BACHELOR", "MASTER"), TODAY.plusDays(23), 5, true, List.of(N_PY, N_ML, N_SLIDE));
        var f = CompetitionAgent.evaluate(c, "BACHELOR", skills(PY, 90, "已驗證", ML, 65, "修課成績"), 1.0, TODAY);
        assertTrue(f.eligible());
        assertEquals(List.of("Python"), f.strengths().stream().map(AgentModels.SkillItem::name).toList());
        assertEquals(List.of("機器學習"), f.weaknesses().stream().map(AgentModels.SkillItem::name).toList());
        assertEquals(List.of("簡報設計"), f.gaps().stream().map(AgentModels.SkillItem::name).toList());
        // 涵蓋率 = (2×1 + 2×0.5×65/70 + 1×0) / 5；證據強度 = 0.90；契合度 = 100 × (0.75 × 涵蓋率 + 0.25 × 0.90)
        double coverage = (2 + 2 * 0.5 * 65 / 70.0) / 5;
        assertEquals(coverage, f.coverage(), 0.001);
        assertEquals(100 * (0.75 * coverage + 0.25 * 0.9), f.fit(), 0.06);
        assertEquals(1, f.coreMet()); assertEquals(2, f.coreTotal()); assertEquals(23, f.daysLeft());
        String all = String.join("｜", f.reasons());
        assertTrue(all.contains("Python（進階・已驗證）") && all.contains("能力缺口：簡報設計") && all.contains("需要指導老師") && all.contains("還有 23 天"), all);
        assertFalse(all.contains("90"), "理由不揭露分數：" + all);
    }

    @Test
    void competitionGatesBlockByDegreeDeadlineAndNoOverlap() {
        var me = skills(PY, 90, "修課成績");
        assertTrue(CompetitionAgent.evaluate(comp(Set.of("BACHELOR"), TODAY.plusDays(5), 5, false, List.of(N_PY)), "PHD", me, 1, TODAY).blockedBy().get(0).startsWith("E1"));
        assertTrue(CompetitionAgent.evaluate(comp(Set.of("BACHELOR"), TODAY.minusDays(1), 5, false, List.of(N_PY)), "BACHELOR", me, 1, TODAY).blockedBy().get(0).startsWith("E2"));
        assertTrue(CompetitionAgent.evaluate(comp(Set.of("BACHELOR"), TODAY.plusDays(5), 5, false, List.of(N_VIZ)), "BACHELOR", me, 1, TODAY).blockedBy().get(0).startsWith("E3"));
        assertTrue(CompetitionAgent.evaluate(comp(Set.of("BACHELOR"), TODAY, 5, false, List.of(N_PY)), "BACHELOR", me, 1, TODAY).eligible(), "截止當天仍可報名");
        assertTrue(CompetitionAgent.evaluate(comp(Set.of("BACHELOR"), null, 5, false, List.of(N_PY)), "BACHELOR", me, 1, TODAY).eligible(), "日期未公告不擋");
    }

    @Test
    void credibilityCoefficientLowersCompetitionFit() {
        Comp c = comp(Set.of("BACHELOR"), TODAY.plusDays(10), 3, false, List.of(N_PY));
        var honest = CompetitionAgent.evaluate(c, "BACHELOR", skills(PY, 93, "自述"), 1.0, TODAY);
        var inflated = CompetitionAgent.evaluate(c, "BACHELOR", skills(PY, 93, "自述"), 0.6, TODAY);
        assertTrue(inflated.fit() < honest.fit());
        assertTrue(String.join("", honest.reasons()).contains("都是自述"));
    }

    // ---------- 學生 Agent ----------
    @Test
    void teamCoverageFindsGaps() {
        Map<Integer, SkillSet> team = new LinkedHashMap<>();
        team.put(10, skills(PY, 90, "已驗證", ML, 65, "修課成績"));
        team.put(11, skills(SLIDE, 80, "修課成績"));
        var cov = StudentAgent.coverage(List.of(N_PY, N_ML, N_SLIDE, N_VIZ), team);
        assertEquals(StudentAgent.Status.MET, cov.get(0).status()); assertEquals(List.of(10), cov.get(0).by());
        assertEquals(StudentAgent.Status.BELOW, cov.get(1).status()); assertEquals(1, cov.get(1).bestTier());     // 有人會，但只到初階
        assertEquals(StudentAgent.Status.MET, cov.get(2).status()); assertEquals(List.of(11), cov.get(2).by());
        assertEquals(StudentAgent.Status.MISSING, cov.get(3).status());
    }

    @Test
    void greedySuggestionCoversMostWeightedGapsFirst() {
        List<Need> gaps = List.of(N_ML, N_VIZ, N_BIZ);                         // 核心、核心、輔助
        LinkedHashMap<Integer, List<Need>> cands = new LinkedHashMap<>();      // 依總分由高到低
        cands.put(21, List.of(N_BIZ));                                         // 分數最高，但只補輔助技能
        cands.put(22, List.of(N_ML, N_VIZ));                                   // 一次補兩項核心
        cands.put(23, List.of(N_ML));
        var picks = StudentAgent.suggest(gaps, cands, 2);
        assertEquals(List.of(22, 21), picks.stream().map(StudentAgent.Pick::userId).toList());
        assertEquals(List.of("機器學習", "資料視覺化"), picks.get(0).fills().stream().map(Need::name).toList());
        // 名額只有 1：選補最多核心缺口的人；沒有人能補的缺口留在「仍缺」
        assertEquals(List.of(22), StudentAgent.suggest(gaps, cands, 1).stream().map(StudentAgent.Pick::userId).toList());
        assertTrue(StudentAgent.suggest(List.of(N_SLIDE), cands, 3).isEmpty());
    }

    @Test
    void fillsRequiresRequiredTier() {
        assertEquals(List.of(N_VIZ), StudentAgent.fills(List.of(N_ML, N_VIZ), skills(ML, 65, "自述", VIZ, 88, "已驗證")));
    }

    // ---------- 教師 Agent ----------
    private static Teacher teacher(String dept, String college, String expertise, String research, String coaching, Map<Integer, Double> sk) {
        return new Teacher(1, "王老師", "教授", 1, dept, college, expertise, research, coaching, null, "https://example.edu/t", TODAY, true, sk, Map.of(), 0);
    }

    @Test
    void teacherFitCombinesExpertiseCoachingDepartmentAndResearch() {
        Map<Integer, List<String>> aliases = Map.of(PY, List.of("Python"), ML, List.of("機器學習", "Machine Learning"), VIZ, List.of("資料視覺化"));
        Teacher t = teacher("資訊工程學系", "資訊電機學院", "機器學習、資料探勘", "以 machine learning 分析醫療影像", "指導學生參加全國資料創新應用競賽獲佳作", Map.of(ML, 0.9, PY, 0.6));
        var s = TeacherAgent.score(t, List.of(N_PY, N_ML, N_VIZ), aliases, "資訊工程學系", "資訊電機學院", List.of("全國資料創新應用競賽", "資料創新賽"), "AI 與資料", List.of());
        assertEquals((2 * 0.6 + 2 * 0.9) / 6, s.e(), 0.001);          // 三項核心技能，對到兩項
        assertEquals(1.0, s.g());                                      // 指導經歷提到這個競賽
        assertEquals(1.0, s.d());                                      // 同系
        assertEquals(1 / 3.0, s.k(), 0.001);                           // 研究方向文字提到「機器學習」（別名 machine learning）
        assertEquals(100 * (0.55 * 0.5 + 0.20 + 0.15 + 0.10 / 3), s.fit(), 0.06);
        assertEquals(List.of("資料視覺化"), s.missing().stream().map(Need::name).toList());
    }

    @Test
    void teacherCoachingAndDepartmentTiers() {
        Map<Integer, List<String>> aliases = Map.of();
        var sameCategory = TeacherAgent.score(teacher("統計學系", "商學院", "", "", "帶隊參加人工智慧應用競賽", Map.of(ML, 1.0)), List.of(N_ML), aliases, "資訊工程學系", "資訊電機學院", List.of("某某盃"), "AI 與資料", List.of());
        assertEquals(0.7, sameCategory.g()); assertEquals(0.3, sameCategory.d());
        var other = TeacherAgent.score(teacher("電機工程學系", "資訊電機學院", "", "", "指導學生參加創意歌唱比賽", Map.of(ML, 1.0)), List.of(N_ML), aliases, "資訊工程學系", "資訊電機學院", List.of(), "AI 與資料", List.of());
        assertEquals(0.4, other.g()); assertEquals(0.6, other.d());
        var none = TeacherAgent.score(teacher("電機工程學系", "資訊電機學院", "", "", "", Map.of()), List.of(N_ML), aliases, "資訊工程學系", "資訊電機學院", List.of(), null, List.of());
        assertEquals(0.0, none.g()); assertEquals(0.0, none.e());
    }
}
