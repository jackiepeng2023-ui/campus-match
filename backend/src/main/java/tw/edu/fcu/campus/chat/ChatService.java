package tw.edu.fcu.campus.chat;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;

import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 對話、成員、訊息的讀寫（《軟體工程架構 3.1》第 9 節）。
 * 對話只有兩種，都掛在流程上（D70）：TALK 洽談（一筆申請或邀請一個，申請人或被邀請人與隊長）、TEAM 隊伍群組（一支隊伍一個）。
 * 沒有任意私訊：對話一律由隊伍流程的事件建立（{@link ChatEventHandler}），使用者不能自己開對話。
 *
 * 規則：
 * 1. 讀寫前檢查是對話成員而且還沒離開；不是成員一律回「找不到對話」，不透露對話是否存在。
 * 2. 新成員只看得到加入之後的訊息（since_message_id），看不到加入前隊伍內部的討論。
 * 3. 寫入前先鎖住對話列：同一個對話的寫入排隊，訊息編號的順序就等於提交順序，用編號補漏才不會漏。
 * 4. 訊息內容不送給任何 AI 功能；這個模組沒有呼叫 llm、assistant、agent。
 */
@Service
public class ChatService {
    static final int MAX_BODY = 2000;

    private final Db db;
    private final DemoClock clock;
    private final ApplicationEventPublisher events;

    public ChatService(Db db, DemoClock clock, ApplicationEventPublisher events) { this.db = db; this.clock = clock; this.events = events; }

    static Map<String, Object> mapOf(Object... kv) {
        Map<String, Object> m = new LinkedHashMap<>();
        for (int i = 0; i < kv.length; i += 2) m.put((String) kv[i], kv[i + 1]);
        return m;
    }

    // ---------- 對話列表與單一對話 ----------
    private List<Map<String, Object>> rows(int uid, Integer only) {
        return db.list("""
                SELECT v.id, v.kind, v.case_id, v.engagement_id, v.read_only, v.last_message_id, v.last_message_at,
                       c.title team_title, c.status team_status, c.owner_id,
                       cp.id comp_id, coalesce(nullif(cp.short_name, ''), cp.name) comp_name, cp.apply_deadline comp_deadline,
                       cm.last_read_message_id,
                       lm.kind last_kind, lm.body last_body, lm.sender_id last_sender, lu.name last_sender_name, lm.created_at last_at, lm.deleted_at last_deleted,
                       (SELECT count(*) FROM messages m WHERE m.conversation_id = v.id AND m.id > greatest(cm.last_read_message_id, cm.since_message_id)
                             AND (m.sender_id IS NULL OR m.sender_id <> :u)) unread,
                       (SELECT count(*) FROM conversation_members x WHERE x.conversation_id = v.id AND x.left_at IS NULL) member_count,
                       e.direction, e.status eng_status, e.due_at, e.user_id joiner_id, e.case_role_id
                FROM conversation_members cm
                JOIN conversations v ON v.id = cm.conversation_id
                JOIN cases c ON c.id = v.case_id
                LEFT JOIN competitions cp ON cp.id = c.competition_id
                LEFT JOIN messages lm ON lm.id = v.last_message_id AND lm.id > cm.since_message_id
                LEFT JOIN users lu ON lu.id = lm.sender_id
                LEFT JOIN engagements e ON e.id = v.engagement_id
                WHERE cm.user_id = :u AND cm.left_at IS NULL AND (cast(:only AS int) IS NULL OR v.id = :only)
                ORDER BY v.last_message_at DESC NULLS LAST, v.id DESC""", "u", uid, "only", only);
    }

