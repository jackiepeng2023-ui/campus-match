package tw.edu.fcu.campus.llm;

import org.springframework.web.bind.annotation.*;
import tw.edu.fcu.campus.common.ApiException;
import tw.edu.fcu.campus.common.Current;
import tw.edu.fcu.campus.common.Db;

import java.util.Map;

/** AI 擷取的管理端 API：課綱 → 技能、競賽簡章 → 草稿；結果都要經過信心門檻或管理員核准才生效 */
@RestController
@RequestMapping("/api/v1/admin/extract")
public class ExtractController {
    private final ExtractService extract;
    private final ClaudeClient claude;
    private final SyllabusClient syllabus;
    private final Db db;

    public ExtractController(ExtractService extract, ClaudeClient claude, SyllabusClient syllabus, Db db) { this.extract = extract; this.claude = claude; this.syllabus = syllabus; this.db = db; }

    @GetMapping("/status")
    public Map<String, Object> status() {
        return Map.of("llmEnabled", claude.enabled(), "model", claude.fastModel(), "syllabusFetch", syllabus.enabled(),
                "cachedSyllabi", db.count("SELECT count(*) FROM course_syllabus"), "llmMappings", db.count("SELECT count(*) FROM course_skill_map WHERE source = 'LLM'"));
    }

    public record CourseIn(Integer courseId) {}
    /** 擷取這門課的課綱並對照技能（已有的對照不會被覆蓋） */
    @PostMapping("/course-skills")
    public Map<String, Object> course(@RequestBody CourseIn in) {
        if (in.courseId() == null) throw ApiException.badRequest("courseId 為必填");
        return extract.mapCourse(in.courseId(), null);
    }

    public record CompetitionIn(String text, String sourceUrl) {}
    /** 貼上簡章文字 → 未核准的競賽草稿 */
    @PostMapping("/competition")
    public Map<String, Object> competition(@RequestBody CompetitionIn in) { return extract.draftCompetition(in.text(), in.sourceUrl(), Current.id()); }
}
