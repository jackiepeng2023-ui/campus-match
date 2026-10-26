package tw.edu.fcu.campus.common;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/** 目前登入者 */
public final class Current {
    public record Principal(int id, String role, String name) {}

    public static Principal principal() {
        Authentication a = SecurityContextHolder.getContext().getAuthentication();
        if (a == null || !(a.getPrincipal() instanceof Principal p)) throw new ApiException(401, "UNAUTHORIZED", "請先登入");
        return p;
    }

    public static int id() { return principal().id(); }

    public static boolean isAdmin() { return "ADMIN".equals(principal().role()); }
}
