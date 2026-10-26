package tw.edu.fcu.campus.common;

import java.util.List;

/** 業務錯誤：回傳 {code, message, reasons} */
public class ApiException extends RuntimeException {
    public final int status;
    public final String code;
    public final List<String> reasons;

    public ApiException(int status, String code, String message) { this(status, code, message, List.of()); }

    public ApiException(int status, String code, String message, List<String> reasons) {
        super(message);
        this.status = status;
        this.code = code;
        this.reasons = reasons;
    }

    public static ApiException badRequest(String msg) { return new ApiException(400, "BAD_REQUEST", msg); }
    public static ApiException forbidden(String msg) { return new ApiException(403, "FORBIDDEN", msg); }
    public static ApiException notFound(String msg) { return new ApiException(404, "NOT_FOUND", msg); }
    public static ApiException conflict(String code, String msg) { return new ApiException(409, code, msg); }
    public static ApiException blocked(String msg, List<String> reasons) { return new ApiException(422, "GATE_BLOCKED", msg, reasons); }
}
