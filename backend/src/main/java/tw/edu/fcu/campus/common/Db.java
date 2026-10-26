package tw.edu.fcu.campus.common;

import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

/** 薄封裝：具名參數以 (name, value, name, value…) 傳入；查詢結果以 Map 直接回傳給 JSON */
@Component
public class Db {
    public final NamedParameterJdbcTemplate jdbc;

    public Db(NamedParameterJdbcTemplate jdbc) { this.jdbc = jdbc; }

    public static MapSqlParameterSource params(Object... kv) {
        MapSqlParameterSource p = new MapSqlParameterSource();
        for (int i = 0; i < kv.length; i += 2) p.addValue((String) kv[i], kv[i + 1]);
        return p;
    }

    public List<Map<String, Object>> list(String sql, Object... kv) { return jdbc.queryForList(sql, params(kv)); }

    public Map<String, Object> one(String sql, Object... kv) {
        List<Map<String, Object>> rows = jdbc.queryForList(sql, params(kv));
        return rows.isEmpty() ? null : rows.get(0);
    }

    public Map<String, Object> required(String sql, String notFoundMessage, Object... kv) {
        Map<String, Object> row = one(sql, kv);
        if (row == null) throw ApiException.notFound(notFoundMessage);
        return row;
    }

    public <T> T scalar(Class<T> type, String sql, Object... kv) {
        List<T> rows = jdbc.queryForList(sql, params(kv), type);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public int count(String sql, Object... kv) {
        Integer n = scalar(Integer.class, sql, kv);
        return n == null ? 0 : n;
    }

    public int exec(String sql, Object... kv) { return jdbc.update(sql, params(kv)); }

    public int insertReturningId(String sql, Object... kv) { return jdbc.queryForObject(sql, params(kv), Integer.class); }

    /** Instant → timestamptz 參數 */
    public static OffsetDateTime ts(Instant i) { return i == null ? null : OffsetDateTime.ofInstant(i, ZoneOffset.UTC); }

    public static Instant instant(Object v) {
        if (v == null) return null;
        if (v instanceof Timestamp t) return t.toInstant();
        if (v instanceof OffsetDateTime o) return o.toInstant();
        if (v instanceof Instant i) return i;
        throw new IllegalArgumentException("not a timestamp: " + v.getClass());
    }

    public static int i(Object v) { return ((Number) v).intValue(); }

    public static double d(Object v) { return v == null ? 0 : ((Number) v).doubleValue(); }
}
