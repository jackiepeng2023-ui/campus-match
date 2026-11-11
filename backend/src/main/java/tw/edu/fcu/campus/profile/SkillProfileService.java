package tw.edu.fcu.campus.profile;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;

import java.sql.Date;
import java.time.LocalDate;
import java.util.*;

/**
 * 能力盤點模組（獨立於三個媒合 Agent）：把分散的證據彙整成 Skill Profile（Skill／Level／Evidence）。
 *
 * 證據來源與分數（統一規則，D53–D55）：
 *   COURSE       修課成績；技能由科目→技能對照（規則／課綱 AI／管理員核准）決定，每門課最多 N 個技能。
 *                研究所成績先依研究所門檻換算到共同量尺（D14：研究所及格 70 分）。
 *   CERTIFICATE  證照：命中證照對照表時用對照表分數，否則用學生自選階級的代表分數
 *   PORTFOLIO    作品集：學生自選階級的代表分數
 *   SELF         自我評估：學生自選階級的代表分數
 *   COMPETITION  競賽得獎：60 + 40 × 得獎矩陣分數
 *   CASE         平台上結案的案件：隊友互評相符度達門檻才產生，且一律為「已驗證」
 * 同一技能的多筆證據不疊加：技能分數 = 最高分；全部證據保留在 skill_evidence。
 * 可信狀態三種：VERIFIED 已驗證（管理員審核證明、結案互評確認）／COURSE 修課成績（誠信自填）／SELF 自述（證照、作品集、得獎、自評尚未驗證）。
 * 自述證據可設分數上限（system_params.self_declared_cap）。等級三階的門檻在 level_bands，可由管理員修改。
 */
@Service
public class SkillProfileService {
    private final Db db;
    private final DemoClock clock;

    public SkillProfileService(Db db, DemoClock clock) { this.db = db; this.clock = clock; }

    // ---------- 等級三階 ----------
    public record Band(int tier, String name, int minScore) {}

    public static final class Bands {
        private final List<Band> list;   // 依 tier 由小到大
        public Bands(List<Band> list) { this.list = list; }
        public List<Band> list() { return list; }
        public int tierOf(int score) { int t = 0; for (Band b : list) if (score >= b.minScore()) t = b.tier(); return t; }
        public String nameOf(int tier) { for (Band b : list) if (b.tier() == tier) return b.name(); return "未達初階"; }
        public int minScore(int tier) { for (Band b : list) if (b.tier() == tier) return b.minScore(); return 0; }
        /** 自選階級的代表分數：該階上下界的中點（預設 初階 65、中階 78、進階 93） */
        public int claimScore(int tier) {
            int lo = minScore(tier), hi = 100;
            for (Band b : list) if (b.tier() == tier + 1) hi = b.minScore();
            return (int) Math.round((lo + hi) / 2.0);
        }
        public static final Bands DEFAULT = new Bands(List.of(new Band(1, "初階", 60), new Band(2, "中階", 70), new Band(3, "進階", 85)));
    }

    private Bands load(String group) {
        List<Band> l = db.list("SELECT tier, name, min_score FROM level_bands WHERE degree_group = :g ORDER BY tier", "g", group).stream()
                .map(r -> new Band(Db.i(r.get("tier")), (String) r.get("name"), Db.i(r.get("min_score")))).toList();
        return l.isEmpty() ? Bands.DEFAULT : new Bands(l);
    }

    /** 共同量尺（Skill 資料庫的 Level 標準）：學士成績直接採用 */
    public Bands bands() { return load("BACHELOR"); }
    public Bands bands(String degree) { return bands(); }
    public Bands bandsOf(int uid) { return bands(); }

    /** 修課成績的門檻：研究所另訂（預設 70／80／90），用來把研究所成績換算到共同量尺 */
    public Bands gradeBands(String degree) { return load("BACHELOR".equals(degree) ? "BACHELOR" : "GRADUATE"); }

    /** 成績 → 共同量尺分數：以各階門檻為錨點分段線性換算（學士為恆等） */
    public static int gradeToScore(int grade, Bands from, Bands to) {
        int[] a = {0, from.minScore(1), from.minScore(2), from.minScore(3), 100}, b = {0, to.minScore(1), to.minScore(2), to.minScore(3), 100};
        int g = Math.max(0, Math.min(100, grade));
        for (int i = 0; i < 4; i++)
            if (g <= a[i + 1] || i == 3) {
                if (a[i + 1] == a[i]) return b[i + 1];
                return (int) Math.round(b[i] + (g - a[i]) * (double) (b[i + 1] - b[i]) / (a[i + 1] - a[i]));
            }
        return g;
    }

