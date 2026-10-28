package tw.edu.fcu.campus.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import tw.edu.fcu.campus.common.Db;

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
 */
@Component
public class DbInit implements InitializingBean {
    private static final Logger log = LoggerFactory.getLogger(DbInit.class);
    private static final String[] REFERENCE = {"db/ref-base.sql", "db/ref-courses.sql", "db/ref-skill-map.sql"};
    private final Db db;
    private final PasswordEncoder encoder;
    private final boolean resetOnStart;
    private final String seedMode, demoPassword, adminEmail, adminPassword, adminName;

    public DbInit(Db db, PasswordEncoder encoder, @Value("${app.reset-on-start}") boolean resetOnStart, @Value("${app.seed-mode}") String seedMode,
                  @Value("${app.demo-password}") String demoPassword, @Value("${app.admin-email}") String adminEmail,
                  @Value("${app.admin-password}") String adminPassword, @Value("${app.admin-name}") String adminName) {
        this.db = db; this.encoder = encoder; this.resetOnStart = resetOnStart; this.seedMode = seedMode; this.demoPassword = demoPassword;
        this.adminEmail = adminEmail; this.adminPassword = adminPassword; this.adminName = adminName;
    }

    public volatile boolean ready = false;

    public boolean isDemo() { return "demo".equalsIgnoreCase(seedMode); }

    @Override
    public void afterPropertiesSet() throws Exception {
        if (resetOnStart) reload();
        else if (!tablesExist()) { log.info("資料表不存在，首次初始化（{} 模式）", seedMode); reload(); }
        else { log.info("reset-on-start=false，沿用現有資料；補齊參考資料"); loadReference(); }
        ensureAdmin();
        ready = true;
    }

    /** 重建 schema 與資料（Demo 彩排之間亦由 /admin/reset 呼叫） */
    public void reload() throws Exception {
        log.info("重建 schema（seed-mode={}）…", seedMode);
        db.jdbc.getJdbcOperations().execute(read("db/schema.sql"));
        if (isDemo()) {
            db.jdbc.getJdbcOperations().execute(read("db/data.sql"));
            int n = db.exec("UPDATE users SET password_hash = :h WHERE password_hash = '{RESET_ON_BOOT}'", "h", encoder.encode(demoPassword));
            log.info("Demo 資料載入完成：{} 位示範帳號密碼為 {}", n, demoPassword);
        }
        loadReference();
        ensureAdmin();
    }

    /** 學校參考資料：全部 ON CONFLICT DO NOTHING，重複執行不會覆蓋管理員事後的修改 */
    private void loadReference() throws Exception {
        long t = System.currentTimeMillis();
        for (String f : REFERENCE) db.jdbc.getJdbcOperations().execute(read(f));
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
