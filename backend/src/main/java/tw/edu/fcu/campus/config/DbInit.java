package tw.edu.fcu.campus.config;

import org.flywaydb.core.Flyway;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.profile.SkillProfileService;

import javax.sql.DataSource;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;

/**
 * 資料初始化。以 InitializingBean 執行，確保在 Tomcat 開放連線之前完成（避免啟動瞬間登入失敗）。
 * <ul>
 *   <li>seed-mode=demo：schema → 50 位示範學生與劇本資料（data.sql）→ 學校參考資料；示範帳號密碼設為 demo 密碼。</li>
 *   <li>seed-mode=reference（正式上線）：schema → 學校參考資料（技能表、各系所各入學年度科目表、科目→技能規則）；不載入任何假學生。</li>
 *   <li>reset-on-start=false：沿用現有資料，只在資料表尚不存在時初始化；每次啟動仍會補齊參考資料（ON CONFLICT DO NOTHING，可安全重複）。</li>
 *   <li>APP_ADMIN_EMAIL／APP_ADMIN_PASSWORD：啟動時若此帳號不存在則建立管理員。</li>
 * </ul>
 * 3.1 起，資料表的變更改用版本化的遷移腳本（db/migration，Flyway）：schema.sql 是 2.0 的基準版，
 * 之後每次變更一支腳本；已有資料的資料庫啟動時只執行還沒跑過的腳本。
 * 正式模式（reference）另有啟動檢查，避免設定錯誤時重建到有資料的資料庫（見 {@link #guard()}）。
 */
@Component
public class DbInit implements InitializingBean {
    private static final Logger log = LoggerFactory.getLogger(DbInit.class);
    private static final String[] REFERENCE = {"db/ref-base.sql", "db/ref-courses.sql", "db/ref-skill-map.sql", "db/ref-competitions.sql", "db/ref-teachers.sql", "db/ref-syllabus.sql"};
    /** application.yml 內建的 Demo 用 JWT 密鑰；正式模式不允許使用 */
    static final String DEMO_JWT_SECRET = "campus-match-demo-secret-key-change-me-in-production-2026";

    private final Db db;
    private final DataSource dataSource;
    private final PasswordEncoder encoder;
    private final SkillProfileService profile;
    private final boolean resetOnStart, demoClock, allowDestructiveReset;
    private final String seedMode, demoPassword, adminEmail, adminPassword, adminName, jwtSecret;

    public DbInit(Db db, DataSource dataSource, PasswordEncoder encoder, SkillProfileService profile,
                  @Value("${app.reset-on-start}") boolean resetOnStart, @Value("${app.seed-mode}") String seedMode,
                  @Value("${app.demo-password}") String demoPassword, @Value("${app.admin-email}") String adminEmail,
                  @Value("${app.admin-password}") String adminPassword, @Value("${app.admin-name}") String adminName,
                  @Value("${app.demo-clock}") boolean demoClock, @Value("${app.jwt-secret}") String jwtSecret,
                  @Value("${app.allow-destructive-reset}") boolean allowDestructiveReset) {
        this.db = db; this.dataSource = dataSource; this.encoder = encoder; this.profile = profile; this.resetOnStart = resetOnStart; this.seedMode = seedMode; this.demoPassword = demoPassword;
        this.adminEmail = adminEmail; this.adminPassword = adminPassword; this.adminName = adminName;
        this.demoClock = demoClock; this.jwtSecret = jwtSecret; this.allowDestructiveReset = allowDestructiveReset;
    }

    public volatile boolean ready = false;

    public boolean isDemo() { return "demo".equalsIgnoreCase(seedMode); }

    @Override
    public void afterPropertiesSet() throws Exception {
        guard();
        if (resetOnStart) reload();
        else if (!tablesExist()) { log.info("資料表不存在，首次初始化（{} 模式）", seedMode); reload(); }
        else { log.info("reset-on-start=false，沿用現有資料；補齊參考資料並執行尚未套用的遷移"); loadReference(); migrate(); }
        ensureAdmin();
        ready = true;
    }

    /**
     * 正式模式的啟動檢查：三個開關的預設值都是 Demo 那一組，正式環境少設一個就可能清掉資料或讓人偽造登入憑證。
     * 任何一項不符合就拒絕啟動，並說明要改哪個設定。
     */
    void guard() {
        if (isDemo()) return;
        if (DEMO_JWT_SECRET.equals(jwtSecret))
            throw new IllegalStateException("正式模式（APP_SEED_MODE=reference）不能使用內建的 JWT 密鑰：請把 APP_JWT_SECRET 設成 32 字元以上的亂數。");
        if (demoClock)
            throw new IllegalStateException("正式模式（APP_SEED_MODE=reference）不能開啟 Demo 時鐘與重置：請設定 APP_DEMO_CLOCK=false。");
        if (resetOnStart && tablesExist() && !allowDestructiveReset
                && db.count("SELECT count(*) FROM users WHERE role = 'STUDENT'") > 0)
            throw new IllegalStateException("正式模式下資料庫已有學生帳號，拒絕重建（APP_RESET_ON_START=true 會刪除全部資料）：請設定 APP_RESET_ON_START=false；"
                    + "若這是可以丟棄的測試資料庫，另外設定 APP_ALLOW_DESTRUCTIVE_RESET=true。");
    }