    public int param(String key, int dflt) {
        Integer v = db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = :k", "k", key);
        return v == null ? dflt : v;
    }

    public static String typeLabel(String type) {
        return switch (type) { case "COURSE" -> "課程"; case "CERTIFICATE" -> "證照"; case "PORTFOLIO" -> "作品集"; case "COMPETITION" -> "競賽"; case "CASE" -> "結案"; default -> "自評"; };
    }

    // ---------- 彙整 ----------
    record Ev(int skillId, String type, Integer refId, String title, int score, boolean verified, String proofUrl, LocalDate on, String detail) {}

    @Transactional
    public void rebuild(int uid) { rebuild(uid, true); }

    /** 重新盤點一位學生：蒐集全部證據 → 寫入 skill_evidence → 依統一規則更新 user_skills（Skill Profile） */
    @Transactional
    public void rebuild(int uid, boolean recordHistory) {
        String degree = db.scalar(String.class, "SELECT degree FROM users WHERE id = :u", "u", uid);
        if (degree == null) return;
        Bands bands = bands(), gradeBands = gradeBands(degree);
        int cap = param("self_declared_cap", 100), maxSkills = Math.max(1, param("max_skills_per_evidence", 5));
        boolean courseVerified = param("course_grade_verified", 0) == 1;
        List<Ev> evs = new ArrayList<>();

        // 1. 課程：每門課取信心最高的前 N 個技能
        Map<Integer, Integer> perCourse = new HashMap<>();
        for (var r : db.list("""
                SELECT g.id gid, co.name, g.score, g.semester, co.requirement, m.skill_id
                FROM user_grades g JOIN courses co ON co.id = g.course_id
                JOIN course_skill_map m ON m.course_id = g.course_id AND m.approved
                WHERE g.user_id = :u ORDER BY g.id, m.confidence DESC, m.skill_id""", "u", uid)) {
            int gid = Db.i(r.get("gid"));
            if (perCourse.merge(gid, 1, Integer::sum) > maxSkills) continue;
            String req = switch (String.valueOf(r.get("requirement"))) { case "REQUIRED" -> "必修"; case "GENERAL" -> "通識"; default -> "選修"; };
            int grade = Db.i(r.get("score")), score = gradeToScore(grade, gradeBands, bands);
            String sem = r.get("semester") == null ? "" : String.valueOf(r.get("semester"));
            evs.add(new Ev(Db.i(r.get("skill_id")), "COURSE", gid, (String) r.get("name"), score, courseVerified, null, semesterEnd(sem),
                    (sem.isBlank() ? "" : sem + " 學期・") + req + "・成績 " + grade + (score != grade ? "（研究所換算 " + score + "）" : "")));
        }
        // 2. 證照、作品集、自我評估
        for (var r : db.list("""
                SELECT c.id, c.type, c.title, c.issuer, coalesce(c.obtained_on, (c.created_at AT TIME ZONE 'Asia/Taipei')::date) obtained_on,
                       c.claimed_score, c.proof_url, c.verified, cs.skill_id
                FROM user_credentials c JOIN credential_skills cs ON cs.credential_id = c.id WHERE c.user_id = :u ORDER BY c.id""", "u", uid)) {
            String detail = r.get("issuer") == null ? "" : String.valueOf(r.get("issuer"));
            evs.add(new Ev(Db.i(r.get("skill_id")), (String) r.get("type"), Db.i(r.get("id")), (String) r.get("title"), Db.i(r.get("claimed_score")),
                    Boolean.TRUE.equals(r.get("verified")), (String) r.get("proof_url"), date(r.get("obtained_on")), detail));
        }
        // 3. 競賽得獎
        for (var r : db.list("""
                SELECT a.id, a.competition, a.level, a.rank, a.award_date, a.proof_url, a.verified, am.score ms, ak.skill_id
                FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level
                JOIN award_skills ak ON ak.award_id = a.id WHERE a.user_id = :u ORDER BY a.id""", "u", uid)) {
            int score = 60 + (int) Math.round(40 * Db.d(r.get("ms")));
            evs.add(new Ev(Db.i(r.get("skill_id")), "COMPETITION", Db.i(r.get("id")), (String) r.get("competition"), Math.min(100, score),
                    Boolean.TRUE.equals(r.get("verified")), (String) r.get("proof_url"), date(r.get("award_date")),
                    awardLevel((String) r.get("level")) + "・" + awardRank((String) r.get("rank"))));
        }
        // 4. 結案（完成）且隊友相符度達門檻 → 已驗證證據
        Map<Integer, Integer> claim = new HashMap<>();
        for (Ev e : evs) claim.merge(e.skillId(), effective(e, cap), Math::max);
        int minMatch = param("case_evidence_min_match_x10", 30), confirmMatch = param("case_confirm_match_x10", 40);
        for (var r : db.list("""
                SELECT c.id, c.title, c.closed_at, r.role_name, rs.skill_id, rs.min_level,
                       (SELECT avg(rv.match_score) FROM reviews rv WHERE rv.case_id = c.id AND rv.reviewee_id = m.user_id
                          AND rv.submitted_at IS NOT NULL AND rv.revealed_at IS NOT NULL) match_avg
                FROM case_members m JOIN cases c ON c.id = m.case_id AND c.status = 'CLOSED' AND c.close_result = 'COMPLETED'
                JOIN case_roles r ON r.id = m.case_role_id JOIN case_role_skills rs ON rs.case_role_id = r.id
                WHERE m.user_id = :u AND NOT m.is_owner ORDER BY c.id""", "u", uid)) {
            if (r.get("match_avg") == null) continue;                       // 互評尚未公開
            double match = Db.d(r.get("match_avg"));
            if (match * 10 < minMatch) continue;                            // 被評為與檔案不符：不產生證據（另由可信度係數調降）
            int skillId = Db.i(r.get("skill_id"));
            int score = bands.minScore(Db.i(r.get("min_level")));
            if (match * 10 >= confirmMatch) score = Math.max(score, claim.getOrDefault(skillId, 0));
            evs.add(new Ev(skillId, "CASE", Db.i(r.get("id")), (String) r.get("title"), Math.min(100, score), true, null,
                    r.get("closed_at") == null ? null : Db.instant(r.get("closed_at")).atZone(ZONE).toLocalDate(),
                    "角色：" + r.get("role_name") + "・隊友相符度 " + String.format("%.1f", match)));
        }

        // 寫入證據
        db.exec("DELETE FROM skill_evidence WHERE user_id = :u", "u", uid);
        for (Ev e : evs)
            db.exec("""
                    INSERT INTO skill_evidence (user_id, skill_id, type, ref_id, title, score, verified, proof_url, occurred_on, detail)
                    VALUES (:u, :s, :t, :r, :ti, :sc, :v, :p, :o, :d)""",
                    "u", uid, "s", e.skillId(), "t", e.type(), "r", e.refId(), "ti", cut(e.title(), 200), "sc", e.score(), "v", e.verified(),
                    "p", e.proofUrl(), "o", e.on(), "d", cut(e.detail(), 200));

        // 統一規則：不疊加，取最高；自述證據受上限限制
        Map<Integer, Agg> agg = aggregate(evs, cap);
        Map<Integer, Object[]> old = new HashMap<>();      // skill → {score, trust}
        for (var r : db.list("SELECT skill_id, score, trust FROM user_skills WHERE user_id = :u", "u", uid))
            old.put(Db.i(r.get("skill_id")), new Object[]{Db.i(r.get("score")), r.get("trust")});
        var now = Db.ts(clock.instant());
        for (var en : agg.entrySet()) {
            int skillId = en.getKey(); Agg a = en.getValue();
            String trust = a.trust(bands);
            db.exec("""
                    INSERT INTO user_skills (user_id, skill_id, score, level, verified_score, trust, self_declared, evidence_count, source, updated_at)
                    VALUES (:u, :s, :sc, :l, :vs, :tr, :sd, :n, :src, :t)
                    ON CONFLICT (user_id, skill_id) DO UPDATE SET score = :sc, level = :l, verified_score = :vs, trust = :tr, self_declared = :sd,
                        evidence_count = :n, source = :src, updated_at = :t""",
                    "u", uid, "s", skillId, "sc", a.score(), "l", bands.tierOf(a.score()), "vs", a.verified() == 0 ? null : a.verified(),
                    "tr", trust, "sd", "SELF".equals(trust), "n", a.count(), "src", a.source(), "t", now);
            if (!recordHistory) continue;
            Object[] prev = old.get(skillId);
            if (prev == null || (int) prev[0] != a.score())
                db.exec("INSERT INTO skill_level_history (user_id, skill_id, old_score, new_score, reason, changed_at) VALUES (:u, :s, :o, :n, :r, :t)",
                        "u", uid, "s", skillId, "o", prev == null ? null : prev[0], "n", a.score(), "r", a.source(), "t", now);
            else if (!"VERIFIED".equals(prev[1]) && "VERIFIED".equals(trust))           // 分數不變，但階級由自述／成績變成已驗證
                db.exec("INSERT INTO skill_level_history (user_id, skill_id, old_score, new_score, reason, changed_at) VALUES (:u, :s, :n, :n, 'VERIFIED', :t)",
                        "u", uid, "s", skillId, "n", a.score(), "t", now);
        }
        for (int skillId : old.keySet()) if (!agg.containsKey(skillId)) db.exec("DELETE FROM user_skills WHERE user_id = :u AND skill_id = :s", "u", uid, "s", skillId);
    }

