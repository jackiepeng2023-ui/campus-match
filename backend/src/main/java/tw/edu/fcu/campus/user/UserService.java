package tw.edu.fcu.campus.user;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.config.JwtService;
import tw.edu.fcu.campus.notify.NotificationService;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.*;

@Service
public class UserService {
    private final Db db;
    private final PasswordEncoder encoder;
    private final JwtService jwt;
    private final StatsService stats;
    private final DemoClock clock;
    private final NotificationService notify;
    private final SkillProfileService profile;

    public UserService(Db db, PasswordEncoder encoder, JwtService jwt, StatsService stats, DemoClock clock, NotificationService notify, SkillProfileService profile) {
        this.db = db; this.encoder = encoder; this.jwt = jwt; this.stats = stats; this.clock = clock; this.notify = notify; this.profile = profile;
    }

    // ---------- 註冊 / 登入 ----------
    public record RegisterIn(String studentNo, String name, String email, String password, String degree, Integer year,
                             Integer departmentId, Integer entryYear, String expectedGraduation, Integer hoursPerWeek, Boolean consent, Boolean aiConsent) {}

    /** 同意條款版本：v2 起加入「AI 助理」用途（技能檔以去識別化形式送至外部語言模型，D56） */
    public static final String TERMS_VERSION = "v2";

    /** 目前學年度（民國）：8 月起算新學年 */
    public int currentAcademicYear() {
        LocalDate d = LocalDate.now(clock);
        return d.getYear() - 1911 - (d.getMonthValue() < 8 ? 1 : 0);
    }

    @Transactional
    public Map<String, Object> register(RegisterIn in) {
        if (in.consent() == null || !in.consent()) throw ApiException.badRequest("必須同意個資使用與保存期限條款");
        if (blank(in.studentNo()) || blank(in.name()) || blank(in.email()) || blank(in.password())) throw ApiException.badRequest("學號、姓名、Email、密碼為必填");
        if (!Set.of("BACHELOR", "MASTER", "PHD").contains(in.degree())) throw ApiException.badRequest("學制須為 BACHELOR／MASTER／PHD");
        if (in.year() == null || in.year() < 1 || in.year() > 7) throw ApiException.badRequest("年級須介於 1–7");
        if (in.departmentId() == null || db.count("SELECT count(*) FROM departments WHERE id = :d", "d", in.departmentId()) == 0) throw ApiException.badRequest("系所不存在");
        int entryYear = in.entryYear() == null ? currentAcademicYear() - (in.year() - 1) : in.entryYear();   // 未填則由年級推算
        if (entryYear < 90 || entryYear > currentAcademicYear() + 1) throw ApiException.badRequest("入學學年度須為民國年（例如 115）");
        if (db.count("SELECT count(*) FROM users WHERE student_no = :s OR email = :e", "s", in.studentNo(), "e", in.email()) > 0)
            throw ApiException.conflict("DUPLICATE", "學號或 Email 已註冊");
        LocalDate grad;
        try { grad = LocalDate.parse(in.expectedGraduation()); } catch (Exception e) { throw ApiException.badRequest("預計畢業日格式須為 YYYY-MM-DD"); }
        int id = db.insertReturningId("""
                INSERT INTO users (student_no, name, email, password_hash, degree, year, department_id, entry_year, expected_graduation)
                VALUES (:s, :n, :e, :p, :d, :y, :dep, :ey, :g) RETURNING id""",
                "s", in.studentNo().trim(), "n", in.name().trim(), "e", in.email().trim().toLowerCase(), "p", encoder.encode(in.password()),
                "d", in.degree(), "y", in.year(), "dep", in.departmentId(), "ey", entryYear, "g", grad);
        LocalDate today = LocalDate.now(clock);
        db.exec("INSERT INTO user_availability VALUES (:u, :h, :f, :t)", "u", id, "h", in.hoursPerWeek() == null ? 8 : in.hoursPerWeek(), "f", today, "t", today.plusMonths(6));
        db.exec("INSERT INTO consents (user_id, purpose, terms_version, agreed_at) VALUES (:u, 'MATCHING', :v, :t), (:u, 'RETENTION', :v, :t)", "u", id, "v", TERMS_VERSION, "t", Db.ts(clock.instant()));
        if (Boolean.TRUE.equals(in.aiConsent())) setAiConsent(id, true);
        notify.log(id, "user", id, "REGISTER", null);
        return Map.of("token", jwt.issue(id, "STUDENT", in.name().trim()), "user", me(id));
    }

