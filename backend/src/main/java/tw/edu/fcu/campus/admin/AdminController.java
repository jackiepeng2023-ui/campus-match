package tw.edu.fcu.campus.admin;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DbInit;
import tw.edu.fcu.campus.config.DemoClock;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;

/** M6 管理：權重、係數、參數、Demo 時鐘、重置資料 */
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    private final Db db;
    private final DemoClock clock;
    private final SchedulerService scheduler;
    private final DbInit dbInit;
    private final boolean demoClock;

    public AdminController(Db db, DemoClock clock, SchedulerService scheduler, DbInit dbInit, @Value("${app.demo-clock}") boolean demoClock) {
        this.db = db; this.clock = clock; this.scheduler = scheduler; this.dbInit = dbInit; this.demoClock = demoClock;
    }

    @GetMapping("/params")
    public Map<String, Object> params() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("weights", db.list("SELECT key, value, label FROM ranking_weights ORDER BY CASE key WHEN 'S' THEN 1 WHEN 'T' THEN 2 WHEN 'R' THEN 3 WHEN 'P' THEN 4 ELSE 5 END"));
        m.put("credibility", db.list("SELECT match_level \"matchLevel\", coefficient FROM credibility_coefficients ORDER BY match_level DESC"));
        m.put("awardMatrix", db.list("SELECT rank, level, score FROM award_matrix ORDER BY CASE rank WHEN 'FIRST' THEN 1 WHEN 'TOP3' THEN 2 WHEN 'HONORABLE' THEN 3 ELSE 4 END, CASE level WHEN 'CAMPUS' THEN 1 WHEN 'NATIONAL' THEN 2 ELSE 3 END"));
        m.put("params", db.list("SELECT key, value, label FROM system_params ORDER BY key"));
        return m;
    }

    public record ParamsIn(Map<String, Double> weights, Map<String, Double> credibility, Map<String, Integer> params, Map<String, Double> awardMatrix) {}

    @PutMapping("/params")
    public Map<String, Object> update(@RequestBody ParamsIn in) {
        if (in.weights() != null) {
            double sum = in.weights().values().stream().mapToDouble(Double::doubleValue).sum();
            if (Math.abs(sum - 1.0) > 0.001) throw ApiException.badRequest("權重總和必須為 1.0（目前 " + sum + "）");
            for (var e : in.weights().entrySet()) db.exec("UPDATE ranking_weights SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
        }
        if (in.credibility() != null) for (var e : in.credibility().entrySet()) db.exec("UPDATE credibility_coefficients SET coefficient = :v WHERE match_level = :k", "v", e.getValue(), "k", Integer.parseInt(e.getKey()));
        if (in.params() != null) for (var e : in.params().entrySet()) db.exec("UPDATE system_params SET value = :v WHERE key = :k", "v", e.getValue(), "k", e.getKey());
        if (in.awardMatrix() != null) for (var e : in.awardMatrix().entrySet()) {
            String[] rl = e.getKey().split("/");
            db.exec("UPDATE award_matrix SET score = :v WHERE rank = :r AND level = :l", "v", e.getValue(), "r", rl[0], "l", rl[1]);
        }
        return params();
    }

    @GetMapping("/clock")
    public Map<String, Object> clock() { return Map.of("now", clock.instant().toString(), "offsetHours", clock.offset().toHours(), "enabled", demoClock); }

    public record ClockIn(Integer hours) {}

    /** Demo：時間快轉並立即執行所有排程，現場展示逾時、提醒、自動結案 */
    @PostMapping("/clock")
    public Map<String, Object> advance(@RequestBody ClockIn in) {
        if (!demoClock) throw ApiException.forbidden("正式環境不允許調整時鐘");
        if (in.hours() == null || in.hours() < 0 || in.hours() > 24 * 365) throw ApiException.badRequest("hours 須介於 0–8760");
        clock.advance(Duration.ofHours(in.hours()));
        Map<String, Object> m = new LinkedHashMap<>(scheduler.runAll());
        m.put("offsetHours", clock.offset().toHours());
        return m;
    }

    @PostMapping("/clock/reset")
    public Map<String, Object> resetClock() { clock.reset(); return clock(); }

    @PostMapping("/run-jobs")
    public Map<String, Object> runJobs() { return scheduler.runAll(); }

    /** 重建 schema 與種子資料（彩排之間使用） */
    @PostMapping("/reset")
    public Map<String, Object> reset() throws Exception {
        if (!demoClock) throw ApiException.forbidden("正式環境不允許重置");
        clock.reset();
        dbInit.reload();
        return Map.of("ok", true, "now", clock.instant().toString());
    }

    @GetMapping("/event-logs")
    public Object logs(@RequestParam(defaultValue = "100") int limit) {
        return db.list("SELECT l.id, l.actor_id \"actorId\", u.name actor, l.entity, l.entity_id \"entityId\", l.action, l.payload::text payload, l.created_at \"createdAt\" FROM event_logs l LEFT JOIN users u ON u.id = l.actor_id ORDER BY l.id DESC LIMIT :n", "n", Math.min(limit, 500));
    }
}