    /**
     * 一個技能的彙整結果：score 取最高；verified／course／declared 分別是三種可信狀態下的最高分。
     * 可信狀態以「階級」比較：已驗證的證據達到目前階級 → VERIFIED；目前階級高於課程與已驗證證據、靠自述撐起 → SELF；其餘 → COURSE。
     */
    public record Agg(int score, int verified, int course, int declared, String source, int count) {
        public String trust(Bands b) {
            int tier = b.tierOf(score);
            if (verified > 0 && b.tierOf(verified) >= tier) return "VERIFIED";
            return b.tierOf(declared) > b.tierOf(course) || (course == 0 && declared > 0) ? "SELF" : "COURSE";
        }
    }

    static int effective(Ev e, int cap) { return e.verified() || "COURSE".equals(e.type()) ? e.score() : Math.min(e.score(), cap); }

    static Map<Integer, Agg> aggregate(List<Ev> evs, int cap) {
        Map<Integer, Agg> agg = new LinkedHashMap<>();
        for (Ev e : evs) {
            int eff = effective(e, cap);
            Agg a = agg.getOrDefault(e.skillId(), new Agg(0, 0, 0, 0, e.type(), 0));
            int v = e.verified() ? Math.max(a.verified(), eff) : a.verified();
            int c = "COURSE".equals(e.type()) ? Math.max(a.course(), eff) : a.course();
            int d = !e.verified() && !"COURSE".equals(e.type()) ? Math.max(a.declared(), eff) : a.declared();
            boolean better = eff > a.score() || (eff == a.score() && e.verified());   // 同分時以已驗證的證據為來源
            agg.put(e.skillId(), new Agg(Math.max(a.score(), eff), v, c, d, better ? e.type() : a.source(), a.count() + 1));
        }
        return agg;
    }