    public record LoginIn(String account, String password) {}

    public Map<String, Object> login(LoginIn in) {
        var u = db.one("SELECT id, name, role, password_hash FROM users WHERE (email = :a OR student_no = :a) AND deidentified_at IS NULL", "a", in.account() == null ? "" : in.account().trim().toLowerCase());
        if (u == null) u = db.one("SELECT id, name, role, password_hash FROM users WHERE student_no = :a AND deidentified_at IS NULL", "a", in.account() == null ? "" : in.account().trim());
        if (u == null || !encoder.matches(in.password() == null ? "" : in.password(), (String) u.get("password_hash")))
            throw new ApiException(401, "BAD_CREDENTIALS", "帳號或密碼錯誤");
        int id = Db.i(u.get("id"));
        return Map.of("token", jwt.issue(id, (String) u.get("role"), (String) u.get("name")), "user", me(id));
    }

    // ---------- 本人檔案（含原始成績，D16） ----------
    public Map<String, Object> me(int uid) {
        Map<String, Object> m = new LinkedHashMap<>(basic(uid));
        m.put("availability", db.one("SELECT hours_per_week \"hoursPerWeek\", available_from \"availableFrom\", available_to \"availableTo\" FROM user_availability WHERE user_id = :u", "u", uid));
        m.put("grades", db.list("""
                SELECT g.id, g.course_id "courseId", co.name course, co.code, co.requirement, co.credits, co.grade_year "gradeYear", co.term,
                       d.name department, g.score, g.semester,
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map cm JOIN skills s ON s.id = cm.skill_id WHERE cm.course_id = co.id AND cm.approved) skills,
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map cm JOIN skills s ON s.id = cm.skill_id WHERE cm.course_id = co.id AND NOT cm.approved) "pendingSkills"
                FROM user_grades g JOIN courses co ON co.id = g.course_id LEFT JOIN departments d ON d.id = co.department_id
                WHERE g.user_id = :u ORDER BY g.semester DESC, co.requirement, co.name""", "u", uid));
        m.put("skills", profile.ownerSkills(uid));
        m.put("credentials", profile.credentials(uid));
        m.put("awards", awards(uid));
        m.put("levelBands", profile.bandsOf(uid).list());
        m.put("aiConsent", hasAiConsent(uid));
        m.put("stats", stats.of(uid).toMap());
        m.put("unreadNotifications", db.count("SELECT count(*) FROM notifications WHERE user_id = :u AND read_at IS NULL", "u", uid));
        return m;
    }

    // ---------- AI 助理同意（D56）：未同意時助理只用規則模式，不呼叫外部模型 ----------
    public boolean hasAiConsent(int uid) {
        var c = db.one("SELECT purpose FROM consents WHERE user_id = :u AND purpose IN ('AI_ASSISTANT','AI_ASSISTANT_REVOKED') ORDER BY agreed_at DESC, id DESC LIMIT 1", "u", uid);
        return c != null && "AI_ASSISTANT".equals(c.get("purpose"));
    }

    public Map<String, Object> setAiConsent(int uid, boolean agree) {
        db.exec("INSERT INTO consents (user_id, purpose, terms_version, agreed_at) VALUES (:u, :p, :v, :t)",
                "u", uid, "p", agree ? "AI_ASSISTANT" : "AI_ASSISTANT_REVOKED", "v", TERMS_VERSION, "t", Db.ts(clock.instant()));
        notify.log(uid, "user", uid, agree ? "AI_CONSENT" : "AI_CONSENT_REVOKE", null);
        return Map.of("aiConsent", agree);
    }

