package tw.edu.fcu.campus.agent;

import org.springframework.stereotype.Service;
import tw.edu.fcu.campus.agent.AgentModels.Need;
import tw.edu.fcu.campus.agent.AgentModels.NeedIn;
import tw.edu.fcu.campus.agent.AgentModels.SkillItem;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Db;
import tw.edu.fcu.campus.ranking.RankingEngine;
import tw.edu.fcu.campus.ranking.RankingService;
import tw.edu.fcu.campus.ranking.RankingService.SkillSet;
import tw.edu.fcu.campus.ranking.RankingService.UserRow;
import tw.edu.fcu.campus.user.StatsService;

import java.sql.Date;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

import static tw.edu.fcu.campus.agent.AgentModels.tier;

/**
 * 學生 Agent（技能互補）：學生 Skill × 其他學生 Skill × 組隊需求 → 推薦互補隊友、互補原因、團隊缺口。
 *
 * 1. 團隊缺口 = 需求技能中，現有成員（含本人）沒有人達到需求階級的項目。
 * 2. 候選人用與案件推薦同一顆排序引擎（D17）評分：S 只看「缺口技能」（核心權重 2、輔助 1），T 時間、R 評價、P 回應率、C 跨系互補照舊；
 *    閘門 G1 身分、G3 時間照舊。至少補上一項缺口才列入推薦。
 * 3. 建議組合：每次挑「補上最多剩餘缺口（加權）」的人，同分看總分，直到缺口補齊或名額用完。
 * 對外只顯示階級與可信狀態，不顯示其他學生的分數（D16）。
 */
@Service
public class StudentAgent {
    private final Db db;
    private final CatalogService catalog;
    private final RankingService ranking;
    private final StatsService stats;

    public StudentAgent(Db db, CatalogService catalog, RankingService ranking, StatsService stats) {
        this.db = db; this.catalog = catalog; this.ranking = ranking; this.stats = stats;
    }

    public record Req(Integer competitionId, Integer caseId, List<NeedIn> skills, List<Integer> memberIds, Integer hoursPerWeek, Integer seats, Integer limit) {}

    public enum Status { MET, BELOW, MISSING }

    /** 一項需求在團隊裡的涵蓋情形：by＝達到需求階級的成員 */
    public record Coverage(Need need, Status status, int bestTier, List<Integer> by) {}

    /** 純函式：團隊對需求的涵蓋情形 */
    public static List<Coverage> coverage(List<Need> needs, Map<Integer, SkillSet> team) {
        List<Coverage> out = new ArrayList<>();
        for (Need n : needs) {
            int best = 0; boolean any = false;
            List<Integer> by = new ArrayList<>();
            for (var e : team.entrySet()) {
                SkillSet sk = e.getValue() == null ? SkillSet.EMPTY : e.getValue();
                int lv = sk.level(n.skillId());
                if (sk.score(n.skillId()) > 0) any = true;
                best = Math.max(best, lv);
                if (lv >= n.minTier()) by.add(e.getKey());
            }
            out.add(new Coverage(n, !by.isEmpty() ? Status.MET : any ? Status.BELOW : Status.MISSING, best, by));
        }
        return out;
    }

    /** 候選人能補上哪些缺口（達到需求階級） */
    public static List<Need> fills(List<Need> gaps, SkillSet sk) { return gaps.stream().filter(n -> sk.level(n.skillId()) >= n.minTier()).toList(); }

    public record Pick(int userId, List<Need> fills) {}

    /** 純函式：貪婪法建議組合。cands＝候選人（依總分由高到低）→ 能補的缺口 */
    public static List<Pick> suggest(List<Need> gaps, LinkedHashMap<Integer, List<Need>> cands, int seats) {
        List<Pick> picks = new ArrayList<>();
        Set<Integer> remaining = gaps.stream().map(Need::skillId).collect(Collectors.toCollection(LinkedHashSet::new));
        Set<Integer> used = new HashSet<>();
        while (picks.size() < seats && !remaining.isEmpty()) {
            Integer best = null; double bestW = 0; List<Need> bestFills = List.of();
            for (var e : cands.entrySet()) {
                if (used.contains(e.getKey())) continue;
                List<Need> f = e.getValue().stream().filter(n -> remaining.contains(n.skillId())).toList();
                double w = f.stream().mapToDouble(Need::weight).sum();
                if (w > bestW) { best = e.getKey(); bestW = w; bestFills = f; }      // 同權重時保留排在前面（總分較高）的人
            }
            if (best == null) break;
            picks.add(new Pick(best, bestFills));
            used.add(best);
            bestFills.forEach(n -> remaining.remove(n.skillId()));
        }
        return picks;
    }

