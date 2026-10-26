package tw.edu.fcu.campus.notify;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.math.BigInteger;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Duration;
import java.util.Arrays;
import java.util.Base64;

/**
 * APNs 推播（D44）：以 .p8 金鑰產生 ES256 JWT，走 HTTP/2 直接呼叫 Apple，不需第三方套件。
 * 未設定金鑰時只記錄 log，站內通知不受影響。
 */
@Component
public class ApnsSender {
    private static final Logger log = LoggerFactory.getLogger(ApnsSender.class);
    private final String keyPath, keyId, teamId, bundleId;
    private final boolean sandbox;
    private PrivateKey key;
    private String cachedJwt;
    private long jwtIssuedAt;
    private final HttpClient http = HttpClient.newBuilder().version(HttpClient.Version.HTTP_2).connectTimeout(Duration.ofSeconds(10)).build();

    public ApnsSender(@Value("${apns.key-path}") String keyPath, @Value("${apns.key-id}") String keyId,
                      @Value("${apns.team-id}") String teamId, @Value("${apns.bundle-id}") String bundleId,
                      @Value("${apns.sandbox}") boolean sandbox) {
        this.keyPath = keyPath; this.keyId = keyId; this.teamId = teamId; this.bundleId = bundleId; this.sandbox = sandbox;
    }

    public boolean configured() { return keyPath != null && !keyPath.isBlank() && !keyId.isBlank() && !teamId.isBlank(); }

    public void send(String deviceToken, String title, String body, String link) {
        if (!configured()) { log.debug("APNs 未設定，略過推播：{} / {}", title, body); return; }
        try {
            String host = sandbox ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
            String payload = "{\"aps\":{\"alert\":{\"title\":" + q(title) + ",\"body\":" + q(body) + "},\"sound\":\"default\"},\"link\":" + q(link == null ? "" : link) + "}";
            HttpRequest req = HttpRequest.newBuilder(URI.create(host + "/3/device/" + deviceToken))
                    .header("authorization", "bearer " + jwt())
                    .header("apns-topic", bundleId).header("apns-push-type", "alert").header("apns-priority", "10")
                    .POST(HttpRequest.BodyPublishers.ofString(payload, StandardCharsets.UTF_8)).build();
            HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString());
            if (res.statusCode() != 200) log.warn("APNs 回應 {}：{}", res.statusCode(), res.body());
        } catch (Exception e) {
            log.warn("APNs 發送失敗：{}", e.toString());
        }
    }

    private synchronized String jwt() throws Exception {
        long now = System.currentTimeMillis() / 1000;
        if (cachedJwt != null && now - jwtIssuedAt < 50 * 60) return cachedJwt;
        if (key == null) {
            String pem = Files.readString(Path.of(keyPath)).replaceAll("-----[A-Z ]+-----", "").replaceAll("\\s", "");
            key = KeyFactory.getInstance("EC").generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(pem)));
        }
        String header = b64("{\"alg\":\"ES256\",\"kid\":\"" + keyId + "\"}");
        String claims = b64("{\"iss\":\"" + teamId + "\",\"iat\":" + now + "}");
        String signingInput = header + "." + claims;
        Signature sig = Signature.getInstance("SHA256withECDSA");
        sig.initSign(key);
        sig.update(signingInput.getBytes(StandardCharsets.US_ASCII));
        byte[] jose = derToJose(sig.sign());
        cachedJwt = signingInput + "." + Base64.getUrlEncoder().withoutPadding().encodeToString(jose);
        jwtIssuedAt = now;
        return cachedJwt;
    }

    /** DER (SEQUENCE of two INTEGER) → JOSE r||s，各 32 bytes */
    static byte[] derToJose(byte[] der) {
        int offset = 2;
        if ((der[1] & 0xff) > 0x80) offset = 3;
        int rLen = der[offset + 1];
        byte[] r = Arrays.copyOfRange(der, offset + 2, offset + 2 + rLen);
        int sOff = offset + 2 + rLen;
        int sLen = der[sOff + 1];
        byte[] s = Arrays.copyOfRange(der, sOff + 2, sOff + 2 + sLen);
        byte[] out = new byte[64];
        byte[] rb = new BigInteger(1, r).toByteArray(), sb = new BigInteger(1, s).toByteArray();
        System.arraycopy(rb, Math.max(0, rb.length - 32), out, Math.max(0, 32 - rb.length), Math.min(32, rb.length));
        System.arraycopy(sb, Math.max(0, sb.length - 32), out, 32 + Math.max(0, 32 - sb.length), Math.min(32, sb.length));
        return out;
    }

    private static String b64(String s) { return Base64.getUrlEncoder().withoutPadding().encodeToString(s.getBytes(StandardCharsets.UTF_8)); }

    private static String q(String s) { return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ") + "\""; }
}