    private Map<String, Object> basic(int uid) {
        return db.required("""
                SELECT u.id, u.student_no "studentNo", u.name, u.email, u.degree, u.year, u.role, u.department_id "departmentId", u.entry_year "entryYear",
                       d.name department, c.name college, u.expected_graduation "expectedGraduation", u.demo_tag "demoTag", u.created_at "createdAt"
                FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges c ON c.id = d.college_id WHERE u.id = :u""", "找不到使用者", "u", uid);
    }

    public List<Map<String, Object>> awards(int uid) {
        return db.list("""
                SELECT a.id, a.competition, a.level, a.rank, a.award_date "awardDate", am.score, a.proof_url "proofUrl", a.verified,
                       (SELECT string_agg(s.name, '、') FROM award_skills ak JOIN skills s ON s.id = ak.skill_id WHERE ak.award_id = a.id) skills
                FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level WHERE a.user_id = :u ORDER BY a.award_date DESC""", "u", uid);
    }

    /** 公開檔案：只有技能階級與「自述／已驗證」，沒有分數與成績（D16） */
    public Map<String, Object> publicProfile(int uid) {
        var b = basic(uid);
        Map<String, Object> m = new LinkedHashMap<>();
        for (String k : List.of("id", "name", "degree", "year", "department", "college")) m.put(k, b.get(k));
        m.put("skills", profile.publicSkills(uid));
        m.put("awards", awards(uid));
        m.put("stats", stats.of(uid).toMap());
        m.put("availability", db.one("SELECT hours_per_week \"hoursPerWeek\", available_from \"availableFrom\", available_to \"availableTo\" FROM user_availability WHERE user_id = :u", "u", uid));
        return m;
    }

    // ---------- 成績 → 技能等級（D10、D14） ----------
    /** skillIds：學生對「尚無技能對照」的科目自填對應技能 → 寫入 course_skill_map(source=SELF, approved=false)，待管理員核准後才影響排序 */
    public record GradeIn(Integer courseId, Integer score, String semester, List<Integer> skillIds) {}

