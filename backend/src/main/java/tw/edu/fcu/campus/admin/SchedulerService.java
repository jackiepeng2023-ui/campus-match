package tw.edu.fcu.campus.admin;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.cases.CaseService;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.notify.NotificationService;
import tw.edu.fcu.campus.review.ReviewService;
import tw.edu.fcu.campus.user.UserService;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.IntSupplier;

/** 六個排程工作（D21、D24、D27–D29、D34、D40）；每分鐘執行，也可由 /admin/clock 立即觸發 */
@Service
public class SchedulerService {
    private static final Logger log = LoggerFactory.getLogger(SchedulerService.class);
    private final CaseService cases;
    private final ReviewService reviews;
    private final UserService users;
    private final NotificationService notify;
    private final Db db;
    private final DemoClock clock;

    public SchedulerService(CaseService cases, ReviewService reviews, UserService users, NotificationService notify, Db db, DemoClock clock) {
        this.cases = cases; this.reviews = reviews; this.users = users; this.notify = notify; this.db = db; this.clock = clock;
    }

    @Scheduled(fixedDelay = 60_000, initialDelay = 30_000)
    public void tick() { runAll(); }

    public synchronized Map<String, Object> runAll() {
        Map<String, Object> out = new LinkedHashMap<>();
        out.put("remind", safe("remind", cases::remindDue));
        out.put("expire", safe("expire", cases::expireDue));
        out.put("closeVoteTimeout", safe("closeVoteTimeout", reviews::closeVoteTimeout));
        out.put("autoClose", safe("autoClose", reviews::autoClose));
        out.put("reviewTimeout", safe("reviewTimeout", reviews::reviewTimeout));
        out.put("graduation", safe("graduation", this::graduationLifecycle));
        out.put("now", clock.instant().toString());
        return out;
    }

    private Object safe(String name, IntSupplier job) {
        try { return job.getAsInt(); } catch (Exception e) { log.error("排程 {} 失敗", name, e); return "error: " + e.getMessage(); }
    }

    /** 畢業前 30 天提醒確認；畢業後 3 個月去識別化；6 個月刪除（D27–D29） */
    int graduationLifecycle() {
        LocalDate today = LocalDate.now(clock);
        int n = 0;
        for (var u : db.list("SELECT id FROM users WHERE role = 'STUDENT' AND grad_reminded_at IS NULL AND deidentified_at IS NULL AND expected_graduation - 30 <= :t", "t", today)) {
            notify.notify(Db.i(u.get("id")), "GRADUATION", "請確認畢業狀態", "你的預計畢業日將屆，請確認：已畢業、延畢或升學。畢業 3 個月後資料將去識別化、6 個月後刪除。", "/profile");
            db.exec("UPDATE users SET grad_reminded_at = :t WHERE id = :id", "t", Db.ts(clock.instant()), "id", u.get("id"));
            n++;
        }
        int deid = param("deidentify_months", 3), purge = param("purge_months", 6);
        for (var u : db.list("SELECT id FROM users WHERE role = 'STUDENT' AND deidentified_at IS NULL AND expected_graduation + (cast(:m AS int) * interval '1 month') <= :t", "m", deid, "t", today)) {
            users.deidentify(Db.i(u.get("id"))); n++;
        }
        for (var u : db.list("SELECT id FROM users WHERE role = 'STUDENT' AND purged_at IS NULL AND expected_graduation + (cast(:m AS int) * interval '1 month') <= :t", "m", purge, "t", today)) {
            users.deidentify(Db.i(u.get("id"))); users.purge(Db.i(u.get("id"))); n++;
        }
        return n;
    }

    private int param(String k, int d) { Integer v = db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = :k", "k", k); return v == null ? d : v; }
}
