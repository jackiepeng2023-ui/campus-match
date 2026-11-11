package tw.edu.fcu.campus.review;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tw.edu.fcu.campus.cases.CaseService;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.config.DemoClock;
import tw.edu.fcu.campus.notify.NotificationService;
import tw.edu.fcu.campus.profile.SkillProfileService;

import java.sql.Date;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

/** M4 結案（D34、D35）與雙盲互評（D39、D40） */
@Service
public class ReviewService {
    private final Db db;
    private final DemoClock clock;
    private final NotificationService notify;
    private final CaseService cases;
    private final SkillProfileService profile;

    public ReviewService(Db db, DemoClock clock, NotificationService notify, CaseService cases, SkillProfileService profile) {
        this.db = db; this.clock = clock; this.notify = notify; this.cases = cases; this.profile = profile;
    }

    private int param(String k, int d) { Integer v = db.scalar(Integer.class, "SELECT value FROM system_params WHERE key = :k", "k", k); return v == null ? d : v; }

    // ---------- 結案 ----------
    public record CloseIn(String result) {}

    @Transactional
    public Map<String, Object> requestClose(int caseId, int uid, CloseIn in) {
        var c = db.required("SELECT id, owner_id, status, title FROM cases WHERE id = :id FOR UPDATE", "找不到案件", "id", caseId);
        if (Db.i(c.get("owner_id")) != uid) throw ApiException.forbidden("只有發案方可以提出結案");
        if (!Set.of("FORMED", "IN_PROGRESS").contains((String) c.get("status"))) throw ApiException.conflict("INVALID_STATE", "成案後才能結案");
        if (!Set.of("COMPLETED", "INCOMPLETE").contains(in.result())) throw ApiException.badRequest("result 須為 COMPLETED（完成）或 INCOMPLETE（未完成）");
        Instant now = clock.instant();
        Instant due = now.plusSeconds(param("close_vote_hours", 72) * 3600L);
        int reqId = db.insertReturningId("INSERT INTO close_requests (case_id, result, auto, status, requested_at, due_at) VALUES (:c, :r, FALSE, 'OPEN', :n, :d) RETURNING id",
                "c", caseId, "r", in.result(), "n", Db.ts(now), "d", Db.ts(due));
        db.exec("UPDATE cases SET status = 'CLOSING' WHERE id = :c", "c", caseId);
        List<Integer> voters = voters(caseId);
        for (int v : voters) notify.notify(v, "CLOSE_VOTE", "請確認結案", "「" + c.get("title") + "」發案方提出結案（" + ("COMPLETED".equals(in.result()) ? "完成" : "未完成") + "），72 小時內未回應視為同意", "/cases/" + caseId);
        notify.log(uid, "case", caseId, "CLOSE_REQUEST", "{\"result\":\"" + in.result() + "\"}");
        if (voters.isEmpty()) finalizeClose(caseId, in.result(), now, reqId);
        else evaluate(reqId, false);
        return cases.detail(caseId, uid, false);
    }

    private List<Integer> voters(int caseId) {
        return db.list("SELECT user_id FROM case_members WHERE case_id = :c AND NOT is_owner", "c", caseId).stream().map(r -> Db.i(r.get("user_id"))).toList();
    }

    public record VoteIn(Boolean agree) {}

    @Transactional
    public Map<String, Object> vote(int reqId, int uid, VoteIn in) {
        var req = db.required("SELECT id, case_id, status FROM close_requests WHERE id = :id FOR UPDATE", "找不到結案申請", "id", reqId);
        if (!"OPEN".equals(req.get("status"))) throw ApiException.conflict("INVALID_STATE", "此結案申請已結束");
        int caseId = Db.i(req.get("case_id"));
        if (!voters(caseId).contains(uid)) throw ApiException.forbidden("只有本案成員（發案方除外）可以確認");
        if (in.agree() == null) throw ApiException.badRequest("agree 為必填");
        db.exec("INSERT INTO close_votes VALUES (:r, :u, :a, :t) ON CONFLICT (close_request_id, user_id) DO UPDATE SET agree = :a, voted_at = :t",
                "r", reqId, "u", uid, "a", in.agree(), "t", Db.ts(clock.instant()));
        evaluate(reqId, false);
        return cases.detail(caseId, uid, false);
    }

