package tw.edu.fcu.campus.config;

import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;

/** 全系統唯一時鐘；Demo 時可快轉，讓逾時、提醒、自動結案現場可見（D20、D24、D34） */
@Component
public class DemoClock extends Clock {
    private volatile Duration offset = Duration.ZERO;
    private final ZoneId zone = ZoneId.of("Asia/Taipei");

    public void advance(Duration d) { offset = offset.plus(d); }
    public void reset() { offset = Duration.ZERO; }
    public Duration offset() { return offset; }

    @Override public ZoneId getZone() { return zone; }
    @Override public Clock withZone(ZoneId z) { return this; }
    @Override public Instant instant() { return Instant.now().plus(offset); }
}
