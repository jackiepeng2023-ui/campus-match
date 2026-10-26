package tw.edu.fcu.campus.ranking;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class RecommendationController {
    private final RankingService ranking;

    public RecommendationController(RankingService ranking) { this.ranking = ranking; }

    /** M3：發案方看推薦人選（含被閘門擋下者與原因） */
    @GetMapping("/roles/{roleId}/recommendations")
    public Map<String, Object> forRole(@PathVariable int roleId) {
        return ranking.recommendForRole(roleId, Current.id(), Current.isAdmin());
    }

    /** M3：學生看推薦給我的案件 */
    @GetMapping("/me/recommended-cases")
    public List<Map<String, Object>> forMe() { return ranking.recommendCasesForUser(Current.id()); }
}
