package tw.edu.fcu.campus.chat;

import java.util.Collection;
import java.util.Map;

/** chat 模組內部的推送事件：在交易內發布，由 {@link PushGateway} 等交易提交後才送出 */
public final class ChatEvents {
    private ChatEvents() {}

    /** 把一則 WebSocket 訊息送給這些使用者（在線上的才收得到） */
    public record Push(Collection<Integer> userIds, Map<String, Object> payload) {}

    /** 新訊息：送給對話成員；不在線上的成員改送 APNs（只寫「你有新訊息」，不帶內文） */
    public record MessagePosted(int conversationId, long messageId, Integer senderId, Collection<Integer> recipientIds, Map<String, Object> payload) {}
}
