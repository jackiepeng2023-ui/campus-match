package tw.edu.fcu.campus.llm;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import tw.edu.fcu.campus.common.Db;

import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Claude API（Messages API）的最小用戶端：JDK HttpClient + Jackson，不依賴 SDK。
 *
 * 只送必要參數（model、max_tokens、system、messages，視需要加 tools 或 output_config.format）：
 *   - 不送 temperature／top_p／top_k、不指定 tool_choice（新模型對這些參數會回 400；工具由模型自行決定是否呼叫）。
 *   - 其他選用參數（例如 thinking、effort）不寫死在程式裡，要用時以 APP_ANTHROPIC_EXTRA_BODY 給一段 JSON 併入請求。
 * 金鑰只從環境變數 APP_ANTHROPIC_API_KEY 讀取；沒有金鑰時 enabled() 為 false，呼叫端一律走規則模式。
 * 每次呼叫（成功或失敗）都記到 llm_calls：用途、模型、token 數、耗時、狀態；不記錄內容。
 */
@Component
public class ClaudeClient {
    private static final Logger log = LoggerFactory.getLogger(ClaudeClient.class);
    private final Db db;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http;
    private final String apiKey, model, fastModel, version, baseUrl;
    private final ObjectNode extraBody;
    private final int timeoutSeconds;

