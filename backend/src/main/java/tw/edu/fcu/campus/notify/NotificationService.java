package tw.edu.fcu.campus.notify;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;

import java.util.List;
import java.util.Map;

/** 通知一律先寫入 notifications（網頁讀取），再嘗試 APNs 推播（iOS） */
@Service
public class NotificationService {
    private final Db db;
    private final DemoClock clock;
    private final ApnsSender apns;

    public NotificationService(Db db, DemoClock clock, ApnsSender apns) { this.db = db; this.clock = clock; this.apns = apns; }

    public void notify(int userId, String type, String title, String body, String link) {
        db.exec("INSERT INTO notifications (user_id, type, title, body, link, created_at) VALUES (:u, :t, :ti, :b, :l, :c)",
                "u", userId, "t", type, "ti", title, "b", body == null ? "" : body, "l", link, "c", Db.ts(clock.instant()));
        for (var row : db.list("SELECT token FROM device_tokens WHERE user_id = :u", "u", userId))
            apns.send((String) row.get("token"), title, body, link);
    }

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
