package tw.edu.fcu.campus.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.config.JwtService;
import tw.edu.fcu.campus.notify.NotificationService;

import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * 推送閘道：管理 WebSocket 連線，資料庫交易提交之後把事件送給在線上的人（《軟體工程架構 3.1》第 9 節）。
 * 用戶端只送兩種訊息：auth（連線後第一則，帶登入憑證；憑證不放網址，網址會進存取紀錄）與 ping。
 * 其餘都是伺服器推送。寫入一律走 REST，所以推送失敗不影響資料：用戶端重連後用訊息編號補漏。
 * 連線表放在記憶體，只適用單一執行個體；要開第二台時改用外部的訊息通道（架構文件 AD-08）。
 */
@Component
public class PushGateway extends TextWebSocketHandler {
    private static final Logger log = LoggerFactory.getLogger(PushGateway.class);
    static final CloseStatus UNAUTHORIZED = new CloseStatus(4401, "unauthorized");
    static final CloseStatus TOO_MANY = new CloseStatus(4409, "too many connections");
    private static final int MAX_PER_USER = 5;
    private static final int AUTH_SECONDS = 5;
    private static final String UID = "uid";

    private final JwtService jwt;
    private final ObjectMapper json;
    private final NotificationService notify;
    /** 連線編號 → 可以同時被多個執行緒寫入的連線 */
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    /** 使用者編號 → 他已通過驗證的連線，依建立先後（一個人可以開好幾個分頁） */
    private final Map<Integer, List<WebSocketSession>> byUser = new ConcurrentHashMap<>();
    private final ScheduledExecutorService timer = Executors.newSingleThreadScheduledExecutor(r -> {
        Thread t = new Thread(r, "ws-auth-timer"); t.setDaemon(true); return t;
    });

    public PushGateway(JwtService jwt, ObjectMapper json, NotificationService notify) { this.jwt = jwt; this.json = json; this.notify = notify; }

    @PreDestroy void stop() { timer.shutdownNow(); }

    // ---------- 連線 ----------
    @Override
    public void afterConnectionEstablished(WebSocketSession raw) {
        WebSocketSession s = new ConcurrentWebSocketSessionDecorator(raw, 5_000, 256 * 1024);
        sessions.put(raw.getId(), s);
        timer.schedule(() -> { if (s.isOpen() && !s.getAttributes().containsKey(UID)) close(s, UNAUTHORIZED); }, AUTH_SECONDS, TimeUnit.SECONDS);
    }

    @Override
    protected void handleTextMessage(WebSocketSession raw, TextMessage message) {
        WebSocketSession s = sessions.get(raw.getId());
        if (s == null) return;
        String type; JsonNode node;
        try { node = json.readTree(message.getPayload()); type = node.path("type").asText(""); }
        catch (Exception e) { write(s, Map.of("type", "error", "code", "BAD_FRAME", "message", "訊息格式錯誤")); return; }
        switch (type) {
            case "auth" -> {
                if (s.getAttributes().containsKey(UID)) return;
                Current.Principal p;
                try { p = jwt.parse(node.path("token").asText("")); }
                catch (Exception e) { write(s, Map.of("type", "error", "code", "UNAUTHORIZED", "message", "登入已失效，請重新登入")); close(s, UNAUTHORIZED); return; }
                s.getAttributes().put(UID, p.id());
                // 登記與移除都在同一個鍵的 compute 裡做，兩邊同時發生也不會把連線加進已經被丟掉的清單
                List<WebSocketSession> mine = byUser.compute(p.id(), (k, list) -> {
                    if (list == null) list = new CopyOnWriteArrayList<>();
                    list.add(s);
                    return list;
                });
                // 同一個人的連線太多時，關掉最舊的（忘記關的分頁）
                while (mine.size() > MAX_PER_USER) {
                    WebSocketSession oldest = mine.get(0);
                    if (oldest == s) break;
                    close(oldest, TOO_MANY);
                }
                write(s, Map.of("type", "ready", "userId", p.id()));
            }
            case "ping" -> { if (s.getAttributes().containsKey(UID)) write(s, Map.of("type", "pong")); }
            default -> write(s, Map.of("type", "error", "code", "UNKNOWN_TYPE", "message", "不支援的訊息種類"));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession raw, CloseStatus status) { forget(raw.getId()); }

    @Override
    public void handleTransportError(WebSocketSession raw, Throwable error) { forget(raw.getId()); }

    private void forget(String sessionId) {
        WebSocketSession s = sessions.remove(sessionId);
        if (s == null) return;
        Object uid = s.getAttributes().get(UID);
        if (uid instanceof Integer u) byUser.computeIfPresent(u, (k, list) -> { list.remove(s); return list.isEmpty() ? null : list; });
    }

    private void close(WebSocketSession s, CloseStatus status) {
        try { s.close(status); } catch (Exception ignored) { /* 已經斷了 */ }
        forget(s.getId());
    }

    private void write(WebSocketSession s, Object payload) {
        try { s.sendMessage(new TextMessage(json.writeValueAsString(payload))); }
        catch (Exception e) { log.debug("WebSocket 送出失敗，關閉連線：{}", e.toString()); close(s, CloseStatus.SERVER_ERROR); }
    }

    // ---------- 推送 ----------
    public boolean online(int userId) { return byUser.containsKey(userId); }

    public int connections() { return sessions.size(); }

    public void send(Collection<Integer> userIds, Object payload) {
        String text = null;
        for (int u : new LinkedHashSet<>(userIds)) {
            List<WebSocketSession> mine = byUser.get(u);
            if (mine == null) continue;
            if (text == null) {
                try { text = json.writeValueAsString(payload); } catch (Exception e) { log.warn("推送內容無法序列化：{}", e.toString()); return; }
            }
            TextMessage frame = new TextMessage(text);
            for (WebSocketSession s : mine) {
                try { s.sendMessage(frame); } catch (Exception e) { log.debug("WebSocket 送出失敗，關閉連線：{}", e.toString()); close(s, CloseStatus.SERVER_ERROR); }
            }
        }
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(ChatEvents.Push e) { send(e.userIds(), e.payload()); }

    /** 新訊息：在線上的成員用 WebSocket；不在線上的改送 APNs，只寫「你有新訊息」，內文不經過 Apple */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(ChatEvents.MessagePosted e) {
        send(e.recipientIds(), e.payload());
        for (int u : e.recipientIds())
            if ((e.senderId() == null || u != e.senderId()) && !online(u)) notify.pushOnly(u, "Fomo鬆", "你有新訊息", "/messages/" + e.conversationId());
    }

    /** 站內通知：小鈴鐺即時更新 */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void on(NotificationService.Notified n) {
        if (!online(n.userId())) return;
        send(Set.of(n.userId()), ChatService.mapOf("type", "notification.new", "unread", notify.unread(n.userId()),
                "notification", ChatService.mapOf("type", n.type(), "title", n.title(), "body", n.body(), "link", n.link())));
    }
}