    private List<Map<String, Object>> items(int uid, Integer only) {
        List<Map<String, Object>> rows = rows(uid, only);
        // 洽談對話的對方：一次取回
        Set<Integer> peerIds = new HashSet<>();
        for (var r : rows) if ("TALK".equals(r.get("kind"))) peerIds.add(peerOf(r, uid));
        Map<Integer, Map<String, Object>> people = new HashMap<>();
        if (!peerIds.isEmpty())
            for (var p : db.list("""
                    SELECT u.id, u.name, d.name department, col.name college, u.degree, u.year
                    FROM users u JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id WHERE u.id IN (:ids)""",
                    "ids", new ArrayList<>(peerIds))) people.put(Db.i(p.get("id")), p);

        LocalDate today = LocalDate.now(clock);
        List<Map<String, Object>> out = new ArrayList<>();
        for (var r : rows) {
            int owner = Db.i(r.get("owner_id"));
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.get("id")); m.put("kind", r.get("kind")); m.put("readOnly", r.get("read_only"));
            m.put("unread", r.get("unread")); m.put("lastReadMessageId", r.get("last_read_message_id")); m.put("lastMessageAt", r.get("last_message_at"));
            m.put("lastMessage", r.get("last_kind") == null ? null : mapOf(
                    "id", r.get("last_message_id"), "kind", r.get("last_kind"), "body", r.get("last_deleted") != null ? "" : preview((String) r.get("last_body")),
                    "deleted", r.get("last_deleted") != null, "senderId", r.get("last_sender"), "senderName", r.get("last_sender_name"), "createdAt", r.get("last_at")));
            m.put("team", mapOf("id", r.get("case_id"), "title", r.get("team_title"), "status", r.get("team_status")));
            LocalDate deadline = r.get("comp_deadline") == null ? null : ((java.sql.Date) r.get("comp_deadline")).toLocalDate();
            m.put("competition", r.get("comp_id") == null ? null : mapOf("id", r.get("comp_id"), "name", r.get("comp_name"), "applyDeadline", deadline,
                    "daysLeft", deadline == null ? null : (int) ChronoUnit.DAYS.between(today, deadline)));
            m.put("isOwner", owner == uid);
            if ("TEAM".equals(r.get("kind"))) m.put("memberCount", r.get("member_count"));
            else {
                m.put("peer", people.get(peerOf(r, uid)));
                boolean invite = "INVITE".equals(r.get("direction"));
                boolean responder = invite ? Db.i(r.get("joiner_id")) == uid : owner == uid;
                m.put("engagement", mapOf("id", r.get("engagement_id"), "direction", r.get("direction"), "status", r.get("eng_status"),
                        "dueAt", r.get("due_at"), "roleId", r.get("case_role_id"), "role", responder ? "RESPONDER" : "INITIATOR"));
            }
            out.add(m);
        }
        return out;
    }

    private static int peerOf(Map<String, Object> r, int uid) {
        int owner = Db.i(r.get("owner_id")), joiner = Db.i(r.get("joiner_id"));
        return owner == uid ? joiner : owner;
    }

    private static String preview(String body) {
        if (body == null) return "";
        String one = body.replaceAll("\\s+", " ").strip();
        return one.length() <= 60 ? one : one.substring(0, 60) + "…";
    }

    /** 我的對話，最近有訊息的排前面；每個對話附未讀數 */
    public List<Map<String, Object>> list(int uid) { return items(uid, null); }

    /** 單一對話：列表上的欄位，加上目前的成員 */
    public Map<String, Object> detail(int convId, int uid) {
        List<Map<String, Object>> one = items(uid, convId);
        if (one.isEmpty()) throw ApiException.notFound("找不到對話");
        Map<String, Object> m = one.get(0);
        m.put("members", db.list("""
                SELECT x.user_id "userId", u.name, d.name department, col.name college, u.degree, u.year, (u.id = c.owner_id) "isOwner", x.joined_at "joinedAt"
                FROM conversation_members x JOIN conversations v ON v.id = x.conversation_id JOIN cases c ON c.id = v.case_id
                JOIN users u ON u.id = x.user_id JOIN departments d ON d.id = u.department_id JOIN colleges col ON col.id = d.college_id
                WHERE x.conversation_id = :c AND x.left_at IS NULL ORDER BY (u.id = c.owner_id) DESC, x.joined_at, u.id""", "c", convId));
        return m;
    }

    /** 隊伍群組的對話編號；不是這支隊伍的成員就找不到 */
    public Map<String, Object> teamConversation(int caseId, int uid) {
        Integer id = db.scalar(Integer.class, """
                SELECT v.id FROM conversations v JOIN conversation_members cm ON cm.conversation_id = v.id
                WHERE v.case_id = :c AND v.kind = 'TEAM' AND cm.user_id = :u AND cm.left_at IS NULL""", "c", caseId, "u", uid);
        if (id == null) throw ApiException.notFound("找不到對話");
        return mapOf("conversationId", id);
    }

    // ---------- 訊息 ----------
    private static final String MESSAGE = """
            SELECT m.id, m.conversation_id "conversationId", m.kind, CASE WHEN m.deleted_at IS NULL THEN m.body ELSE '' END body,
                   (m.deleted_at IS NOT NULL) deleted, m.sender_id "senderId", u.name "senderName", m.client_id "clientId", m.created_at "createdAt"
            FROM messages m LEFT JOIN users u ON u.id = m.sender_id\s""";

    private Map<String, Object> membership(int convId, int uid, boolean lock) {
        var r = db.one("""
                SELECT v.id, v.kind, v.case_id, v.read_only, coalesce(v.last_message_id, 0) last_message_id, cm.since_message_id, cm.last_read_message_id
                FROM conversations v JOIN conversation_members cm ON cm.conversation_id = v.id
                WHERE v.id = :c AND cm.user_id = :u AND cm.left_at IS NULL""" + (lock ? " FOR UPDATE OF v" : ""), "c", convId, "u", uid);
        if (r == null) throw ApiException.notFound("找不到對話");
        return r;
    }

    /**
     * 讀訊息，依編號由小到大。不帶參數：最新的 limit 則；after：編號比它大的（斷線重連後補漏）；before：編號比它小的（往上翻舊訊息）。
     */
    public List<Map<String, Object>> messages(int convId, int uid, Long after, Long before, Integer limit) {
        var mem = membership(convId, uid, false);
        long since = ((Number) mem.get("since_message_id")).longValue();
        int n = limit == null ? 50 : Math.max(1, Math.min(limit, 200));
        if (after != null)
            return db.list(MESSAGE + "WHERE m.conversation_id = :c AND m.id > :a ORDER BY m.id LIMIT :n", "c", convId, "a", Math.max(after, since), "n", n);
        List<Map<String, Object>> rows = db.list(MESSAGE + """
                WHERE m.conversation_id = :c AND m.id > :s AND (cast(:b AS bigint) IS NULL OR m.id < :b) ORDER BY m.id DESC LIMIT :n""",
                "c", convId, "s", since, "b", before, "n", n);
        Collections.reverse(rows);
        return rows;
    }

    /** 送訊息。帶 clientId 重送同一則時，回傳原本那一則，不會變成兩則。 */
    @Transactional
    public Map<String, Object> send(int convId, int uid, String body, String clientId) {
        String text = body == null ? "" : body.strip();
        if (text.isEmpty()) throw ApiException.badRequest("訊息不能是空的");
        if (text.length() > MAX_BODY) throw ApiException.badRequest("一則訊息最多 2,000 個字");
        if (clientId != null && (clientId.isBlank() || clientId.length() > 40)) throw ApiException.badRequest("clientId 最多 40 個字元");
        var mem = membership(convId, uid, true);
        if (clientId != null) {
            var sent = db.one(MESSAGE + "WHERE m.sender_id = :u AND m.client_id = :k", "u", uid, "k", clientId);
            if (sent != null) return sent;
        }
        if (Boolean.TRUE.equals(mem.get("read_only"))) throw ApiException.conflict("READ_ONLY", "這個對話已經結束，不能再傳訊息");
        Integer rate = db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = 'message_rate_per_minute'");
        int perMinute = rate == null ? 30 : rate;
        if (perMinute > 0 && db.count("SELECT count(*) FROM messages WHERE sender_id = :u AND created_at > :t", "u", uid, "t", Db.ts(clock.instant().minusSeconds(60))) >= perMinute)
            throw new ApiException(429, "RATE_LIMITED", "傳得太快了，等一下再傳");
        return insert(convId, uid, "TEXT", text, clientId);
    }

    /** 更新已讀位置；回傳我全部對話的未讀總數（給導覽列的紅點） */
    @Transactional
    public Map<String, Object> markRead(int convId, int uid, Long messageId) {
        var mem = membership(convId, uid, false);
        long last = ((Number) mem.get("last_message_id")).longValue();
        long upTo = messageId == null ? last : Math.min(messageId, last);
        db.exec("UPDATE conversation_members SET last_read_message_id = greatest(last_read_message_id, :m) WHERE conversation_id = :c AND user_id = :u",
                "m", upTo, "c", convId, "u", uid);
        return mapOf("conversationId", convId, "lastReadMessageId", Math.max(upTo, ((Number) mem.get("last_read_message_id")).longValue()), "unreadTotal", unreadTotal(uid));
    }

    public int unreadTotal(int uid) {
        return db.count("""
                SELECT count(*) FROM conversation_members cm JOIN messages m ON m.conversation_id = cm.conversation_id
                WHERE cm.user_id = :u AND cm.left_at IS NULL AND m.id > greatest(cm.last_read_message_id, cm.since_message_id)
                  AND (m.sender_id IS NULL OR m.sender_id <> :u)""", "u", uid);
    }

    /** 寫入一則訊息、更新對話的最後一則、把發送者標成已讀，並排入推送。呼叫前必須已經鎖住對話列。 */
    private Map<String, Object> insert(int convId, Integer senderId, String kind, String body, String clientId) {
        Instant now = clock.instant();
        Long id = db.jdbc.queryForObject("""
                INSERT INTO messages (conversation_id, sender_id, kind, body, client_id, created_at) VALUES (:c, :s, :k, :b, :cid, :t) RETURNING id""",
                Db.params("c", convId, "s", senderId, "k", kind, "b", body, "cid", clientId, "t", Db.ts(now)), Long.class);
        db.exec("UPDATE conversations SET last_message_id = :m, last_message_at = :t WHERE id = :c", "m", id, "t", Db.ts(now), "c", convId);
        if (senderId != null) markReadUpTo(convId, senderId, id);
        Map<String, Object> msg = db.one(MESSAGE + "WHERE m.id = :id", "id", id);
        events.publishEvent(new ChatEvents.MessagePosted(convId, id, senderId, members(convId), mapOf("type", "message.new", "conversationId", convId, "message", msg)));
        return msg;
    }

    private void markReadUpTo(int convId, int userId, long messageId) {
        db.exec("UPDATE conversation_members SET last_read_message_id = greatest(last_read_message_id, :m) WHERE conversation_id = :c AND user_id = :u",
                "m", messageId, "c", convId, "u", userId);
    }

    // ---------- 給事件處理用（同一個套件） ----------
    private void lock(int convId) { db.required("SELECT id FROM conversations WHERE id = :c FOR UPDATE", "找不到對話", "c", convId); }

    Integer teamOf(int caseId) { return db.scalar(Integer.class, "SELECT id FROM conversations WHERE case_id = :c AND kind = 'TEAM'", "c", caseId); }

    Integer talkOf(int engagementId) { return db.scalar(Integer.class, "SELECT id FROM conversations WHERE engagement_id = :e", "e", engagementId); }

    List<Integer> members(int convId) {
        return db.list("SELECT user_id FROM conversation_members WHERE conversation_id = :c AND left_at IS NULL ORDER BY user_id", "c", convId)
                .stream().map(r -> Db.i(r.get("user_id"))).toList();
    }

    String name(int userId) {
        String n = db.scalar(String.class, "SELECT name FROM users WHERE id = :u", "u", userId);
        return n == null ? "隊友" : n;
    }

    /** 建立隊伍群組，把目前的隊伍成員都加進去 */
    int openTeam(int caseId) {
        int conv = db.insertReturningId("INSERT INTO conversations (kind, case_id, created_at) VALUES ('TEAM', :c, :t) RETURNING id", "c", caseId, "t", Db.ts(clock.instant()));
        db.exec("INSERT INTO conversation_members (conversation_id, user_id, joined_at) SELECT :v, m.user_id, :t FROM case_members m WHERE m.case_id = :c",
                "v", conv, "t", Db.ts(clock.instant()), "c", caseId);
        return conv;
    }

    /** 建立洽談對話：申請人或被邀請人，加上隊長 */
    int openTalk(int caseId, int engagementId, int joinerId, int ownerId) {
        int conv = db.insertReturningId("INSERT INTO conversations (kind, case_id, engagement_id, created_at) VALUES ('TALK', :c, :e, :t) RETURNING id",
                "c", caseId, "e", engagementId, "t", Db.ts(clock.instant()));
        for (int u : new LinkedHashSet<>(List.of(joinerId, ownerId)))
            db.exec("INSERT INTO conversation_members (conversation_id, user_id, joined_at) VALUES (:v, :u, :t)", "v", conv, "u", u, "t", Db.ts(clock.instant()));
        return conv;
    }

    /** 加入對話。只看得到加入之後的訊息；曾經離開再回來的人也一樣。 */
    void join(int convId, int userId) {
        lock(convId);
        db.exec("""
                INSERT INTO conversation_members (conversation_id, user_id, joined_at, since_message_id, last_read_message_id)
                SELECT :v, :u, :t, coalesce(v.last_message_id, 0), coalesce(v.last_message_id, 0) FROM conversations v WHERE v.id = :v
                ON CONFLICT (conversation_id, user_id) DO UPDATE
                  SET joined_at = EXCLUDED.joined_at, left_at = NULL, since_message_id = EXCLUDED.since_message_id, last_read_message_id = EXCLUDED.last_read_message_id""",
                "v", convId, "u", userId, "t", Db.ts(clock.instant()));
    }

    void leave(int convId, int userId) {
        db.exec("UPDATE conversation_members SET left_at = :t WHERE conversation_id = :v AND user_id = :u AND left_at IS NULL", "t", Db.ts(clock.instant()), "v", convId, "u", userId);
    }

    void close(int convId) { db.exec("UPDATE conversations SET read_only = TRUE WHERE id = :v", "v", convId); }

    /** 系統訊息：流程上發生的事。actorId 是做這件事的人，他自己不會被標成未讀。 */
    Map<String, Object> system(int convId, String body, Integer actorId) {
        lock(convId);
        Map<String, Object> msg = insert(convId, null, "SYSTEM", body, null);
        if (actorId != null) markReadUpTo(convId, actorId, ((Number) msg.get("id")).longValue());
        return msg;
    }

    /** 申請或邀請時附的那一句話，當成對話的第一則文字訊息（不受每分鐘則數限制） */
    Map<String, Object> text(int convId, int senderId, String body) {
        lock(convId);
        return insert(convId, senderId, "TEXT", body.length() > MAX_BODY ? body.substring(0, MAX_BODY) : body, null);
    }

    void push(Collection<Integer> userIds, Object... kv) {
        if (!userIds.isEmpty()) events.publishEvent(new ChatEvents.Push(List.copyOf(userIds), mapOf(kv)));
    }
}