    /** 過半成員同意即成立；逾時未投票視為同意（D34） */
    private void evaluate(int reqId, boolean timeout) {
        var req = db.required("SELECT id, case_id, result, status FROM close_requests WHERE id = :id", "找不到結案申請", "id", reqId);
        if (!"OPEN".equals(req.get("status"))) return;
        int caseId = Db.i(req.get("case_id"));
        int n = voters(caseId).size();
        int agree = db.count("SELECT count(*) FROM close_votes WHERE close_request_id = :r AND agree", "r", reqId);
        int disagree = db.count("SELECT count(*) FROM close_votes WHERE close_request_id = :r AND NOT agree", "r", reqId);
        int needed = n / 2 + 1;
        if (timeout) agree += n - agree - disagree;
        Instant now = clock.instant();
        if (agree >= needed) {
            db.exec("UPDATE close_requests SET status = 'PASSED', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", reqId);
            finalizeClose(caseId, (String) req.get("result"), now, reqId);
        } else if (n - disagree < needed) {
            db.exec("UPDATE close_requests SET status = 'REJECTED', decided_at = :t WHERE id = :id", "t", Db.ts(now), "id", reqId);
            db.exec("UPDATE cases SET status = 'IN_PROGRESS' WHERE id = :c", "c", caseId);
            var c = db.one("SELECT owner_id, title FROM cases WHERE id = :c", "c", caseId);
            notify.notify(Db.i(c.get("owner_id")), "CLOSE_REJECTED", "結案未獲同意", "「" + c.get("title") + "」成員不同意結案，案件回到執行中", "/cases/" + caseId);
        }
    }

    /** CLOSED：建立每一對成員的互評列，72 小時內完成，雙盲公開 */
    void finalizeClose(int caseId, String result, Instant now, Integer reqId) {
        db.exec("UPDATE cases SET status = 'CLOSED', close_result = :r, closed_at = :t WHERE id = :c", "r", result, "t", Db.ts(now), "c", caseId);
        if (reqId != null) db.exec("UPDATE close_requests SET status = 'PASSED', decided_at = coalesce(decided_at, :t) WHERE id = :id", "t", Db.ts(now), "id", reqId);
        List<Integer> members = db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", caseId).stream().map(r -> Db.i(r.get("user_id"))).toList();
        Instant due = now.plusSeconds(param("review_hours", 72) * 3600L);
        for (int a : members) for (int b : members) if (a != b)
            db.exec("INSERT INTO reviews (case_id, reviewer_id, reviewee_id, due_at) VALUES (:c, :a, :b, :d) ON CONFLICT DO NOTHING", "c", caseId, "a", a, "b", b, "d", Db.ts(due));
        var c = db.one("SELECT title FROM cases WHERE id = :c", "c", caseId);
        for (int m : members) notify.notify(m, "REVIEW", "案件已結案，請完成互評", "「" + c.get("title") + "」已結案（" + ("COMPLETED".equals(result) ? "完成" : "未完成") + "），請在 72 小時內評價隊友；雙方都送出後才會同時公開", "/cases/" + caseId + "/review");
        // 結案證據（CASE）要等互評雙盲公開、隊友相符度達門檻才產生：見 submit() 與 reviewTimeout()
        notify.log(null, "case", caseId, "CLOSED", "{\"result\":\"" + result + "\"}");
    }

