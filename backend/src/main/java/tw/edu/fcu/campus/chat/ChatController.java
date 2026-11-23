package tw.edu.fcu.campus.chat;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;

import java.util.List;
import java.util.Map;

/** 即時通訊的 REST：讀寫都走這裡，WebSocket（/ws）只負責推送 */
@RestController
@RequestMapping("/api/v1")
public class ChatController {
    private final ChatService chat;

    public ChatController(ChatService chat) { this.chat = chat; }

    @GetMapping("/conversations") public List<Map<String, Object>> list() { return chat.list(Current.id()); }
    @GetMapping("/conversations/{id}") public Map<String, Object> detail(@PathVariable int id) { return chat.detail(id, Current.id()); }

    /** after：補漏（斷線重連後帶最後一則的編號）；before：往上翻舊訊息；都不帶就是最新的 limit 則 */
    @GetMapping("/conversations/{id}/messages")
    public List<Map<String, Object>> messages(@PathVariable int id, @RequestParam(required = false) Long after, @RequestParam(required = false) Long before,
                                              @RequestParam(required = false) Integer limit) {
        return chat.messages(id, Current.id(), after, before, limit);
    }

    public record SendIn(String body, String clientId) {}
    @PostMapping("/conversations/{id}/messages") public Map<String, Object> send(@PathVariable int id, @RequestBody SendIn in) { return chat.send(id, Current.id(), in.body(), in.clientId()); }

    public record ReadIn(Long messageId) {}
    @PostMapping("/conversations/{id}/read") public Map<String, Object> read(@PathVariable int id, @RequestBody(required = false) ReadIn in) {
        return chat.markRead(id, Current.id(), in == null ? null : in.messageId());
    }

    /** 隊伍群組的對話編號（隊伍頁的「進入隊伍群組」） */
    @GetMapping("/cases/{id}/conversation") public Map<String, Object> ofTeam(@PathVariable int id) { return chat.teamConversation(id, Current.id()); }
}
