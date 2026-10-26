package tw.edu.fcu.campus.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import tw.edu.fcu.campus.common.Current;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtService {
    private final SecretKey key;

    public JwtService(@Value("${app.jwt-secret}") String secret) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String issue(int userId, String role, String name) {
        return Jwts.builder().subject(String.valueOf(userId)).claim("role", role).claim("name", name)
                .issuedAt(new Date()).expiration(new Date(System.currentTimeMillis() + 30L * 24 * 3600 * 1000))
                .signWith(key).compact();
    }

    public Current.Principal parse(String token) {
        Claims c = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
        return new Current.Principal(Integer.parseInt(c.getSubject()), c.get("role", String.class), c.get("name", String.class));
    }
}