    // ---------- 互評 ----------
    public Map<String, Object> pending(int caseId, int uid) {
        var c = db.required("SELECT id, title, type, owner_id, status FROM cases WHERE id = :id", "找不到案件", "id", caseId);
        List<Map<String, Object>> rows = db.list("""
                SELECT r.id, r.reviewee_id "revieweeId", u.name, d.name department, r.due_at "dueAt", r.submitted_at "submittedAt", r.missed,
                       (u.id = c.owner_id) "isOwner", r.satisfaction, r.match_score "matchScore", r.on_time "onTime", r.communication, r.attribution_kept "attributionKept", r.comment
                FROM reviews r JOIN users u ON u.id = r.reviewee_id JOIN departments d ON d.id = u.department_id JOIN cases c ON c.id = r.case_id
                WHERE r.case_id = :c AND r.reviewer_id = :u ORDER BY u.name""", "c", caseId, "u", uid);
        return Map.of("caseId", caseId, "caseTitle", c.get("title"), "caseType", c.get("type"), "askAttribution", "RESEARCH".equals(c.get("type")), "items", rows);
    }

    public record ReviewIn(Integer revieweeId, Integer satisfaction, Integer matchScore, Integer onTime, Integer communication, String attributionKept, String comment) {}

    @Transactional
    public Map<String, Object> submit(int caseId, int uid, List<ReviewIn> in) {
        var c = db.required("SELECT id, type, owner_id, status FROM cases WHERE id = :id", "找不到案件", "id", caseId);
        if (!"CLOSED".equals(c.get("status"))) throw ApiException.conflict("INVALID_STATE", "結案後才能互評");
        Instant now = clock.instant();
        for (ReviewIn r : in) {
            for (Integer v : List.of(r.satisfaction(), r.matchScore(), r.onTime(), r.communication()))
                if (v == null || v < 1 || v > 5) throw ApiException.badRequest("四題評分皆須為 1–5");
            boolean askAttr = "RESEARCH".equals(c.get("type")) && r.revieweeId() == Db.i(c.get("owner_id"));
            String attr = askAttr ? r.attributionKept() : null;
            if (askAttr && !Set.of("YES", "PARTIAL", "NO").contains(attr)) throw ApiException.badRequest("研究協作須回答成果歸屬是否兌現（YES／PARTIAL／NO）");
            int n = db.exec("""
                    UPDATE reviews SET satisfaction = :s, match_score = :m, on_time = :o, communication = :co, attribution_kept = :a, comment = :cm, submitted_at = :t
                    WHERE case_id = :c AND reviewer_id = :u AND reviewee_id = :r AND submitted_at IS NULL AND NOT missed""",
                    "s", r.satisfaction(), "m", r.matchScore(), "o", r.onTime(), "co", r.communication(), "a", attr, "cm", r.comment(), "t", Db.ts(now),
                    "c", caseId, "u", uid, "r", r.revieweeId());
            if (n == 0) throw ApiException.conflict("INVALID_STATE", "此評價已送出、逾期或不存在");
            // 雙盲：雙方都送出才同時公開（D40）
            if (db.count("SELECT count(*) FROM reviews WHERE case_id = :c AND reviewer_id = :r AND reviewee_id = :u AND submitted_at IS NOT NULL", "c", caseId, "r", r.revieweeId(), "u", uid) > 0)
                db.exec("UPDATE reviews SET revealed_at = :t WHERE case_id = :c AND revealed_at IS NULL AND ((reviewer_id = :u AND reviewee_id = :r) OR (reviewer_id = :r AND reviewee_id = :u))",
                        "t", Db.ts(now), "c", caseId, "u", uid, "r", r.revieweeId());
        }
        notify.log(uid, "review", caseId, "SUBMIT", "{\"count\":" + in.size() + "}");
        // 互評公開後重新盤點本案成員：相符度達門檻 → 角色技能得到「已驗證」的結案證據（D55）
        if (db.count("SELECT count(*) FROM reviews WHERE case_id = :c AND revealed_at = :t", "c", caseId, "t", Db.ts(now)) > 0) profile.rebuildForCase(caseId);
        return pending(caseId, uid);
    }

