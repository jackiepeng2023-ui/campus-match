package tw.edu.fcu.campus.llm;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.ProxySelector;
import java.net.URI;
import java.net.URLDecoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.Duration;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 逢甲大學公開課綱擷取（不需登入）：課程檢索系統找出開課 → 教學大綱查詢〈W320104〉取課綱 JSON。
 * 流程與 tools/fcu_syllabus.py 相同（該工具有完整的端點說明與批次模式），這裡是後端即時使用的精簡版：
 *   1. GET  https://coursesearch.fcu.edu.tw/                       → 指派的檢索節點
 *   2. POST {節點}/Service/Search.asmx/GetType2Result             → 依科目名稱查開課
 *   3. GET  ilearntools…/W320104_SyllabusFullVer.aspx?courseid=…   → 302 Location 帶公開 token
 *   4. POST ilearntools…/W320104_syllabus.aspx/GetCourseDetail     → 課綱 JSON
 * 自我約束：兩個請求至少間隔 0.6 秒；遇到 401／403／429 或非預期內容立即放棄，不重試、不繞過；
 * 只取課程描述、課程目標、核心能力、學習工具、授課進度主題；不讀取教師與助教的聯絡資料，文字中的 Email／電話一律遮蔽；
 * 存進資料庫的是節錄（≤ 1,500 字）與來源連結，不保存完整課綱。
 */
@Component
public class SyllabusClient {
    private static final Logger log = LoggerFactory.getLogger(SyllabusClient.class);
    private static final String ENTRY = "https://coursesearch.fcu.edu.tw/";
    private static final String PAGE = "https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx";
    private static final String API = "https://ilearntools.fcu.edu.tw/W320104/W320104_syllabus.aspx/GetCourseDetail";
    private static final Pattern NODE = Pattern.compile("url=(https://coursesearch\\d+\\.fcu\\.edu\\.tw)(/main\\.aspx\\?token=[\\w.\\-]+)");
    private static final Pattern EMAIL = Pattern.compile("[A-Za-z0-9._%+-]+\\s*[@＠]\\s*[A-Za-z0-9-]+(?:\\.[A-Za-z0-9-]+)+");
    private static final Pattern PHONE = Pattern.compile("09\\d{2}[-\\s]?\\d{3}[-\\s]?\\d{3}|\\(?0\\d{1,2}\\)?[-\\s]\\d{3,4}[-\\s]?\\d{4}|(?:分機|ext\\.?)\\s*[:：]?\\s*\\d{3,5}", Pattern.CASE_INSENSITIVE);
    public static final int EXCERPT = 1500;