    /** 依證據發生的時間重建成長紀錄（示範資料載入、或管理員重建時使用）：每個技能的分數隨證據出現而墊高 */
    @Transactional
    public void backfillHistory(int uid) {
        int cap = param("self_declared_cap", 100);
        db.exec("DELETE FROM skill_level_history WHERE user_id = :u", "u", uid);
        Bands bands = bands();
        Map<Integer, Integer> best = new HashMap<>(), bestVerified = new HashMap<>();
        for (var r : db.list("SELECT skill_id, type, score, verified, occurred_on FROM skill_evidence WHERE user_id = :u ORDER BY occurred_on NULLS FIRST, score, id", "u", uid)) {
            int skillId = Db.i(r.get("skill_id")), score = Db.i(r.get("score"));
            boolean v = Boolean.TRUE.equals(r.get("verified"));
            String type = (String) r.get("type");
            int eff = v || "COURSE".equals(type) ? score : Math.min(score, cap);
            LocalDate on = date(r.get("occurred_on"));
            java.time.Instant when = on == null ? clock.instant() : on.atTime(12, 0).atZone(ZONE).toInstant();
            var at = Db.ts(when.isAfter(clock.instant()) ? clock.instant() : when);       // 進行中的學期：不寫未來的時間
            int prev = best.getOrDefault(skillId, -1), prevV = bestVerified.getOrDefault(skillId, 0);
            boolean wasVerified = prev >= 0 && prevV > 0 && bands.tierOf(prevV) >= bands.tierOf(prev);
            if (eff > prev) {
                db.exec("INSERT INTO skill_level_history (user_id, skill_id, old_score, new_score, reason, changed_at) VALUES (:u, :s, :o, :n, :r, :t)",
                        "u", uid, "s", skillId, "o", prev < 0 ? null : prev, "n", eff, "r", type, "t", at);
                best.put(skillId, eff);
                if (v) bestVerified.put(skillId, Math.max(prevV, eff));
            } else if (v) {
                bestVerified.put(skillId, Math.max(prevV, eff));
                if (!wasVerified && bands.tierOf(Math.max(prevV, eff)) >= bands.tierOf(prev))
                    db.exec("INSERT INTO skill_level_history (user_id, skill_id, old_score, new_score, reason, changed_at) VALUES (:u, :s, :n, :n, 'VERIFIED', :t)",
                            "u", uid, "s", skillId, "n", prev, "t", at);
            }
        }
    }