    @Transactional
    public Map<String, Object> upsertGrades(int uid, List<GradeIn> grades) {
        Integer entryYear = db.scalar(Integer.class, "SELECT entry_year FROM users WHERE id = :u", "u", uid);
        for (GradeIn g : grades) {
            if (g.courseId() == null || g.score() == null || g.score() < 0 || g.score() > 100) throw ApiException.badRequest("課程與 0–100 分數為必填");
            var co = db.one("SELECT grade_year, term FROM courses WHERE id = :c", "c", g.courseId());
            if (co == null) throw ApiException.badRequest("科目不存在");
            String sem = g.semester();
            if (sem == null || sem.isBlank()) {                      // 學期預設：入學學年度 + 年級 − 1，學期依科目表
                int base = entryYear != null ? entryYear : currentAcademicYear();
                int gy = co.get("grade_year") == null ? 1 : Db.i(co.get("grade_year"));
                int term = co.get("term") == null ? 1 : Db.i(co.get("term"));
                sem = (base + gy - 1) + "-" + term;
            }
            if (!sem.matches("\\d{2,3}-[12]")) throw ApiException.badRequest("學期格式須為 學年度-學期，例如 115-1");
            db.exec("""
                    INSERT INTO user_grades (user_id, course_id, score, semester) VALUES (:u, :c, :s, :sem)
                    ON CONFLICT (user_id, course_id) DO UPDATE SET score = excluded.score, semester = excluded.semester""",
                    "u", uid, "c", g.courseId(), "s", g.score(), "sem", sem);
            if (g.skillIds() != null) for (Integer sk : g.skillIds()) if (sk != null)
                db.exec("INSERT INTO course_skill_map (course_id, skill_id, source, confidence, approved) VALUES (:c, :s, 'SELF', 0.5, FALSE) ON CONFLICT DO NOTHING", "c", g.courseId(), "s", sk);
        }
        profile.rebuild(uid);
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteGrade(int uid, int gradeId) {
        db.exec("DELETE FROM user_grades WHERE id = :g AND user_id = :u", "g", gradeId, "u", uid);
        profile.rebuild(uid);
        return me(uid);
    }

    // ---------- 自我評估（自述證據，D7、D54） ----------
    /** level：1 初階／2 中階／3 進階。寫入一筆 SELF 證據；是否影響排序取決於統一規則（不疊加、自述可封頂） */
    public record SkillIn(Integer skillId, Integer level) {}

    @Transactional
    public Map<String, Object> upsertSkills(int uid, List<SkillIn> skills) {
        for (SkillIn s : skills) {
            if (s.skillId() == null || s.level() == null) throw ApiException.badRequest("技能與階級（1 初階／2 中階／3 進階）為必填");
            profile.selfAssess(uid, s.skillId(), s.level());
        }
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteSkill(int uid, int skillId) {
        profile.removeSelfAssessment(uid, skillId);
        return me(uid);
    }

    // ---------- 證照、作品集（自述證據，D54） ----------
    @Transactional
    public Map<String, Object> addCredential(int uid, SkillProfileService.CredentialIn in) { profile.addCredential(uid, in); return me(uid); }

    @Transactional
    public Map<String, Object> deleteCredential(int uid, int id) { profile.deleteCredential(uid, id); return me(uid); }

    // ---------- 得獎（D8、D41） ----------
    public record AwardIn(String competition, String level, String rank, String awardDate, List<Integer> skillIds, String proofUrl) {}

    @Transactional
    public Map<String, Object> addAward(int uid, AwardIn in) {
        if (blank(in.competition()) || !Set.of("CAMPUS", "NATIONAL", "INTERNATIONAL").contains(in.level()) || !Set.of("FIRST", "TOP3", "HONORABLE", "FINALIST").contains(in.rank()))
            throw ApiException.badRequest("競賽名稱、層級（CAMPUS／NATIONAL／INTERNATIONAL）、名次（FIRST／TOP3／HONORABLE／FINALIST）為必填");
        LocalDate date;
        try { date = LocalDate.parse(in.awardDate()); } catch (Exception e) { throw ApiException.badRequest("得獎日期格式須為 YYYY-MM-DD"); }
        int maxSkills = Math.max(1, profile.param("max_skills_per_evidence", 5));
        if (in.skillIds() != null && in.skillIds().size() > maxSkills) throw ApiException.badRequest("每筆競賽最多對應 " + maxSkills + " 個技能");
        String proof = in.proofUrl() == null || in.proofUrl().isBlank() ? null : in.proofUrl().trim();
        if (proof != null && !proof.matches("^https?://\\S+$")) throw ApiException.badRequest("證明連結須為 http(s) 網址");
        int id = db.insertReturningId("INSERT INTO user_awards (user_id, competition, level, rank, award_date, proof_url) VALUES (:u, :c, :l, :r, :d, :p) RETURNING id",
                "u", uid, "c", in.competition().trim(), "l", in.level(), "r", in.rank(), "d", date, "p", proof);
        if (in.skillIds() != null) for (int s : in.skillIds()) db.exec("INSERT INTO award_skills VALUES (:a, :s) ON CONFLICT DO NOTHING", "a", id, "s", s);
        profile.rebuild(uid);
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteAward(int uid, int awardId) {
        db.exec("DELETE FROM user_awards WHERE id = :a AND user_id = :u", "a", awardId, "u", uid);
        profile.rebuild(uid);
        return me(uid);
    }

    public record AvailabilityIn(Integer hoursPerWeek, String availableFrom, String availableTo) {}

    public Map<String, Object> updateAvailability(int uid, AvailabilityIn in) {
        if (in.hoursPerWeek() == null || in.hoursPerWeek() < 0 || in.hoursPerWeek() > 80) throw ApiException.badRequest("每週時數須介於 0–80");
        LocalDate f, t;
        try { f = LocalDate.parse(in.availableFrom()); t = LocalDate.parse(in.availableTo()); } catch (Exception e) { throw ApiException.badRequest("日期格式須為 YYYY-MM-DD"); }
        if (t.isBefore(f)) throw ApiException.badRequest("結束日不可早於開始日");
        db.exec("INSERT INTO user_availability VALUES (:u, :h, :f, :t) ON CONFLICT (user_id) DO UPDATE SET hours_per_week = :h, available_from = :f, available_to = :t",
                "u", uid, "h", in.hoursPerWeek(), "f", f, "t", t);
        return me(uid);
    }

    public record GraduationIn(String status, String expectedGraduation, String degree) {}

    /** 畢業確認（D29）：GRADUATED／EXTENDED（延畢，更新日期）／CONTINUING（升學，更新學制與日期） */
    public Map<String, Object> confirmGraduation(int uid, GraduationIn in) {
        if ("GRADUATED".equals(in.status())) {
            db.exec("UPDATE users SET expected_graduation = :d WHERE id = :u", "d", LocalDate.now(clock), "u", uid);
        } else if ("EXTENDED".equals(in.status()) || "CONTINUING".equals(in.status())) {
            LocalDate d;
            try { d = LocalDate.parse(in.expectedGraduation()); } catch (Exception e) { throw ApiException.badRequest("請提供新的預計畢業日"); }
            if ("CONTINUING".equals(in.status())) {
                if (!Set.of("MASTER", "PHD").contains(in.degree())) throw ApiException.badRequest("升學須指定新學制 MASTER／PHD");
                db.exec("UPDATE users SET expected_graduation = :d, degree = :g, year = 1, grad_reminded_at = NULL WHERE id = :u", "d", d, "g", in.degree(), "u", uid);
            } else db.exec("UPDATE users SET expected_graduation = :d, grad_reminded_at = NULL WHERE id = :u", "d", d, "u", uid);
        } else throw ApiException.badRequest("status 須為 GRADUATED／EXTENDED／CONTINUING");
        return me(uid);
    }

    // ---------- 刪除帳號：去識別化＋刪除個人資料（D26、D28） ----------
    @Transactional
    public void deleteAccount(int uid) {
        deidentify(uid);
        purge(uid);
    }

    public void deidentify(int uid) {
        db.exec("""
                UPDATE users SET name = '已離開的成員', email = 'deleted-' || id || '@invalid', student_no = 'DEL-' || id,
                       demo_tag = NULL, deidentified_at = coalesce(deidentified_at, :t) WHERE id = :u""", "t", Db.ts(clock.instant()), "u", uid);
        db.exec("DELETE FROM device_tokens WHERE user_id = :u", "u", uid);
    }

    public void purge(int uid) {
        db.exec("DELETE FROM user_grades WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM skill_level_history WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM skill_evidence WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM user_credentials WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM agent_sessions WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM agent_actions WHERE user_id = :u", "u", uid);
        db.exec("UPDATE llm_calls SET user_id = NULL WHERE user_id = :u", "u", uid);        // 用量紀錄只留 token 與耗時，不再連到本人
        db.exec("DELETE FROM user_skills WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM award_skills WHERE award_id IN (SELECT id FROM user_awards WHERE user_id = :u)", "u", uid);
        db.exec("DELETE FROM user_awards WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM user_availability WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM notifications WHERE user_id = :u", "u", uid);
        db.exec("DELETE FROM recommendations WHERE user_id = :u", "u", uid);
        db.exec("UPDATE reviews SET comment = NULL WHERE reviewee_id = :u OR reviewer_id = :u", "u", uid);
        db.exec("UPDATE engagements SET status = 'WITHDRAWN', decided_at = :t WHERE user_id = :u AND status = 'PENDING'", "t", Db.ts(clock.instant()), "u", uid);
        db.exec("UPDATE users SET purged_at = coalesce(purged_at, :t), password_hash = 'PURGED' WHERE id = :u", "t", Db.ts(clock.instant()), "u", uid);
    }

    private static boolean blank(String s) { return s == null || s.isBlank(); }

    public static ZoneId zone() { return ZoneId.of("Asia/Taipei"); }
}
