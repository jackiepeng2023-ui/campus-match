package tw.edu.fcu.campus.review;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.Current;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class ReviewController {
    private final ReviewService svc;

    public ReviewController(ReviewService svc) { this.svc = svc; }

    @PostMapping("/cases/{id}/close-requests") public Map<String, Object> close(@PathVariable int id, @RequestBody ReviewService.CloseIn in) { return svc.requestClose(id, Current.id(), in); }
    @PostMapping("/close-requests/{id}/votes") public Map<String, Object> vote(@PathVariable int id, @RequestBody ReviewService.VoteIn in) { return svc.vote(id, Current.id(), in); }
    @GetMapping("/cases/{id}/reviews/pending") public Map<String, Object> pending(@PathVariable int id) { return svc.pending(id, Current.id()); }
    @PostMapping("/cases/{id}/reviews") public Map<String, Object> submit(@PathVariable int id, @RequestBody List<ReviewService.ReviewIn> in) { return svc.submit(id, Current.id(), in); }
    @GetMapping("/me/reviews") public Map<String, Object> received() { return svc.received(Current.id()); }
}
