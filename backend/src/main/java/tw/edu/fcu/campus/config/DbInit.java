package tw.edu.fcu.campus.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import tw.edu.fcu.campus.common.Db;

import java.nio.charset.StandardCharsets;

/** Demo 模式：啟動時重建 schema 與種子資料，並將所有示範帳號密碼設為 demo 密碼 */
@Component
public class DbInit implements ApplicationRunner {
    private static final Logger log = LoggerFactory.getLogger(DbInit.class);
    private final Db db;
    private final PasswordEncoder encoder;
    private final boolean resetOnStart;
    private final String demoPassword;

    public DbInit(Db db, PasswordEncoder encoder, @Value("${app.reset-on-start}") boolean resetOnStart,
                  @Value("${app.demo-password}") String demoPassword) {
        this.db = db; this.encoder = encoder; this.resetOnStart = resetOnStart; this.demoPassword = demoPassword;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        if (resetOnStart) reload();
        else log.info("reset-on-start=false，沿用現有資料");
    }

    public void reload() throws Exception {
        log.info("重建 schema 與種子資料…");
        db.jdbc.getJdbcOperations().execute(read("db/schema.sql"));
        db.jdbc.getJdbcOperations().execute(read("db/data.sql"));
        int n = db.exec("UPDATE users SET password_hash = :h WHERE password_hash = '{RESET_ON_BOOT}'", "h", encoder.encode(demoPassword));
        log.info("完成：{} 位示範帳號密碼為 {}", n, demoPassword);
    }

    private static String read(String path) throws Exception {
        return new String(new ClassPathResource(path).getInputStream().readAllBytes(), StandardCharsets.UTF_8);
    }
}