    public ClaudeClient(Db db, @Value("${app.llm.api-key}") String apiKey, @Value("${app.llm.model}") String model, @Value("${app.llm.model-fast}") String fastModel,
                        @Value("${app.llm.version}") String version, @Value("${app.llm.base-url}") String baseUrl,
                        @Value("${app.llm.extra-body}") String extraBody, @Value("${app.llm.timeout-seconds}") int timeoutSeconds) {
        this.db = db; this.apiKey = apiKey == null ? "" : apiKey.trim(); this.model = model; this.fastModel = fastModel; this.version = version;
        this.baseUrl = baseUrl.replaceAll("/+$", ""); this.timeoutSeconds = timeoutSeconds;
        ObjectNode extra = null;
        if (extraBody != null && !extraBody.isBlank()) {
            try { extra = (ObjectNode) json.readTree(extraBody); } catch (Exception e) { log.warn("APP_ANTHROPIC_EXTRA_BODY 不是 JSON 物件，已忽略"); }
        }
        this.extraBody = extra;
        this.http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).proxy(ProxySelector.getDefault()).build();
        log.info("Claude API：{}（endpoint={}，model={}，fast={}，version={}）", enabled() ? "已設定金鑰" : "未設定金鑰 → AI 助理與 AI 擷取以規則模式運作", this.baseUrl, model, fastModel, version);
    }

    public boolean enabled() { return !apiKey.isEmpty(); }
    public String model() { return model; }
    public String fastModel() { return fastModel; }
    public ObjectMapper mapper() { return json; }

    public static class LlmException extends RuntimeException {
        public final int status; public final String type;
        public LlmException(int status, String type, String message) { super(message); this.status = status; this.type = type; }
    }

    /** 一次回覆：content 原樣保留（含 thinking 區塊），多輪工具呼叫時要原封不動送回 */
    public record Reply(String stopReason, ArrayNode content, int inputTokens, int outputTokens, int attempts) {
        public String text() {
            StringBuilder sb = new StringBuilder();
            for (JsonNode b : content) if ("text".equals(b.path("type").asText())) sb.append(b.path("text").asText());
            return sb.toString().trim();
        }
        public List<JsonNode> toolUses() {
            List<JsonNode> l = new ArrayList<>();
            for (JsonNode b : content) if ("tool_use".equals(b.path("type").asText())) l.add(b);
            return l;
        }
    }

    /**
     * @param tools  工具定義（{name, description, input_schema}）；null 表示不用工具
     * @param schema 結構化輸出的 JSON Schema（output_config.format）；null 表示一般文字
     */
    public Reply send(String purpose, Integer userId, String useModel, String system, ArrayNode messages, ArrayNode tools, JsonNode schema, int maxTokens) {
        if (!enabled()) throw new LlmException(0, "not_configured", "未設定 APP_ANTHROPIC_API_KEY");
        ObjectNode body = json.createObjectNode();
        body.put("model", useModel);
        body.put("max_tokens", maxTokens);
        if (system != null && !system.isBlank()) body.put("system", system);
        body.set("messages", messages);
        if (tools != null && !tools.isEmpty()) body.set("tools", tools);
        if (schema != null) body.putObject("output_config").putObject("format").put("type", "json_schema").set("schema", schema);
        if (extraBody != null) extraBody.fields().forEachRemaining(e -> { if (!body.has(e.getKey())) body.set(e.getKey(), e.getValue()); });

        LlmException last = null;
        for (int attempt = 1; attempt <= 2; attempt++) {
            long t0 = System.currentTimeMillis();
            try {
                HttpRequest req = HttpRequest.newBuilder(URI.create(baseUrl + "/v1/messages")).timeout(Duration.ofSeconds(timeoutSeconds))
                        .header("content-type", "application/json").header("x-api-key", apiKey).header("anthropic-version", version)
                        .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body), StandardCharsets.UTF_8)).build();
                HttpResponse<String> res = http.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                long ms = System.currentTimeMillis() - t0;
                JsonNode out = parse(res.body());
                if (res.statusCode() == 200 && out != null && out.has("content")) {
                    int in = out.path("usage").path("input_tokens").asInt(0), outTok = out.path("usage").path("output_tokens").asInt(0);
                    record(purpose, useModel, userId, in, outTok, ms, "OK", null);
                    return new Reply(out.path("stop_reason").asText(""), (ArrayNode) out.get("content"), in, outTok, attempt);
                }
                String type = out == null ? "invalid_response" : out.path("error").path("type").asText("http_" + res.statusCode());
                String msg = out == null ? "回應不是 JSON" : out.path("error").path("message").asText("HTTP " + res.statusCode());
                record(purpose, useModel, userId, 0, 0, ms, "HTTP_" + res.statusCode(), type + "：" + msg);
                last = new LlmException(res.statusCode(), type, msg);
                boolean retryable = res.statusCode() == 429 || res.statusCode() == 529 || res.statusCode() >= 500;
                if (!retryable) throw last;
            } catch (LlmException e) {
                throw e;
            } catch (HttpTimeoutException e) {
                record(purpose, useModel, userId, 0, 0, System.currentTimeMillis() - t0, "TIMEOUT", null);
                last = new LlmException(0, "timeout", "Claude API 逾時（" + timeoutSeconds + " 秒）");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new LlmException(0, "interrupted", "已中斷");
            } catch (Exception e) {
                record(purpose, useModel, userId, 0, 0, System.currentTimeMillis() - t0, "ERROR", e.getClass().getSimpleName());
                last = new LlmException(0, "network", "無法連線到 Claude API：" + e.getClass().getSimpleName());
            }
            if (attempt == 1) try { Thread.sleep(1500); } catch (InterruptedException e) { Thread.currentThread().interrupt(); break; }
        }
        throw last == null ? new LlmException(0, "unknown", "Claude API 呼叫失敗") : last;
    }

    /** 結構化輸出：回傳符合 schema 的 JSON（模型以純文字區塊輸出 JSON） */
    public JsonNode structured(String purpose, Integer userId, String useModel, String system, String userText, JsonNode schema, int maxTokens) {
        ArrayNode messages = json.createArrayNode();
        messages.addObject().put("role", "user").put("content", userText);
        Reply r = send(purpose, userId, useModel, system, messages, null, schema, maxTokens);
        if ("refusal".equals(r.stopReason())) throw new LlmException(200, "refusal", "模型拒絕處理這段內容");
        if ("max_tokens".equals(r.stopReason())) throw new LlmException(200, "max_tokens", "輸出超過長度上限，結果不完整");
        JsonNode out = parse(r.text());
        if (out == null) throw new LlmException(200, "invalid_json", "模型輸出不是合法的 JSON");
        return out;
    }

    private JsonNode parse(String s) {
        try { return s == null || s.isBlank() ? null : json.readTree(s); } catch (Exception e) { return null; }
    }

    private void record(String purpose, String m, Integer userId, int in, int out, long ms, String status, String error) {
        try {
            db.exec("INSERT INTO llm_calls (purpose, model, user_id, input_tokens, output_tokens, duration_ms, status, error, created_at) VALUES (:p, :m, :u, :i, :o, :d, :s, :e, :t)",
                    "p", purpose, "m", m, "u", userId, "i", in, "o", out, "d", (int) ms, "s", status, "e", error == null ? null : error.substring(0, Math.min(300, error.length())),
                    "t", Db.ts(Instant.now()));
        } catch (Exception e) { log.warn("llm_calls 寫入失敗：{}", e.getMessage()); }
    }
}