    private final boolean enabled;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).followRedirects(HttpClient.Redirect.NEVER).proxy(ProxySelector.getDefault()).build();
    private long last = 0;
    private String node;

    public SyllabusClient(@Value("${app.syllabus-fetch}") boolean enabled) { this.enabled = enabled; }

    public boolean enabled() { return enabled; }

    public record Syllabus(String course, String code, String offeredBy, int year, int sms, String sourceUrl, String text) {}

    public static class Blocked extends RuntimeException { public Blocked(String m) { super(m); } }

    /** 兩個請求之間至少 0.6 秒（全系統共用一個節流點） */
    private synchronized HttpResponse<String> send(HttpRequest.Builder b) throws Exception {
        long wait = last + 600 - System.currentTimeMillis();
        if (wait > 0) Thread.sleep(wait);
        last = System.currentTimeMillis();
        HttpResponse<String> r = http.send(b.timeout(Duration.ofSeconds(20)).header("User-Agent", "Mozilla/5.0 (campus-match syllabus importer)").build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (r.statusCode() == 401 || r.statusCode() == 403 || r.statusCode() == 429) throw new Blocked("站方拒絕（HTTP " + r.statusCode() + "）");
        return r;
    }

    private JsonNode postJson(String url, ObjectNode body) throws Exception {
        HttpResponse<String> r = send(HttpRequest.newBuilder(URI.create(url)).header("Content-Type", "application/json; charset=utf-8").header("Accept", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body), StandardCharsets.UTF_8)));
        JsonNode n;
        try { n = json.readTree(r.body()); } catch (Exception e) { throw new Blocked("預期 JSON 卻收到其他內容（HTTP " + r.statusCode() + "）"); }
        if (n.has("d")) n = n.get("d");                              // ASP.NET 可能包一層 {"d": …}
        return n.isTextual() ? json.readTree(n.asText()) : n;
    }

    private synchronized String node() throws Exception {
        if (node == null) {
            Matcher m = NODE.matcher(send(HttpRequest.newBuilder(URI.create(ENTRY)).GET()).body());
            if (!m.find()) throw new Blocked("課程檢索入口沒有指派節點");
            send(HttpRequest.newBuilder(URI.create(m.group(1) + m.group(2))).header("Referer", ENTRY).GET());
            node = m.group(1);
        }
        return node;
    }

    static String norm(String s) { return Normalizer.normalize(s == null ? "" : s, Normalizer.Form.NFKC).replaceAll("\\s+", "").toLowerCase(); }

    /** 名稱符合程度：4 同名、3 同名加(一)(二)、2 開頭或結尾、1 包含、0 不符 */
    static int nameScore(String query, String name) {
        String q = norm(query), n = norm(name);
        if (n.equals(q)) return 4;
        if (n.matches(Pattern.quote(q) + "\\(?[一二三四五六上下1-6iv]+\\)?")) return 3;
        if (n.startsWith(q) || n.endsWith(q)) return 2;
        return n.contains(q) ? 1 : 0;
    }

    /**
     * 找出最符合的開課並取回課綱。terms：依序嘗試的學期（學年, 學期），例如 [[115,1],[114,2],[114,1]]。
     * 課程編碼（正式科目表的 code）相符者優先，其次同名、同名加序號；都沒有則回傳 empty。
     */
    public Optional<Syllabus> fetch(String courseName, String code, List<int[]> terms) {
        if (!enabled || courseName == null || norm(courseName).length() < 2) return Optional.empty();
        try {
            for (int[] term : terms) {
                ObjectNode body = json.createObjectNode();
                body.putObject("baseOptions").put("lang", "cht").put("year", term[0]).put("sms", term[1]);
                ObjectNode opt = body.putObject("typeOptions");
                opt.putObject("code").put("enabled", false).put("value", "");
                opt.putObject("weekPeriod").put("enabled", false).put("week", "*").put("period", "*");
                opt.putObject("course").put("enabled", true).put("value", courseName.trim());
                opt.putObject("teacher").put("enabled", false).put("value", "");
                opt.putObject("useEnglish").put("enabled", false);
                opt.putObject("useLanguage").put("enabled", false).put("value", "01");
                opt.putObject("specificSubject").put("enabled", false).put("value", "1");
                opt.putObject("courseDescription").put("enabled", false).put("value", "");
                JsonNode items = postJson(node() + "/Service/Search.asmx/GetType2Result", body).path("items");
                JsonNode best = null; int bestKey = 0;
                for (JsonNode it : items) {
                    int s = nameScore(courseName, it.path("sub_name").asText());
                    if (s == 0) continue;
                    boolean codeHit = code != null && !code.isBlank() && norm(code).equals(norm(it.path("sub_id3").asText()));
                    int key = (codeHit ? 100 : 0) + s * 10 + (it.path("scr_credit").asDouble(0) > 0 ? 1 : 0);
                    if (key > bestKey) { bestKey = key; best = it; }
                }
                if (best == null || bestKey < 30) continue;          // 只接受編碼相符（≥100）、同名（40）或同名加序號（30）
                String courseId = "" + term[0] + term[1] + best.path("scr_selcode").asText();
                String url = PAGE + "?courseid=" + courseId + "&lang=cht";
                HttpResponse<String> page = send(HttpRequest.newBuilder(URI.create(url)).GET());
                String loc = page.headers().firstValue("Location").orElse("");
                Matcher tk = Pattern.compile("[?&]token=([^&#]+)").matcher(loc);       // Location 形如 …?token=<JWT>#!/fullVer/cht，片段不屬於 token
                if (!tk.find()) { if (loc.contains("noCourse")) continue; throw new Blocked("教學大綱頁沒有發出公開 token"); }
                ObjectNode req = json.createObjectNode(); req.put("access_token", URLDecoder.decode(tk.group(1), StandardCharsets.UTF_8));
                JsonNode d = postJson(API, req);
                if (!d.path("success").asBoolean(false)) continue;
                String text = excerpt(d);
                if (text.isBlank()) continue;
                return Optional.of(new Syllabus(best.path("sub_name").asText().trim(), best.path("sub_id3").asText().trim(), best.path("cls_name").asText().trim(), term[0], term[1], url, text));
            }
        } catch (Blocked e) {
            log.warn("課綱擷取中止：{}（{}）", e.getMessage(), courseName);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (Exception e) {
            log.warn("課綱擷取失敗：{}（{}）", e.getClass().getSimpleName(), courseName);
        }
        return Optional.empty();
    }

    static String clean(String v) {
        String s = (v == null ? "" : v).replaceAll("(?i)<\\s*(?:br|/p|/div|/li|/tr|/h\\d)\\b[^>]*>", "\n").replaceAll("</?[A-Za-z][^>]*>", "")
                .replace("&nbsp;", " ").replace("&middot;", "·").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", "\"").replace("&amp;", "&")
                .replaceAll("&#?[A-Za-z0-9]{2,8};", " ").replace('\u00a0', ' ');
        s = PHONE.matcher(EMAIL.matcher(s).replaceAll("[email]")).replaceAll("[電話]");
        return s.replaceAll("[ \\t\\r\\f]+", " ").replaceAll("\\s*\\n\\s*", "\n").trim();
    }

    /** 課綱 JSON → 節錄：課程描述、課程目標、核心能力、學習工具、授課進度主題（不含 teachersInfo） */
    static String excerpt(JsonNode d) {
        StringBuilder sb = new StringBuilder();
        add(sb, "課程描述", clean(d.path("description").path("describe_ch").asText("")));
        List<String> goals = new ArrayList<>();
        for (JsonNode t : d.path("targets")) { String g = clean(t.path("describe_ch").asText("")); if (!g.isBlank()) goals.add(g); }
        add(sb, "課程目標", String.join("；", goals));
        Set<String> core = new LinkedHashSet<>();
        for (JsonNode c : d.path("courseBankC")) { String g = clean(c.path("core_item").asText("")); if (!g.isBlank()) core.add(g); }
        add(sb, "核心能力", String.join("；", core));
        List<String> tools = new ArrayList<>();
        for (String k : new String[]{"iSoftwares", "assistSoftwares"}) for (JsonNode t : d.path(k)) { String g = clean(t.path("soft_name").asText("")); if (!g.isBlank()) tools.add(g); }
        add(sb, "學習工具", String.join("、", tools));
        List<String> weeks = new ArrayList<>();
        for (JsonNode w : d.path("weeklyScds")) { String g = clean(w.path("tpd_reading").asText("")).replace("\n", " "); if (!g.isBlank()) weeks.add(g); }
        add(sb, "授課進度", String.join("；", weeks));
        String s = sb.toString().trim();
        return s.length() <= EXCERPT ? s : s.substring(0, EXCERPT - 1) + "…";
    }

    private static void add(StringBuilder sb, String label, String text) { if (!text.isBlank()) sb.append("【").append(label).append("】").append(text).append("\n"); }
}
