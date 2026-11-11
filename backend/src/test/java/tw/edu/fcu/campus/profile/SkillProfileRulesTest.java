package tw.edu.fcu.campus.profile;

import org.junit.jupiter.api.Test;
import tw.edu.fcu.campus.profile.SkillProfileService.Agg;
import tw.edu.fcu.campus.profile.SkillProfileService.Band;
import tw.edu.fcu.campus.profile.SkillProfileService.Bands;
import tw.edu.fcu.campus.profile.SkillProfileService.Ev;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/** 能力盤點的統一規則（D53–D55）：三階門檻、研究所成績換算、不疊加、自述／已驗證 */
class SkillProfileRulesTest {
    private static final Bands REF = Bands.DEFAULT;                                                              // 60／70／85
    private static final Bands GRAD = new Bands(List.of(new Band(1, "初階", 70), new Band(2, "中階", 80), new Band(3, "進階", 90)));

    private static Ev ev(int skill, String type, int score, boolean verified) { return new Ev(skill, type, 1, type, score, verified, null, null, ""); }

    @Test
    void tiersFollowTeacherTable() {
        assertEquals(0, REF.tierOf(59)); assertEquals(1, REF.tierOf(60)); assertEquals(1, REF.tierOf(69));
        assertEquals(2, REF.tierOf(70)); assertEquals(2, REF.tierOf(84)); assertEquals(3, REF.tierOf(85)); assertEquals(3, REF.tierOf(100));
        assertEquals("未達初階", REF.nameOf(0)); assertEquals("進階", REF.nameOf(3));
    }

    @Test
    void claimedTierUsesBandMidpoint() {
        assertEquals(65, REF.claimScore(1)); assertEquals(78, REF.claimScore(2)); assertEquals(93, REF.claimScore(3));
    }

    @Test
    void bachelorGradesAreUsedAsIs() {
        for (int g : new int[]{0, 55, 60, 72, 85, 100}) assertEquals(g, SkillProfileService.gradeToScore(g, REF, REF));
    }

    @Test
    void graduateGradesAreConvertedToCommonScale() {
        // 研究所及格 70 分 → 共同量尺的初階下限 60；80 → 70；90 → 85
        assertEquals(60, SkillProfileService.gradeToScore(70, GRAD, REF));
        assertEquals(70, SkillProfileService.gradeToScore(80, GRAD, REF));
        assertEquals(85, SkillProfileService.gradeToScore(90, GRAD, REF));
        assertEquals(100, SkillProfileService.gradeToScore(100, GRAD, REF));
        assertEquals(78, SkillProfileService.gradeToScore(85, GRAD, REF));       // 70 + 5/10 × 15 = 77.5 → 78
        assertTrue(SkillProfileService.gradeToScore(69, GRAD, REF) < 60);        // 研究所 69 分不及格 → 未達初階
        int prev = -1;
        for (int g = 0; g <= 100; g++) { int v = SkillProfileService.gradeToScore(g, GRAD, REF); assertTrue(v >= prev, "換算須單調遞增"); prev = v; }
    }

    @Test
    void sameSkillFromSeveralCoursesDoesNotStack() {
        Agg a = SkillProfileService.aggregate(List.of(ev(1, "COURSE", 72, false), ev(1, "COURSE", 88, false), ev(1, "COURSE", 80, false)), 100).get(1);
        assertEquals(88, a.score());      // 取最高，不相加
        assertEquals(3, a.count());       // 全部證據都保留
        assertEquals("COURSE", a.trust(REF));
    }

    @Test
    void unverifiedClaimAboveCourseTierIsSelfDeclared() {
        // 課程 72（中階）＋ 未驗證作品集自述進階 93 → 分數 93，但階級靠自述
        Agg a = SkillProfileService.aggregate(List.of(ev(1, "COURSE", 72, false), ev(1, "PORTFOLIO", 93, false)), 100).get(1);
        assertEquals(93, a.score()); assertEquals("PORTFOLIO", a.source()); assertEquals("SELF", a.trust(REF));
        // 同一階級內的自述不改變可信狀態：課程 88（進階）＋ 自述進階 93
        Agg b = SkillProfileService.aggregate(List.of(ev(1, "COURSE", 88, false), ev(1, "SELF", 93, false)), 100).get(1);
        assertEquals("COURSE", b.trust(REF));
        // 只有自我評估
        assertEquals("SELF", SkillProfileService.aggregate(List.of(ev(1, "SELF", 65, false)), 100).get(1).trust(REF));
    }

    @Test
    void verifiedEvidenceAtCurrentTierMakesSkillVerified() {
        Agg a = SkillProfileService.aggregate(List.of(ev(1, "COURSE", 91, false), ev(1, "CASE", 91, true)), 100).get(1);
        assertEquals("VERIFIED", a.trust(REF)); assertEquals("CASE", a.source());          // 同分時以已驗證的證據為來源
        // 已驗證證據只到中階，目前階級是進階（靠課程）→ 不算已驗證
        Agg b = SkillProfileService.aggregate(List.of(ev(1, "COURSE", 91, false), ev(1, "CERTIFICATE", 78, true)), 100).get(1);
        assertEquals("COURSE", b.trust(REF)); assertEquals(78, b.verified());
    }

    @Test
    void selfDeclaredCapLimitsUnverifiedClaimsOnly() {
        // 上限 84：未驗證的自述最高到中階；課程成績與已驗證證據不受限
        var evs = List.of(ev(1, "PORTFOLIO", 93, false), ev(2, "COURSE", 95, false), ev(3, "CERTIFICATE", 93, true));
        var agg = SkillProfileService.aggregate(evs, 84);
        assertEquals(84, agg.get(1).score()); assertEquals(95, agg.get(2).score()); assertEquals(93, agg.get(3).score());
    }

    @Test
    void semesterMapsToItsEndDate() {
        assertEquals(LocalDate.of(2026, 1, 20), SkillProfileService.semesterEnd("114-1"));
        assertEquals(LocalDate.of(2026, 6, 25), SkillProfileService.semesterEnd("114-2"));
        assertNull(SkillProfileService.semesterEnd("未知"));
    }
}