    private record Ctx(String type, Integer id, String title, List<Need> needs, Set<Integer> team, LocalDate start, LocalDate end, int hours, int seats) {}

    private Ctx context(int uid, Req req) {
        LocalDate today = catalog.today();
        Set<Integer> team = new LinkedHashSet<>(List.of(uid));
        if (req.memberIds() != null) for (Integer m : req.memberIds()) {
            if (m == null) continue;
            if (db.count("SELECT count(*) FROM users WHERE id = :u AND role = 'STUDENT' AND deidentified_at IS NULL", "u", m) == 0) throw ApiException.badRequest("成員不存在：" + m);
            team.add(m);
        }
        int hours = req.hoursPerWeek() == null ? 4 : Math.max(1, Math.min(40, req.hoursPerWeek()));
        if (req.caseId() != null) {
            var c = db.required("SELECT id, title, owner_id, start_date, end_date FROM cases WHERE id = :c", "找不到案件", "c", req.caseId());
            var members = db.list("SELECT user_id FROM case_members WHERE case_id = :c", "c", req.caseId()).stream().map(r -> Db.i(r.get("user_id"))).toList();
            if (!members.contains(uid)) throw ApiException.forbidden("只有案件成員可以用這個案件找隊友");
            team.addAll(members);
            int open = db.count("SELECT coalesce(sum(headcount - filled_count), 0) FROM case_roles WHERE case_id = :c", "c", req.caseId());
            return new Ctx("CASE", req.caseId(), (String) c.get("title"), catalog.needsOfCase(req.caseId()), team,
                    ((Date) c.get("start_date")).toLocalDate(), ((Date) c.get("end_date")).toLocalDate(), hours, req.seats() == null ? Math.max(open, 1) : req.seats());
        }
        if (req.competitionId() != null) {
            var c = catalog.competition(req.competitionId());
            LocalDate end = c.eventDate() != null && !c.eventDate().isBefore(today) ? c.eventDate() : c.deadline() != null && !c.deadline().isBefore(today) ? c.deadline().plusDays(30) : today.plusDays(60);
            int max = c.teamMax() == null ? 5 : c.teamMax();
            return new Ctx("COMPETITION", c.id(), c.display(), c.needs(), team, today, end, hours, req.seats() == null ? Math.max(max - team.size(), 0) : req.seats());
        }
        List<Need> needs = catalog.needs(req.skills());
        if (needs.isEmpty()) throw ApiException.badRequest("請指定競賽（competitionId）、案件（caseId）或需求技能（skills）");
        return new Ctx("CUSTOM", null, "自訂需求", needs, team, today, today.plusDays(60), hours, req.seats() == null ? 3 : req.seats());
    }

