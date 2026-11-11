package tw.edu.fcu.campus.assistant;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;

import java.util.List;
import java.util.Map;

/** AI 助理入口的 API：對話（背景執行＋輪詢）、待確認動作、回饋、操作軌跡、評測指標 */
@RestController
@RequestMapping("/api/v1")
public class AssistantController {
    private final AssistantService assistant;

    public AssistantController(AssistantService assistant) { this.assistant = assistant; }

    @GetMapping("/assistant/status") public Map<String, Object> status() { return assistant.status(Current.id()); }
    @GetMapping("/assistant/sessions") public List<Map<String, Object>> sessions() { return assistant.sessions(Current.id()); }
    @GetMapping("/assistant/sessions/{id}") public Map<String, Object> session(@PathVariable int id) { return assistant.session(Current.id(), id); }
    @DeleteMapping("/assistant/sessions/{id}") public Map<String, Object> delete(@PathVariable int id) { assistant.deleteSession(Current.id(), id); return Map.of("ok", true); }

    public record MessageIn(Integer sessionId, String text) {}

    /** 送出訊息：立即回傳執行中的助理訊息編號；用 GET /assistant/messages/{id} 輪詢進度（工具呼叫軌跡會逐步出現） */
    @PostMapping("/assistant/messages") public Map<String, Object> post(@RequestBody MessageIn in) { return assistant.post(Current.id(), in.sessionId(), in.text()); }
    @GetMapping("/assistant/messages/{id}") public Map<String, Object> message(@PathVariable int id) { return assistant.message(Current.id(), id); }

    public record FeedbackIn(Integer value, String note) {}
    @PostMapping("/assistant/messages/{id}/feedback")
    public Map<String, Object> feedback(@PathVariable int id, @RequestBody FeedbackIn in) { return assistant.feedback(Current.id(), id, in.value(), in.note()); }

    public record DraftIn(Integer competitionId, List<Integer> inviteUserIds, Integer advisorTeacherId, Integer hoursPerWeek) {}
    /** 競賽頁直接起草組隊案件（同樣只產生待確認動作） */
    @PostMapping("/assistant/actions/draft-team")
    public Map<String, Object> draftTeam(@RequestBody DraftIn in) {
        if (in.competitionId() == null) throw tw.edu.fcu.campus.common.ApiException.badRequest("competitionId 為必填");
        return assistant.draftTeam(Current.id(), in.competitionId(), in.inviteUserIds(), in.advisorTeacherId(), in.hoursPerWeek());
    }

    /** 待確認動作：使用者確認後才真正建立案件、送出邀請 */
    @GetMapping("/assistant/actions/{id}") public Map<String, Object> action(@PathVariable int id) { return assistant.action(Current.id(), id); }
    @PostMapping("/assistant/actions/{id}/confirm") public Map<String, Object> confirm(@PathVariable int id) { return assistant.confirm(Current.id(), id); }
    @PostMapping("/assistant/actions/{id}/cancel") public Map<String, Object> cancel(@PathVariable int id) { return assistant.cancel(Current.id(), id); }

    /** 操作軌跡（本人或管理員）：可下載存查 */
    @GetMapping("/assistant/sessions/{id}/trace") public Map<String, Object> trace(@PathVariable int id) { return assistant.trace(Current.id(), Current.isAdmin(), id); }

    /** 評測指標（管理員） */
    @GetMapping("/admin/assistant/metrics") public Map<String, Object> metrics(@RequestParam(required = false) Integer days) { return assistant.metrics(days); }
}
