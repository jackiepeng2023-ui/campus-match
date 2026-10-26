package tw.edu.fcu.campus.user;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.common.Db;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** 評價、可信度、回應率：全部即時由互評與申請紀錄計算（D9、D22、D38、D41） */
@Service
public class StatsService {
    private final Db db;

    public StatsService(Db db) { this.db = db; }

    public record Stats(Double peerScore, Double avgRating, Double avgMatch, int reviewCount,
                        double awardScore, double responseRate, int responded, int missed,
                        double credibility, int closedCases, int activeCases) {
        public Map<String, Object> toMap() {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("avgRating", avgRating); m.put("avgMatch", avgMatch); m.put("reviewCount", reviewCount);
            m.put("awardScore", awardScore); m.put("responseRate", responseRate);
            m.put("responded", responded); m.put("missed", missed);
            m.put("credibility", credibility); m.put("closedCases", closedCases); m.put("activeCases", activeCases);
            m.put("peerScore", peerScore);
            return m;
        }
    }

    public Stats of(int userId) { return all(List.of(userId)).getOrDefault(userId, empty()); }

    private Stats empty() { return new Stats(null, null, null, 0, 0, 1.0, 0, 0, 1.0, 0, 0); }

    /** 一次算出多位使用者的統計（推薦名單用） */
    public Map<Integer, Stats> all(List<Integer> userIds) {
        Map<Integer, double[]> peer = new HashMap<>();   // [sumRating, sumMatch, n]
        for (var r : db.list("""
                SELECT reviewee_id uid, avg((satisfaction + on_time + communication) / 3.0) r, avg(match_score) m, count(*) n
                FROM reviews WHERE submitted_at IS NOT NULL AND revealed_at IS NOT NULL GROUP BY reviewee_id"""))
            peer.put(Db.i(r.get("uid")), new double[]{Db.d(r.get("r")), Db.d(r.get("m")), Db.d(r.get("n"))});

        Map<Integer, Double> award = new HashMap<>();
        for (var r : db.list("""
                SELECT a.user_id uid, sum(am.score) s FROM user_awards a
                JOIN award_matrix am ON am.rank = a.rank AND am.level = a.level GROUP BY a.user_id"""))
            award.put(Db.i(r.get("uid")), Db.d(r.get("s")));

        // 回應率：以「應回應者」計 —— APPLY 由發案方回應，INVITE 由被邀請者回應；互評逾時未填也算未回應
        Map<Integer, int[]> resp = new HashMap<>();
        for (var r : db.list("""
                SELECT uid, sum(responded) responded, sum(missed) missed FROM (
                  SELECT CASE WHEN e.direction = 'INVITE' THEN e.user_id ELSE c.owner_id END uid,
                         CASE WHEN e.status IN ('ACCEPTED','DECLINED') THEN 1 ELSE 0 END responded,
                         CASE WHEN e.status = 'EXPIRED' THEN 1 ELSE 0 END missed
                  FROM engagements e JOIN case_roles cr ON cr.id = e.case_role_id JOIN cases c ON c.id = cr.case_id
                  UNION ALL
                  SELECT reviewer_id, CASE WHEN submitted_at IS NOT NULL THEN 1 ELSE 0 END, CASE WHEN missed THEN 1 ELSE 0 END FROM reviews
                ) x GROUP BY uid"""))
            resp.put(Db.i(r.get("uid")), new int[]{Db.i(r.get("responded")), Db.i(r.get("missed"))});

        Map<Integer, int[]> cases = new HashMap<>();  // [closed, active]
        for (var r : db.list("""
                SELECT m.user_id uid,
                       count(*) FILTER (WHERE c.status = 'CLOSED') closed,
                       count(*) FILTER (WHERE c.status IN ('OPEN','FORMED','IN_PROGRESS','CLOSING')) active
                FROM case_members m JOIN cases c ON c.id = m.case_id GROUP BY m.user_id"""))
            cases.put(Db.i(r.get("uid")), new int[]{Db.i(r.get("closed")), Db.i(r.get("active"))});

        Map<Integer, Double> coef = new HashMap<>();
        for (var r : db.list("SELECT match_level, coefficient FROM credibility_coefficients"))
            coef.put(Db.i(r.get("match_level")), Db.d(r.get("coefficient")));

        Map<Integer, Stats> out = new HashMap<>();
        for (int uid : userIds) {
            double[] p = peer.get(uid);
            Double peerScore = p == null ? null : p[0] / 5.0;
            Double avgRating = p == null ? null : round(p[0]);
            Double avgMatch = p == null ? null : round(p[1]);
            int n = p == null ? 0 : (int) p[2];
            double credibility = p == null ? coef.getOrDefault(0, 1.0) : coef.getOrDefault((int) Math.round(p[1]), 1.0);
            int[] rs = resp.getOrDefault(uid, new int[]{0, 0});
            double rate = (rs[0] + rs[1]) == 0 ? 1.0 : rs[0] / (double) (rs[0] + rs[1]);
            int[] cs = cases.getOrDefault(uid, new int[]{0, 0});
            out.put(uid, new Stats(peerScore, avgRating, avgMatch, n, Math.min(1.0, award.getOrDefault(uid, 0.0)),
                    rate, rs[0], rs[1], credibility, cs[0], cs[1]));
        }
        return out;
    }

    private static double round(double v) { return Math.round(v * 100) / 100.0; }
}