    private static final java.time.ZoneId ZONE = java.time.ZoneId.of("Asia/Taipei");

    /** 「114-1」→ 該學期結束日（上學期隔年 1/20、下學期隔年 6/25） */
    static LocalDate semesterEnd(String sem) {
        try {
            String[] p = sem.trim().split("-");
            int y = Integer.parseInt(p[0]) + 1911;
            return "1".equals(p[1]) ? LocalDate.of(y + 1, 1, 20) : LocalDate.of(y + 1, 6, 25);
        } catch (Exception e) { return null; }
    }

    @Transactional
    public int rebuildAll(boolean recordHistory) {
        var ids = db.list("SELECT id FROM users WHERE role = 'STUDENT' AND purged_at IS NULL");
        for (var r : ids) rebuild(Db.i(r.get("id")), recordHistory);
        return ids.size();
    }

    /** 示範資料載入後：全體盤點並依證據時間重建成長紀錄 */
    @Transactional
    public int rebuildAllWithHistory() {
        var ids = db.list("SELECT id FROM users WHERE role = 'STUDENT' AND purged_at IS NULL");
        for (var r : ids) { int uid = Db.i(r.get("id")); rebuild(uid, false); backfillHistory(uid); }
        return ids.size();
    }

    @Transactional
    public int rebuildForCourse(int courseId) {
        var ids = db.list("SELECT DISTINCT user_id FROM user_grades WHERE course_id = :c", "c", courseId);
        for (var r : ids) rebuild(Db.i(r.get("user_id")));
        return ids.size();
    }

