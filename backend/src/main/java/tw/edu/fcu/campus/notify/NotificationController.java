package tw.edu.fcu.campus.notify;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Current;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/me")
public class NotificationController {
    private final NotificationService svc;

    public NotificationController(NotificationService svc) { this.svc = svc; }

    @GetMapping("/notifications")
    public Map<String, Object> list() { return svc.list(Current.id()); }

    @PostMapping("/notifications/read-all")
    public Map<String, Object> readAll() { svc.readAll(Current.id()); return Map.of("ok", true); }

    public record DeviceIn(String token) {}

    @PostMapping("/device-tokens")
    public Map<String, Object> device(@RequestBody DeviceIn in) {
        if (in.token() == null || in.token().isBlank()) throw ApiException.badRequest("token 不可為空");
        svc.registerDevice(Current.id(), in.token());
        return Map.of("ok", true);
    }
}
