package tw.edu.fcu.campus.cases;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class CaseController {
    private final CaseService cases;

    public CaseController(CaseService cases) { this.cases = cases; }

    @PostMapping("/cases") public Map<String, Object> create(@RequestBody CaseService.CaseIn in) { return cases.create(Current.id(), in); }
    @PutMapping("/cases/{id}") public Map<String, Object> update(@PathVariable int id, @RequestBody CaseService.CaseIn in) { return cases.update(id, Current.id(), in); }

    @GetMapping("/cases")
    public List<Map<String, Object>> list(@RequestParam(required = false) String status, @RequestParam(required = false) String type,
                                          @RequestParam(required = false) Integer skillId, @RequestParam(required = false) String q,
                                          @RequestParam(defaultValue = "false") boolean mine, @RequestParam(defaultValue = "false") boolean member) {
        return cases.list(Current.id(), status, type, skillId, q, mine, member);
    }

    @GetMapping("/cases/{id}") public Map<String, Object> detail(@PathVariable int id) { return cases.detail(id, Current.id(), Current.isAdmin()); }
    @PostMapping("/cases/{id}/publish") public Map<String, Object> publish(@PathVariable int id) { return cases.publish(id, Current.id()); }
    @PostMapping("/cases/{id}/cancel") public Map<String, Object> cancel(@PathVariable int id) { return cases.cancel(id, Current.id()); }
    @PostMapping("/cases/{id}/start") public Map<String, Object> start(@PathVariable int id) { return cases.start(id, Current.id()); }
    @GetMapping("/cases/{id}/engagements") public List<Map<String, Object>> engagements(@PathVariable int id) {
        cases.detail(id, Current.id(), Current.isAdmin());
        return cases.engagementsOfCase(id);
    }

    @PostMapping("/roles/{roleId}/engagements")
    public Map<String, Object> engage(@PathVariable int roleId, @RequestBody CaseService.EngagementIn in) { return cases.createEngagement(roleId, Current.id(), in); }

    @GetMapping("/me/engagements") public List<Map<String, Object>> mine() { return cases.myEngagements(Current.id()); }
    @PostMapping("/engagements/{id}/accept") public Map<String, Object> accept(@PathVariable int id) { return cases.accept(id, Current.id()); }
    @PostMapping("/engagements/{id}/decline") public Map<String, Object> decline(@PathVariable int id) { return cases.decline(id, Current.id()); }
    @PostMapping("/engagements/{id}/withdraw") public Map<String, Object> withdraw(@PathVariable int id) { return cases.withdraw(id, Current.id()); }
}