    /** 我收到的評價：團隊少於 3 人只併入累計平均，不顯示單案分數（D40） */
    public Map<String, Object> received(int uid) {
        List<Map<String, Object>> perCase = db.list("""
                SELECT c.id "caseId", c.title, c.type, c.closed_at "closedAt",
                       (SELECT count(*) FROM case_members m WHERE m.case_id = c.id) members,
                       round(avg(r.satisfaction), 2) satisfaction, round(avg(r.match_score), 2) "matchScore", round(avg(r.on_time), 2) "onTime",
                       round(avg(r.communication), 2) communication, count(*) n,
                       string_agg(r.comment, ' ／ ') FILTER (WHERE r.comment IS NOT NULL AND r.comment <> '') comments
                FROM reviews r JOIN cases c ON c.id = r.case_id
                WHERE r.reviewee_id = :u AND r.submitted_at IS NOT NULL AND r.revealed_at IS NOT NULL
                GROUP BY c.id ORDER BY c.closed_at DESC""", "u", uid);
        List<Map<String, Object>> visible = new ArrayList<>();
        for (var pc : perCase) {
            if (Db.i(pc.get("members")) < 3) {
                Map<String, Object> hidden = new LinkedHashMap<>();
                hidden.put("caseId", pc.get("caseId")); hidden.put("title", pc.get("title")); hidden.put("closedAt", pc.get("closedAt"));
                hidden.put("hidden", true); hidden.put("note", "團隊少於 3 人，分數只併入累計平均");
                visible.add(hidden);
            } else { pc.put("hidden", false); visible.add(pc); }
        }
        var overall = db.one("""
                SELECT round(avg(satisfaction), 2) satisfaction, round(avg(match_score), 2) "matchScore", round(avg(on_time), 2) "onTime",
                       round(avg(communication), 2) communication, count(*) n
                FROM reviews WHERE reviewee_id = :u AND submitted_at IS NOT NULL AND revealed_at IS NOT NULL""", "u", uid);
        return Map.of("overall", overall, "cases", visible);
    }

    // ---------- 排程 ----------
    @Transactional
    public int closeVoteTimeout() {
        var rows = db.list("SELECT id FROM close_requests WHERE status = 'OPEN' AND due_at <= :t", "t", Db.ts(clock.instant()));
        for (var r : rows) evaluate(Db.i(r.get("id")), true);
        return rows.size();
    }

    @Transactional
    public int autoClose() {
        int days = param("auto_close_days", 7);
        LocalDate today = LocalDate.now(clock);
        var rows = db.list("SELECT id, end_date FROM cases WHERE status = 'IN_PROGRESS' AND end_date + cast(:d AS int) <= :today", "d", days, "today", today);
        for (var r : rows) {
            int caseId = Db.i(r.get("id"));
            Instant now = clock.instant();
            int reqId = db.insertReturningId("INSERT INTO close_requests (case_id, result, auto, status, requested_at, due_at, decided_at) VALUES (:c, 'COMPLETED', TRUE, 'PASSED', :t, :t, :t) RETURNING id", "c", caseId, "t", Db.ts(now));
            finalizeClose(caseId, "COMPLETED", now, reqId);
        }
        return rows.size();
    }

    @Transactional
    public int reviewTimeout() {
        Instant now = clock.instant();
        int missed = db.exec("UPDATE reviews SET missed = TRUE WHERE submitted_at IS NULL AND NOT missed AND due_at <= :t", "t", Db.ts(now));
        var cases = db.list("SELECT DISTINCT case_id FROM reviews WHERE submitted_at IS NOT NULL AND revealed_at IS NULL AND due_at <= :t", "t", Db.ts(now));
        db.exec("UPDATE reviews SET revealed_at = :t WHERE submitted_at IS NOT NULL AND revealed_at IS NULL AND due_at <= :t", "t", Db.ts(now));
        for (var c : cases) profile.rebuildForCase(Db.i(c.get("case_id")));
        return missed;
    }
}
