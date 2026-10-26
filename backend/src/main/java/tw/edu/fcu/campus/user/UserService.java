package tw.edu.fcu.campus.user;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.config.JwtService;
import tw.edu.fcu.campus.notify.NotificationService;

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

    public UserService(Db db, PasswordEncoder encoder, JwtService jwt, StatsService stats, DemoClock clock, NotificationService notify) {
        this.db = db; this.encoder = encoder; this.jwt = jwt; this.stats = stats; this.clock = clock; this.notify = notify;
    }

    // ---------- 註冊 / 登入 ----------
    public record RegisterIn(String studentNo, String name, String email, String password, String degree, Integer year,
                             Integer departmentId, String expectedGraduation, Integer hoursPerWeek, Boolean consent) {}

    @Transactional
    public Map<String, Object> register(RegisterIn in) {
        if (in.consent() == null || !in.consent()) throw ApiException.badRequest("必須同意個資使用與保存期限條款");
        if (blank(in.studentNo()) || blank(in.name()) || blank(in.email()) || blank(in.password())) throw ApiException.badRequest("學號、姓名、Email、密碼為必填");
        if (!Set.of("BACHELOR", "MASTER", "PHD").contains(in.degree())) throw ApiException.badRequest("學制須為 BACHELOR／MASTER／PHD");
        if (in.year() == null || in.year() < 1 || in.year() > 7) throw ApiException.badRequest("年級須介於 1–7");
        if (in.departmentId() == null || db.count("SELECT count(*) FROM departments WHERE id = :d", "d", in.departmentId()) == 0) throw ApiException.badRequest("系所不存在");
        if (db.count("SELECT count(*) FROM users WHERE student_no = :s OR email = :e", "s", in.studentNo(), "e", in.email()) > 0)
            throw ApiException.conflict("DUPLICATE", "學號或 Email 已註冊");
        LocalDate grad;
        try { grad = LocalDate.parse(in.expectedGraduation()); } catch (Exception e) { throw ApiException.badRequest("預計畢業日格式須為 YYYY-MM-DD"); }
        int id = db.insertReturningId("""
                INSERT INTO users (student_no, name, email, password_hash, degree, year, department_id, expected_graduation)
                VALUES (:s, :n, :e, :p, :d, :y, :dep, :g) RETURNING id""",
                "s", in.studentNo().trim(), "n", in.name().trim(), "e", in.email().trim().toLowerCase(), "p", encoder.encode(in.password()),
                "d", in.degree(), "y", in.year(), "dep", in.departmentId(), "g", grad);
        LocalDate today = LocalDate.now(clock);
        db.exec("INSERT INTO user_availability VALUES (:u, :h, :f, :t)", "u", id, "h", in.hoursPerWeek() == null ? 8 : in.hoursPerWeek(), "f", today, "t", today.plusMonths(6));
        db.exec("INSERT INTO consents (user_id, purpose, terms_version, agreed_at) VALUES (:u, 'MATCHING', 'v1', :t), (:u, 'RETENTION', 'v1', :t)", "u", id, "t", Db.ts(clock.instant()));
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
                SELECT g.id, g.course_id "courseId", co.name course, g.score, g.semester,
                       (SELECT string_agg(s.name, '、' ORDER BY s.name) FROM course_skill_map cm JOIN skills s ON s.id = cm.skill_id WHERE cm.course_id = co.id) skills
                FROM user_grades g JOIN courses co ON co.id = g.course_id WHERE g.user_id = :u ORDER BY g.semester DESC, co.name""", "u", uid));
        m.put("skills", skills(uid));
        m.put("awards", awards(uid));
        m.put("stats", stats.of(uid).toMap());
        m.put("unreadNotifications", db.count("SELECT count(*) FROM notifications WHERE user_id = :u AND read_at IS NULL", "u", uid));
        return m;
    }

    private Map<String, Object> basic(int uid) {
        return db.required("""
                SELECT u.id, u.student_no "studentNo", u.name, u.email, u.degree, u.year, u.role, u.department_id "departmentId",
                       d.name department, c.name college, u.expected_graduation "expectedGraduation", u.demo_tag "demoTag", u.created_at "createdAt"
                FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges c ON c.id = d.college_id WHERE u.id = :u""", "找不到使用者", "u", uid);
    }

    public List<Map<String, Object>> skills(int uid) {
        return db.list("""
                SELECT us.skill_id "skillId", s.name, s.category, us.default_level "defaultLevel", us.level, us.source
                FROM user_skills us JOIN skills s ON s.id = us.skill_id WHERE us.user_id = :u ORDER BY s.category, us.level DESC, s.name""", "u", uid);
    }

    public List<Map<String, Object>> awards(int uid) {
        return db.list("""
                SELECT a.id, a.competition, a.level, a.rank, a.award_date "awardDate", am.score,
                       (SELECT string_agg(s.name, '、') FROM award_skills ak JOIN skills s ON s.id = ak.skill_id WHERE ak.award_id = a.id) skills
                FROM user_awards a JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level WHERE a.user_id = :u ORDER BY a.award_date DESC""", "u", uid);
    }

    /** 公開檔案：只有技能等級，沒有分數（D16） */
    public Map<String, Object> publicProfile(int uid) {
        var b = basic(uid);
        Map<String, Object> m = new LinkedHashMap<>();
        for (String k : List.of("id", "name", "degree", "year", "department", "college")) m.put(k, b.get(k));
        m.put("skills", skills(uid).stream().map(s -> Map.of("skillId", s.get("skillId"), "name", s.get("name"), "category", s.get("category"), "level", s.get("level"))).toList());
        m.put("awards", awards(uid));
        m.put("stats", stats.of(uid).toMap());
        m.put("availability", db.one("SELECT hours_per_week \"hoursPerWeek\", available_from \"availableFrom\", available_to \"availableTo\" FROM user_availability WHERE user_id = :u", "u", uid));
        return m;
    }

    // ---------- 成績 → 技能等級（D10、D14） ----------
    public record GradeIn(Integer courseId, Integer score, String semester) {}

    @Transactional
    public Map<String, Object> upsertGrades(int uid, List<GradeIn> grades) {
        for (GradeIn g : grades) {
            if (g.courseId() == null || g.score() == null || g.score() < 0 || g.score() > 100) throw ApiException.badRequest("課程與 0–100 分數為必填");
            db.exec("""
                    INSERT INTO user_grades (user_id, course_id, score, semester) VALUES (:u, :c, :s, :sem)
                    ON CONFLICT (user_id, course_id) DO UPDATE SET score = excluded.score, semester = excluded.semester""",
                    "u", uid, "c", g.courseId(), "s", g.score(), "sem", g.semester() == null ? "115-1" : g.semester());
        }
        recomputeDefaults(uid);
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteGrade(int uid, int gradeId) {
        db.exec("DELETE FROM user_grades WHERE id = :g AND user_id = :u", "g", gradeId, "u", uid);
        recomputeDefaults(uid);
        return me(uid);
    }

    /** 每個技能的預設等級 = 對應課程成績換算後的最高等級；學生調整過的等級保留 */
    void recomputeDefaults(int uid) {
        String degree = db.scalar(String.class, "SELECT degree FROM users WHERE id = :u", "u", uid);
        String group = "BACHELOR".equals(degree) ? "BACHELOR" : "GRADUATE";
        var rows = db.list("""
                SELECT m.skill_id, max(lv.level) lvl FROM user_grades g
                JOIN course_skill_map m ON m.course_id = g.course_id
                JOIN LATERAL (SELECT level FROM grade_conversion gc WHERE gc.degree_group = :grp AND gc.min_score <= g.score ORDER BY gc.min_score DESC LIMIT 1) lv ON true
                WHERE g.user_id = :u GROUP BY m.skill_id""", "grp", group, "u", uid);
        Set<Integer> seen = new HashSet<>();
        for (var r : rows) {
            int skillId = Db.i(r.get("skill_id")), newDefault = Db.i(r.get("lvl"));
            seen.add(skillId);
            var ex = db.one("SELECT default_level, level FROM user_skills WHERE user_id = :u AND skill_id = :s", "u", uid, "s", skillId);
            if (ex == null) {
                db.exec("INSERT INTO user_skills VALUES (:u, :s, :d, :d, 'GRADE')", "u", uid, "s", skillId, "d", newDefault);
                history(uid, skillId, null, newDefault, "GRADE");
            } else {
                Integer oldDefault = ex.get("default_level") == null ? null : Db.i(ex.get("default_level"));
                int oldLevel = Db.i(ex.get("level"));
                if (oldDefault != null && oldDefault == newDefault) continue;
                boolean adjusted = oldDefault != null && oldLevel != oldDefault;
                int newLevel = adjusted ? Math.max(oldLevel, newDefault) : newDefault;
                db.exec("UPDATE user_skills SET default_level = :d, level = :l, source = 'GRADE' WHERE user_id = :u AND skill_id = :s", "d", newDefault, "l", newLevel, "u", uid, "s", skillId);
                if (newLevel != oldLevel) history(uid, skillId, oldLevel, newLevel, "GRADE");
            }
        }
        // 成績被刪除後，不再有課程支撐的 GRADE 技能改為自填
        for (var r : db.list("SELECT skill_id FROM user_skills WHERE user_id = :u AND source = 'GRADE'", "u", uid)) {
            int skillId = Db.i(r.get("skill_id"));
            if (!seen.contains(skillId)) db.exec("UPDATE user_skills SET default_level = NULL, source = 'SELF' WHERE user_id = :u AND skill_id = :s", "u", uid, "s", skillId);
        }
    }

    private void history(int uid, int skillId, Integer old, int nw, String reason) {
        db.exec("INSERT INTO skill_level_history (user_id, skill_id, old_level, new_level, reason, changed_at) VALUES (:u, :s, :o, :n, :r, :t)",
                "u", uid, "s", skillId, "o", old, "n", nw, "r", reason, "t", Db.ts(clock.instant()));
    }

    // ---------- 技能自評（D7、D10） ----------
    public record SkillIn(Integer skillId, Integer level) {}

    @Transactional
    public Map<String, Object> upsertSkills(int uid, List<SkillIn> skills) {
        for (SkillIn s : skills) {
            if (s.skillId() == null || s.level() == null || s.level() < 1 || s.level() > 5) throw ApiException.badRequest("技能與 1–5 等級為必填");
            var ex = db.one("SELECT level FROM user_skills WHERE user_id = :u AND skill_id = :s", "u", uid, "s", s.skillId());
            if (ex == null) {
                db.exec("INSERT INTO user_skills VALUES (:u, :s, NULL, :l, 'SELF')", "u", uid, "s", s.skillId(), "l", s.level());
                history(uid, s.skillId(), null, s.level(), "SELF_DECLARE");
            } else if (Db.i(ex.get("level")) != s.level()) {
                db.exec("UPDATE user_skills SET level = :l WHERE user_id = :u AND skill_id = :s", "l", s.level(), "u", uid, "s", s.skillId());
                history(uid, s.skillId(), Db.i(ex.get("level")), s.level(), "SELF_ADJUST");
            }
        }
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteSkill(int uid, int skillId) {
        db.exec("DELETE FROM user_skills WHERE user_id = :u AND skill_id = :s", "u", uid, "s", skillId);
        return me(uid);
    }

    // ---------- 得獎（D8、D41） ----------
    public record AwardIn(String competition, String level, String rank, String awardDate, List<Integer> skillIds) {}

    @Transactional
    public Map<String, Object> addAward(int uid, AwardIn in) {
        if (blank(in.competition()) || !Set.of("CAMPUS", "NATIONAL", "INTERNATIONAL").contains(in.level()) || !Set.of("FIRST", "TOP3", "HONORABLE", "FINALIST").contains(in.rank()))
            throw ApiException.badRequest("競賽名稱、層級（CAMPUS／NATIONAL／INTERNATIONAL）、名次（FIRST／TOP3／HONORABLE／FINALIST）為必填");
        LocalDate date;
        try { date = LocalDate.parse(in.awardDate()); } catch (Exception e) { throw ApiException.badRequest("得獎日期格式須為 YYYY-MM-DD"); }
        int id = db.insertReturningId("INSERT INTO user_awards (user_id, competition, level, rank, award_date) VALUES (:u, :c, :l, :r, :d) RETURNING id",
                "u", uid, "c", in.competition().trim(), "l", in.level(), "r", in.rank(), "d", date);
        if (in.skillIds() != null) for (int s : in.skillIds()) db.exec("INSERT INTO award_skills VALUES (:a, :s) ON CONFLICT DO NOTHING", "a", id, "s", s);
        return me(uid);
    }

    @Transactional
    public Map<String, Object> deleteAward(int uid, int awardId) {
        db.exec("DELETE FROM user_awards WHERE id = :a AND user_id = :u", "a", awardId, "u", uid);
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
