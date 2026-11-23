package tw.edu.fcu.campus.notify;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;

import java.util.List;
import java.util.Map;

/**
 * 通知一律先寫入 notifications（網頁讀取）。APNs 推播（iOS）與 WebSocket 推送都等資料庫交易提交後才送：
 * 不會推送還沒提交的資料，也不會在鎖定期間做網路呼叫（《軟體工程架構 3.1》第 6.4 節規則 4）。
 */
@Service
public class NotificationService {
    private final Db db;
    private final DemoClock clock;
    private final ApnsSender apns;
    private final ApplicationEventPublisher events;

    public NotificationService(Db db, DemoClock clock, ApnsSender apns, ApplicationEventPublisher events) {
        this.db = db; this.clock = clock; this.apns = apns; this.events = events;
    }

    /** 已寫入一則站內通知；提交後由 {@link #deliver} 送 APNs，推送閘道送 WebSocket */
    public record Notified(int userId, String type, String title, String body, String link) {}

    public void notify(int userId, String type, String title, String body, String link) {
        db.exec("INSERT INTO notifications (user_id, type, title, body, link, created_at) VALUES (:u, :t, :ti, :b, :l, :c)",
                "u", userId, "t", type, "ti", title, "b", body == null ? "" : body, "l", link, "c", Db.ts(clock.instant()));
        events.publishEvent(new Notified(userId, type, title, body == null ? "" : body, link));
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void deliver(Notified n) { pushOnly(n.userId(), n.title(), n.body(), n.link()); }

    /** 只送 APNs，不寫站內通知（新訊息用：未讀數已經在對話列表上） */
    public void pushOnly(int userId, String title, String body, String link) {
        if (!apns.configured()) return;
        for (var row : db.list("SELECT token FROM device_tokens WHERE user_id = :u", "u", userId))
            apns.send((String) row.get("token"), title, body, link);
    }

    public int unread(int userId) { return db.count("SELECT count(*) FROM notifications WHERE user_id = :u AND read_at IS NULL", "u", userId); }

    public void notifyAll(List<Integer> userIds, String type, String title, String body, String link) {
        for (int u : userIds) notify(u, type, title, body, link);
    }

    public Map<String, Object> list(int userId) {
        return Map.of(
                "unread", db.count("SELECT count(*) FROM notifications WHERE user_id = :u AND read_at IS NULL", "u", userId),
                "items", db.list("""
                        SELECT id, type, title, body, link, created_at "createdAt", read_at "readAt"
                        FROM notifications WHERE user_id = :u ORDER BY created_at DESC LIMIT 50""", "u", userId));
    }

    public void readAll(int userId) {
        db.exec("UPDATE notifications SET read_at = :n WHERE user_id = :u AND read_at IS NULL", "n", Db.ts(clock.instant()), "u", userId);
    }

    public void registerDevice(int userId, String token) {
        db.exec("INSERT INTO device_tokens (user_id, token) VALUES (:u, :t) ON CONFLICT DO NOTHING", "u", userId, "t", token);
    }

    public void log(Integer actorId, String entity, Integer entityId, String action, String payloadJson) {
        db.exec("INSERT INTO event_logs (actor_id, entity, entity_id, action, payload, created_at) VALUES (:a, :e, :i, :ac, cast(:p AS jsonb), :c)",
                "a", actorId, "e", entity, "i", entityId, "ac", action, "p", payloadJson == null ? "{}" : payloadJson, "c", Db.ts(clock.instant()));
    }
}