    public Map<String, Object> recommend(int uid, Req req) {
        Ctx ctx = context(uid, req);
        List<UserRow> users = ranking.loadStudents(null);
        Map<Integer, UserRow> byId = users.stream().collect(Collectors.toMap(UserRow::id, u -> u));
        UserRow me = byId.get(uid);
        if (me == null) throw ApiException.forbidden("只有學生帳號可以使用組隊推薦");
        Map<Integer, SkillSet> skills = ranking.loadSkills(null);
        var st = stats.all(users.stream().map(UserRow::id).toList());

        // 1. 團隊缺口
        Map<Integer, SkillSet> teamSkills = new LinkedHashMap<>();
        for (int m : ctx.team()) teamSkills.put(m, skills.getOrDefault(m, SkillSet.EMPTY));
        List<Coverage> cov = coverage(ctx.needs(), teamSkills);
        List<Need> gaps = cov.stream().filter(c -> c.status() != Status.MET).map(Coverage::need).toList();
        boolean covered = gaps.isEmpty();
        List<Need> target = covered ? ctx.needs() : gaps;          // 沒有缺口時，改找能加強全部需求技能的人

        // 2. 同一顆排序引擎：角色的技能 = 缺口技能（全部視為加分項，核心權重 2）
        var role = new RankingEngine.Role(ctx.hours(), ctx.start(), ctx.end(),
                target.stream().map(n -> new RankingEngine.RoleSkill(n.skillId(), n.name(), n.minTier(), n.minScore(), false, n.weight())).toList(),
                me.college(), me.dept(), true, Math.max(ctx.seats(), 1));
        var w = ranking.weights();
        List<Map<String, Object>> ok = new ArrayList<>(), blocked = new ArrayList<>();
        Map<Integer, List<Need>> fillsOf = new HashMap<>();
        Map<Integer, Double> scoreOf = new HashMap<>();
        Set<Integer> teamMet = cov.stream().filter(c -> c.status() == Status.MET).map(c -> c.need().skillId()).collect(Collectors.toSet());
        for (UserRow u : users) {
            if (ctx.team().contains(u.id())) continue;
            SkillSet sk = skills.getOrDefault(u.id(), SkillSet.EMPTY);
            List<Need> f = fills(target, sk);
            if (f.isEmpty()) continue;                                 // 一項缺口都補不上：不列入
            var r = ranking.engine().evaluate(role, ranking.candidate(u, sk, st.get(u.id()), uid, ctx.team(), Set.of()), w);
            List<Need> partial = target.stream().filter(n -> sk.score(n.skillId()) > 0 && sk.level(n.skillId()) < n.minTier()).toList();
            long overlap = ctx.needs().stream().filter(n -> teamMet.contains(n.skillId()) && sk.level(n.skillId()) >= n.minTier()).count();
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("userId", u.id()); m.put("name", u.name()); m.put("department", u.dept()); m.put("college", u.college()); m.put("degree", u.degree()); m.put("year", u.year());
            m.put("score", r.score()); m.put("breakdown", r.breakdown()); m.put("activeCases", r.activeCases());
            m.put("fills", f.stream().map(n -> item(n, sk)).toList());
            m.put("partial", partial.stream().map(n -> item(n, sk)).toList());
            List<String> why = new ArrayList<>();
            why.add((covered ? "可加強：" : "補上團隊缺口：") + String.join("、", f.stream().map(n -> item(n, sk).label() + (n.core() ? "［核心］" : "")).toList()));
            if (!partial.isEmpty()) why.add("可部分補強：" + String.join("、", partial.stream().map(n -> n.name() + "（目前" + tier(sk.level(n.skillId())) + "，需求" + tier(n.minTier()) + "）").toList()));
            if (!covered) why.add(overlap == 0 ? "與現有成員已具備的技能不重疊，互補性高" : "與現有成員重疊 " + overlap + " 項，可分擔工作");
            if (!Objects.equals(u.college(), me.college())) why.add("跨學院：" + u.college() + "・" + u.dept());
            else if (!Objects.equals(u.dept(), me.dept())) why.add("同學院不同系：" + u.dept());
            m.put("complementReasons", why);
            m.put("reasons", r.reasons());
            if (r.passed()) { ok.add(m); fillsOf.put(u.id(), f); scoreOf.put(u.id(), r.score()); }
            else { m.put("blockedBy", r.blockedBy()); blocked.add(m); }
        }
        Comparator<Map<String, Object>> order = Comparator.<Map<String, Object>>comparingDouble(m -> -(double) m.get("score")).thenComparingInt(m -> (int) m.get("activeCases"));
        ok.sort(order); blocked.sort(order);
        int limit = req.limit() == null ? 8 : Math.max(1, Math.min(req.limit(), 30));

        // 3. 建議組合（貪婪）
        LinkedHashMap<Integer, List<Need>> ranked = new LinkedHashMap<>();
        for (var m : ok) ranked.put((int) m.get("userId"), fillsOf.get((int) m.get("userId")));
        List<Pick> picks = covered ? List.of() : suggest(gaps, ranked, ctx.seats());
        Set<Integer> filled = picks.stream().flatMap(p -> p.fills().stream()).map(Need::skillId).collect(Collectors.toSet());
        List<Need> remaining = gaps.stream().filter(n -> !filled.contains(n.skillId())).toList();

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("agent", "STUDENT");
        Map<String, Object> c = new LinkedHashMap<>();
        c.put("type", ctx.type()); c.put("id", ctx.id()); c.put("title", ctx.title()); c.put("startDate", ctx.start()); c.put("endDate", ctx.end());
        c.put("hoursPerWeek", ctx.hours()); c.put("seats", ctx.seats());
        out.put("context", c);
        out.put("team", ctx.team().stream().map(byId::get).filter(Objects::nonNull).map(u -> Map.of("userId", u.id(), "name", u.name(), "department", u.dept())).toList());
        out.put("coverage", cov.stream().map(x -> { Map<String, Object> m = new LinkedHashMap<>();
            m.put("skillId", x.need().skillId()); m.put("name", x.need().name()); m.put("importance", x.need().importance()); m.put("required", tier(x.need().minTier()));
            m.put("status", x.status().name()); m.put("best", x.bestTier() == 0 && x.status() == Status.MISSING ? null : tier(x.bestTier()));
            m.put("by", x.by().stream().map(byId::get).filter(Objects::nonNull).map(UserRow::name).toList()); return m; }).toList());
        out.put("gaps", cov.stream().filter(x -> x.status() != Status.MET)
                .map(x -> new SkillItem(x.need().skillId(), x.need().name(), x.need().core(), tier(x.need().minTier()), x.status() == Status.MISSING ? null : tier(x.bestTier()), null)).toList());
        out.put("candidates", ok.subList(0, Math.min(limit, ok.size())));
        out.put("totalCandidates", ok.size());
        out.put("blocked", blocked.subList(0, Math.min(5, blocked.size())));
        Map<String, Object> sug = new LinkedHashMap<>();
        sug.put("picks", picks.stream().map(p -> { UserRow u = byId.get(p.userId()); Map<String, Object> m = new LinkedHashMap<>();
            m.put("userId", u.id()); m.put("name", u.name()); m.put("department", u.dept()); m.put("score", scoreOf.get(u.id()));
            m.put("fills", p.fills().stream().map(Need::name).toList()); return m; }).toList());
        sug.put("remainingGaps", remaining.stream().map(Need::name).toList());
        sug.put("coveredAfter", ctx.needs().size() - remaining.size()); sug.put("total", ctx.needs().size());
        out.put("suggestedTeam", sug);
        out.put("trace", List.of(
                "組隊需求：「" + ctx.title() + "」" + ctx.needs().size() + " 項技能（核心 " + ctx.needs().stream().filter(Need::core).count() + "）",
                "現有成員 " + ctx.team().size() + " 人已涵蓋 " + (ctx.needs().size() - gaps.size()) + " 項 → 團隊缺口 " + gaps.size() + " 項" + (gaps.isEmpty() ? "" : "：" + String.join("、", gaps.stream().map(Need::name).toList())),
                "在 " + (users.size() - ctx.team().size()) + " 位學生中找出至少補上一項" + (covered ? "需求" : "缺口") + "的人：" + (ok.size() + blocked.size()) + " 位；通過時間與身分閘門 " + ok.size() + " 位",
                "用排序引擎評分（S 只看缺口技能 × 可信度係數，T 時間、R 評價、P 回應率、C 跨系互補）",
                covered ? "團隊已涵蓋全部需求，列出可加強的人選" : "建議組合：" + picks.size() + " 人，補齊後涵蓋 " + (ctx.needs().size() - remaining.size()) + "／" + ctx.needs().size() + " 項"
                        + (remaining.isEmpty() ? "" : "，仍缺 " + String.join("、", remaining.stream().map(Need::name).toList()))));
        return out;
    }

    private static SkillItem item(Need n, SkillSet sk) {
        return new SkillItem(n.skillId(), n.name(), n.core(), tier(n.minTier()), sk.score(n.skillId()) == 0 ? null : tier(sk.level(n.skillId())), sk.trust().get(n.skillId()));
    }
}
