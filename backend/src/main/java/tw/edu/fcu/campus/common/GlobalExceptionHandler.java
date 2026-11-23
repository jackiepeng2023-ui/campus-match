package tw.edu.fcu.campus.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<Map<String, Object>> api(ApiException e) {
        return ResponseEntity.status(e.status).body(Map.of("code", e.code, "message", e.getMessage(), "reasons", e.reasons));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> denied(AccessDeniedException e) {
        return ResponseEntity.status(403).body(Map.of("code", "FORBIDDEN", "message", "沒有權限"));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> unreadable(HttpMessageNotReadableException e) {
        return ResponseEntity.status(400).body(Map.of("code", "BAD_REQUEST", "message", "請求格式錯誤"));
    }

    @ExceptionHandler({MethodArgumentTypeMismatchException.class})
    public ResponseEntity<Map<String, Object>> badParam(Exception e) {
        return ResponseEntity.status(400).body(Map.of("code", "BAD_REQUEST", "message", "參數格式錯誤"));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> noResource(NoResourceFoundException e) {
        return ResponseEntity.status(404).body(Map.of("code", "NOT_FOUND", "message", "找不到資源"));
    }

    /** 未預期的錯誤：細節只寫進紀錄，回給用戶端的是固定訊息加追蹤編號（不把例外訊息帶出去） */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> other(Exception e) {
        String trace = java.util.UUID.randomUUID().toString().substring(0, 8);
        log.error("unhandled [{}]", trace, e);
        return ResponseEntity.status(500).body(Map.of("code", "INTERNAL", "message", "系統發生錯誤，請稍後再試（追蹤編號 " + trace + "）", "trace", trace));
    }
}