    @Transactional
    public void rebuildForCase(int caseId) {
        for (var r : db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId)) rebuild(Db.i(r.get("user_id")));
    }

    // ---------- 輸出 ----------
    public static String trustLabel(String trust) { return switch (trust) { case "VERIFIED" -> "已驗證"; case "SELF" -> "自述"; default -> "修課成績"; }; }

    /** 本人檢視：分數、階級、可信狀態、全部證據 */
    public List<Map<String, Object>> ownerSkills(int uid) {
        Bands bands = bands();
        Map<Integer, List<Map<String, Object>>> ev = new HashMap<>();
        for (var e : db.list("""
                SELECT id, skill_id, type, ref_id "refId", title, score, verified, proof_url "proofUrl", occurred_on "occurredOn", detail
                FROM skill_evidence WHERE user_id = :u ORDER BY score DESC, verified DESC, id""", "u", uid)) {
            int sid = Db.i(e.remove("skill_id"));
            e.put("typeLabel", typeLabel((String) e.get("type")));
            e.put("tier", bands.nameOf(bands.tierOf(Db.i(e.get("score")))));
            ev.computeIfAbsent(sid, k -> new ArrayList<>()).add(e);
        }
        List<Map<String, Object>> out = db.list("""
                SELECT us.skill_id "skillId", s.name, s.category, us.score, us.level, us.verified_score "verifiedScore", us.trust,
                       us.self_declared "selfDeclared", us.evidence_count "evidenceCount", us.source
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY us.score DESC, s.name""", "u", uid);
        for (var s : out) {
            s.put("tier", bands.nameOf(Db.i(s.get("level"))));
            s.put("trustLabel", trustLabel((String) s.get("trust")));
            s.put("sourceLabel", typeLabel((String) s.get("source")));
            s.put("evidence", ev.getOrDefault(Db.i(s.get("skillId")), List.of()));
        }
        return out;
    }

    /** 公開檢視（D16）：只有階級與可信狀態，不含分數與成績 */
    public List<Map<String, Object>> publicSkills(int uid) {
        Bands bands = bands();
        List<Map<String, Object>> out = db.list("""
                SELECT us.skill_id "skillId", s.name, s.category, us.level, us.trust, us.self_declared "selfDeclared", us.evidence_count "evidenceCount",
                       (SELECT string_agg(DISTINCT e.type, ',') FROM skill_evidence e WHERE e.user_id = us.user_id AND e.skill_id = us.skill_id) types
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u AND us.level >= 1 ORDER BY us.level DESC, us.score DESC, s.name""", "u", uid);
        for (var s : out) {
            s.put("tier", bands.nameOf(Db.i(s.get("level"))));
            s.put("trustLabel", trustLabel((String) s.get("trust")));
            String types = (String) s.remove("types");
            s.put("evidenceTypes", types == null ? List.of() : Arrays.stream(types.split(",")).map(SkillProfileService::typeLabel).toList());
        }
        return out;
    }

    public List<Map<String, Object>> credentials(int uid) {
        return db.list("""
                SELECT c.id, c.type, c.title, c.issuer, c.obtained_on "obtainedOn", c.claimed_score "score", c.proof_url "proofUrl", c.note, c.verified,
                       c.catalog_id "catalogId",
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM credential_skills cs JOIN skills s ON s.id = cs.skill_id WHERE cs.credential_id = c.id) skills
                FROM user_credentials c WHERE c.user_id = :u ORDER BY c.type, c.id DESC""", "u", uid);
    }

    // ---------- 學生自填：證照、作品集、自我評估 ----------
    public record CredentialIn(String type, String title, String issuer, String obtainedOn, Integer catalogId, Integer tier,
                               String proofUrl, String note, List<Integer> skillIds) {}

    @Transactional
    public int addCredential(int uid, CredentialIn in) {
        if (!Set.of("CERTIFICATE", "PORTFOLIO", "SELF").contains(in.type())) throw ApiException.badRequest("type 須為 CERTIFICATE（證照）／PORTFOLIO（作品集）／SELF（自我評估）");
        Bands bands = bands();
        int maxSkills = Math.max(1, param("max_skills_per_evidence", 5));
        String title = in.title(), issuer = in.issuer();
        int score;
        List<Integer> skillIds = in.skillIds() == null ? new ArrayList<>() : new ArrayList<>(new LinkedHashSet<>(in.skillIds()));
        if ("CERTIFICATE".equals(in.type()) && in.catalogId() != null) {            // 證照對照表：分數與技能由對照表決定
            var cat = db.required("SELECT name, issuer, score FROM certificate_catalog WHERE id = :id", "證照對照表中沒有這一項", "id", in.catalogId());
            title = (String) cat.get("name"); issuer = (String) cat.get("issuer"); score = Db.i(cat.get("score"));
            skillIds = db.jdbc.queryForList("SELECT skill_id FROM certificate_catalog_skills WHERE catalog_id = :c", Db.params("c", in.catalogId()), Integer.class);
        } else {
            if (in.tier() == null || in.tier() < 1 || in.tier() > 3) throw ApiException.badRequest("請選擇階級：1 初階／2 中階／3 進階");
            score = bands.claimScore(in.tier());
        }
        if (title == null || title.isBlank()) throw ApiException.badRequest("名稱為必填");
        if (skillIds.isEmpty() || skillIds.size() > maxSkills) throw ApiException.badRequest("請從 Skill 指標庫選 1–" + maxSkills + " 個技能");
        LocalDate on = null;
        if (in.obtainedOn() != null && !in.obtainedOn().isBlank()) { try { on = LocalDate.parse(in.obtainedOn()); } catch (Exception e) { throw ApiException.badRequest("日期格式須為 YYYY-MM-DD"); } }
        String proof = in.proofUrl() == null || in.proofUrl().isBlank() ? null : in.proofUrl().trim();
        if (proof != null && !proof.matches("^https?://\\S+$")) throw ApiException.badRequest("證明連結須為 http(s) 網址");
        int id = db.insertReturningId("""
                INSERT INTO user_credentials (user_id, type, title, issuer, obtained_on, catalog_id, claimed_score, proof_url, note, created_at)
                VALUES (:u, :t, :ti, :i, :o, :c, :s, :p, :n, :now) RETURNING id""",
                "u", uid, "t", in.type(), "ti", cut(title.trim(), 120), "i", issuer, "o", on, "c", "CERTIFICATE".equals(in.type()) ? in.catalogId() : null,
                "s", score, "p", proof, "n", cut(in.note(), 300), "now", Db.ts(clock.instant()));
        for (int sk : skillIds) {
            if (db.count("SELECT count(*) FROM skills WHERE id = :s", "s", sk) == 0) throw ApiException.badRequest("技能不存在：" + sk);
            db.exec("INSERT INTO credential_skills VALUES (:c, :s) ON CONFLICT DO NOTHING", "c", id, "s", sk);
        }
        rebuild(uid);
        return id;
    }

    @Transactional
    public void deleteCredential(int uid, int id) {
        db.exec("DELETE FROM user_credentials WHERE id = :id AND user_id = :u", "id", id, "u", uid);
        rebuild(uid);
    }

    /** 自我評估：每個技能一筆 SELF 證據（自述），重複設定則更新 */
    @Transactional
    public void selfAssess(int uid, int skillId, int tier) {
        if (tier < 1 || tier > 3) throw ApiException.badRequest("請選擇階級：1 初階／2 中階／3 進階");
        String name = db.scalar(String.class, "SELECT name FROM skills WHERE id = :s", "s", skillId);
        if (name == null) throw ApiException.badRequest("技能不存在");
        int score = bands().claimScore(tier);
        Integer existing = db.scalar(Integer.class, """
                SELECT c.id FROM user_credentials c JOIN credential_skills cs ON cs.credential_id = c.id
                WHERE c.user_id = :u AND c.type = 'SELF' AND cs.skill_id = :s LIMIT 1""", "u", uid, "s", skillId);
        if (existing != null) db.exec("UPDATE user_credentials SET claimed_score = :sc, verified = FALSE, verified_by = NULL, verified_at = NULL WHERE id = :id", "sc", score, "id", existing);
        else {
            int id = db.insertReturningId("INSERT INTO user_credentials (user_id, type, title, claimed_score, created_at) VALUES (:u, 'SELF', :t, :s, :now) RETURNING id",
                    "u", uid, "t", "自我評估：" + name, "s", score, "now", Db.ts(clock.instant()));
            db.exec("INSERT INTO credential_skills VALUES (:c, :s)", "c", id, "s", skillId);
        }
        rebuild(uid);
    }

    @Transactional
    public void removeSelfAssessment(int uid, int skillId) {
        db.exec("""
                DELETE FROM user_credentials WHERE user_id = :u AND type = 'SELF'
                  AND id IN (SELECT credential_id FROM credential_skills WHERE skill_id = :s)""", "u", uid, "s", skillId);
        rebuild(uid);
    }

    // ---------- 驗證（管理員／教師審核） ----------
    @Transactional
    public void verifyCredential(int credentialId, int adminId, boolean verified) {
        var c = db.required("SELECT user_id FROM user_credentials WHERE id = :id", "找不到這筆證據", "id", credentialId);
        db.exec("UPDATE user_credentials SET verified = :v, verified_by = :a, verified_at = :t WHERE id = :id", "v", verified, "a", verified ? adminId : null,
                "t", verified ? Db.ts(clock.instant()) : null, "id", credentialId);
        rebuild(Db.i(c.get("user_id")));
    }

    @Transactional
    public void verifyAward(int awardId, int adminId, boolean verified) {
        var a = db.required("SELECT user_id FROM user_awards WHERE id = :id", "找不到這筆得獎紀錄", "id", awardId);
        db.exec("UPDATE user_awards SET verified = :v, verified_by = :a, verified_at = :t WHERE id = :id", "v", verified, "a", verified ? adminId : null,
                "t", verified ? Db.ts(clock.instant()) : null, "id", awardId);
        rebuild(Db.i(a.get("user_id")));
    }

    private static LocalDate date(Object o) { return o == null ? null : ((Date) o).toLocalDate(); }
    private static String cut(String s, int n) { return s == null ? null : (s.length() > n ? s.substring(0, n) : s); }
    private static String awardLevel(String l) { return switch (l) { case "NATIONAL" -> "全國"; case "INTERNATIONAL" -> "國際"; default -> "校內"; }; }
    private static String awardRank(String r) { return switch (r) { case "FIRST" -> "第一名"; case "TOP3" -> "前三名"; case "HONORABLE" -> "佳作"; default -> "入圍"; }; }
}