    public boolean isReference() { return !isDemo(); }

    /** 重建 schema 與資料（Demo 彩排之間亦由 /admin/reset 呼叫） */
    public void reload() throws Exception {
        ready = false;                                                    // 重建期間排程先停（資料表會暫時回到 2.0 的樣子）
        log.info("重建 schema（seed-mode={}）…", seedMode);
        db.jdbc.getJdbcOperations().execute(read("db/reset-3.sql"));     // 3.x 遷移新增的資料表與遷移紀錄：先刪，才能回到 2.0 基準版
        db.jdbc.getJdbcOperations().execute(read("db/schema.sql"));
        if (isDemo()) {
            db.jdbc.getJdbcOperations().execute(read("db/data.sql"));
            int n = db.exec("UPDATE users SET password_hash = :h WHERE password_hash = '{RESET_ON_BOOT}'", "h", encoder.encode(demoPassword));
            log.info("Demo 資料載入完成：{} 位示範帳號，密碼取自 APP_DEMO_PASSWORD", n);
        }
        loadReference();
        if (isDemo()) {
            // 示範資料只放原始證據（成績、證照、作品集、得獎、結案與互評）；Skill Profile 由能力盤點模組依同一套規則算出
            db.jdbc.getJdbcOperations().execute(read("db/data-post.sql"));
            long t = System.currentTimeMillis();
            log.info("能力盤點完成：{} 位學生、{} 筆證據、{} 項技能，{} ms", profile.rebuildAllWithHistory(),
                    db.count("SELECT count(*) FROM skill_evidence"), db.count("SELECT count(*) FROM user_skills"), System.currentTimeMillis() - t);
        }
        migrate();
        if (isDemo()) {
            // 3.1 的示範資料：比賽隊伍（對應到競賽清單）、隊伍群組的訊息、一筆等待回覆的邀請；要在遷移之後才有這些資料表與欄位
            db.jdbc.getJdbcOperations().execute(read("db/data-3.1.sql"));
            log.info("3.1 示範資料：{} 支比賽隊伍招募中", db.count("SELECT count(*) FROM cases WHERE status = 'OPEN' AND competition_id IS NOT NULL"));
        }
        ensureAdmin();
        ready = true;
    }

    /** 執行尚未套用的遷移腳本。沒有遷移紀錄的既有資料庫視為 2.0 基準版（schema.sql）。 */
    private void migrate() {
        var result = Flyway.configure().dataSource(dataSource).locations("classpath:db/migration")
                .baselineOnMigrate(true).baselineVersion("2.0").baselineDescription("CampusMatch 2.0 schema.sql")
                .load().migrate();
        log.info("資料庫遷移：本次套用 {} 支，目前版本 {}", result.migrationsExecuted, result.targetSchemaVersion == null ? "2.0" : result.targetSchemaVersion);
    }

    /** 學校參考資料：全部 ON CONFLICT DO NOTHING，重複執行不會覆蓋管理員事後的修改 */
    private void loadReference() throws Exception {
        long t = System.currentTimeMillis();
        for (String f : REFERENCE) db.jdbc.getJdbcOperations().execute(read(f));
        log.info("競賽 {} 筆、教師 {} 位、證照對照 {} 筆", db.count("SELECT count(*) FROM competitions"), db.count("SELECT count(*) FROM teachers"), db.count("SELECT count(*) FROM certificate_catalog"));
        log.info("參考資料完成：{} 系所、{} 科目（{} 入學年度）、{} 筆科目→技能對照，{} ms",
                db.count("SELECT count(*) FROM departments"), db.count("SELECT count(*) FROM courses WHERE entry_year IS NOT NULL"),
                db.scalar(String.class, "SELECT string_agg(y::text, '、' ORDER BY y) FROM (SELECT DISTINCT entry_year y FROM courses WHERE entry_year IS NOT NULL) s"),
                db.count("SELECT count(*) FROM course_skill_map"), System.currentTimeMillis() - t);
    }

    private void ensureAdmin() {
        if (adminEmail == null || adminEmail.isBlank() || adminPassword == null || adminPassword.isBlank()) return;
        if (db.count("SELECT count(*) FROM users WHERE email = :e", "e", adminEmail.trim().toLowerCase()) > 0) return;
        Integer dept = db.scalar(Integer.class, "SELECT id FROM departments ORDER BY id LIMIT 1");
        if (dept == null) return;
        db.exec("""
                INSERT INTO users (student_no, name, email, password_hash, degree, year, department_id, expected_graduation, role)
                VALUES ('ADMIN', :n, :e, :p, 'BACHELOR', 1, :d, :g, 'ADMIN')""",
                "n", adminName, "e", adminEmail.trim().toLowerCase(), "p", encoder.encode(adminPassword), "d", dept, "g", LocalDate.now().plusYears(10));
        log.info("已建立管理員帳號 {}", adminEmail);
    }

    private boolean tablesExist() {
        return db.count("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'courses'") > 0;
    }

    private static String read(String path) throws Exception {
        return new String(new ClassPathResource(path).getInputStream().readAllBytes(), StandardCharsets.UTF_8);
    }
}
