#!/usr/bin/env python3
"""
競賽與教師參考資料：tools/data/*.json → src/main/resources/db/ref-competitions.sql、ref-teachers.sql

  python3 tools/ref_napai.py            # 轉換並檢查（技能名稱須存在於共用 Skill 資料庫、欄位長度、日期格式）
  python3 tools/ref_napai.py --check    # 只檢查，不寫檔

資料原則
- 競賽：只收官方簡章／官方網站可查證的資訊；每筆保留 source_url 與 checked_at（查證日）。日期以官方公告為準，系統只做提醒。
- 教師：只收逢甲大學系所網站「公開」的姓名、職稱、專長、研究方向、指導競賽經歷與頁面連結；不收 Email、電話、研究室等聯絡方式。
- 兩者的技能一律對到共用 Skill 資料庫（skills.name）；對不到的技能名稱會被擋下，不會默默略過。
產生的 SQL 可重複執行（ON CONFLICT DO NOTHING／NOT EXISTS），不會覆蓋管理員在後台修改過的資料。
"""
import datetime, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "..", "src", "main", "resources", "db")
DATA = os.path.join(HERE, "data")
CATEGORIES = {"資訊應用", "AI 與資料", "程式設計", "資安", "創新創業", "商管企劃", "設計", "工程實作", "土木建築", "語文", "跨域"}
LEVELS = {"CAMPUS", "NATIONAL", "INTERNATIONAL"}
DEGREES = {"BACHELOR", "MASTER", "PHD"}
CONTACT = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+|\(?0\d{1,2}\)?[-\s]?\d{3,4}[-\s]?\d{3,4}|分機\s*\d+|ext\.?\s*\d+", re.I)


def skill_names():
    sql = open(os.path.join(DB, "ref-base.sql"), encoding="utf-8").read()
    block = sql[sql.index("INSERT INTO skills"):sql.index("ON CONFLICT (name) DO NOTHING")]
    return {m.group(1) for m in re.finditer(r"\('([^']+)',\s*'[^']+'\)", block)}


def q(v):
    if v is None or v == "": return "NULL"
    if isinstance(v, bool): return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def qs(v):
    """NOT NULL DEFAULT '' 的文字欄位：空值寫成空字串"""
    return "''" if v in (None, "") else q(v)


def text(v, n):
    """去掉換行與多餘空白；超過長度則截斷並回報"""
    v = re.sub(r"\s+", " ", str(v or "")).strip()
    return v if len(v) <= n else v[: n - 1] + "…"


def date(v, where, errs):
    if v in (None, ""): return None
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(v)):
        errs.append(f"{where}：日期須為 YYYY-MM-DD（{v}）"); return None
    return v


def load(name):
    p = os.path.join(DATA, name)
    if not os.path.exists(p): return None
    d = json.load(open(p, encoding="utf-8"))
    return d if isinstance(d, list) else d.get("items") or d.get("competitions") or d.get("teachers") or []


def competitions(skills, errs, warns):
    rows = load("competitions.json")
    out = ["-- 競賽參考資料：由 tools/ref_napai.py 從 tools/data/competitions.json 產生；日期與資格以各競賽官方公告為準", "BEGIN;"]
    if rows is None:
        return out + ["-- （尚無資料：請放入 tools/data/competitions.json 後重新產生）", "COMMIT;"], 0
    links, seen = [], set()
    for c in rows:
        name = text(c.get("name"), 160)
        if not name or name in seen: errs.append(f"競賽名稱空白或重複：{name}"); continue
        seen.add(name)
        if c.get("category") not in CATEGORIES: errs.append(f"{name}：category 不在清單內（{c.get('category')}）")
        if c.get("level") not in LEVELS: errs.append(f"{name}：level 須為 CAMPUS／NATIONAL／INTERNATIONAL（{c.get('level')}）")
        deg = c.get("eligible_degrees") or ["BACHELOR", "MASTER", "PHD"]
        if isinstance(deg, str): deg = [d.strip() for d in deg.split(",") if d.strip()]
        if not set(deg) <= DEGREES: errs.append(f"{name}：eligible_degrees 不合法（{deg}）")
        if not c.get("source_url"): errs.append(f"{name}：缺 source_url（每筆都要能回查出處）")
        sk = c.get("skills") or []
        if not sk: errs.append(f"{name}：沒有對應技能")
        if not any(s.get("importance", "CORE") == "CORE" for s in sk): errs.append(f"{name}：至少要有一項 CORE 技能")
        for s in sk:
            if s.get("skill") not in skills: errs.append(f"{name}：技能不在 Skill 資料庫（{s.get('skill')}）"); continue
            tier = int(s.get("min_tier", s.get("min_level", 2)))
            if tier not in (1, 2, 3): errs.append(f"{name}：min_tier 須為 1–3（{tier}）"); continue
            links.append((name, s["skill"], tier, "SUPPORT" if s.get("importance") == "SUPPORT" else "CORE"))
        tmin, tmax = c.get("team_min"), c.get("team_max")
        if tmin and tmax and tmin > tmax: errs.append(f"{name}：team_min > team_max")
        if not c.get("apply_deadline"): warns.append(f"{name}：沒有報名截止日（只會出現在清單，不會進入「報名中」）")
        out.append(
            "INSERT INTO competitions (name, short_name, organizer, category, level, url, description, eligible_degrees, eligibility_note, "
            "team_min, team_max, advisor_required, apply_deadline, event_date, schedule_note, prize, source, source_url, checked_at) VALUES ("
            + ", ".join([q(name), q(text(c.get("short_name"), 60)), q(text(c.get("organizer"), 200)), q(c.get("category")), q(c.get("level")),
                         q(c.get("url")), qs(text(c.get("description"), 600)), q(",".join(deg)), qs(text(c.get("eligibility_note"), 300)),
                         q(tmin), q(tmax), q(c.get("advisor_required")), q(date(c.get("apply_deadline"), name, errs)), q(date(c.get("event_date"), name, errs)),
                         qs(text(c.get("schedule_note"), 200)), q(text(c.get("prize"), 300)), "'SEED'", q(c.get("source_url")),
                         q(date(c.get("checked_at"), name, errs))])
            + ") ON CONFLICT (name) DO NOTHING;")
    if links:
        out.append("INSERT INTO competition_skills (competition_id, skill_id, min_level, importance)\nSELECT c.id, s.id, v.t, v.i FROM (VALUES\n  "
                   + ",\n  ".join(f"({q(n)}, {q(s)}, {t}, {q(i)})" for n, s, t, i in links)
                   + "\n) AS v(c, s, t, i) JOIN competitions c ON c.name = v.c JOIN skills s ON s.name = v.s\nON CONFLICT DO NOTHING;")
    out.append("COMMIT;")
    return out, len(seen)


def teachers(skills, errs, warns):
    rows = load("teachers.json")
    path = os.path.join(DATA, "teachers.json")
    crawled = datetime.date.fromtimestamp(os.path.getmtime(path)).isoformat() if os.path.exists(path) else None      # 個別紀錄沒有擷取日時，用檔案日期
    out = ["-- 教師參考資料：由 tools/ref_napai.py 從 tools/data/teachers.json 產生；只含系所網站公開的姓名、職稱、專長、研究方向、指導經歷與來源連結", "BEGIN;"]
    if rows is None:
        return out + ["-- （尚無資料：請放入 tools/data/teachers.json 後重新產生）", "COMMIT;"], 0
    links, seen = [], set()
    for t in rows:
        name, dept = text(t.get("name"), 40), text(t.get("department"), 50)
        key = (name, dept)
        if not name or not dept or key in seen: errs.append(f"教師姓名／系所空白或重複：{key}"); continue
        seen.add(key)
        exp = t.get("expertise") or []
        exp = "、".join(x.strip() for x in exp if x and x.strip()) if isinstance(exp, list) else str(exp)
        research, coaching = text(t.get("research"), 600), text(t.get("coaching"), 600)
        for field, v in (("expertise", exp), ("research", research), ("coaching", coaching)):
            if CONTACT.search(v): errs.append(f"{name}：{field} 含聯絡方式（Email／電話／分機），不得收錄")
        if not t.get("source_url"): errs.append(f"{name}：缺 source_url")
        if not exp: warns.append(f"{name}（{dept}）：沒有專長文字")
        sk = [s for s in (t.get("skills") or []) if s.get("skill")]
        if not sk: warns.append(f"{name}（{dept}）：沒有對應到 Skill，不會被教師 Agent 推薦")
        for s in sk:
            if s["skill"] not in skills: errs.append(f"{name}：技能不在 Skill 資料庫（{s['skill']}）"); continue
            conf = float(s.get("confidence", 0.8))
            if not 0 < conf <= 1: errs.append(f"{name}：confidence 須介於 0–1（{conf}）"); continue
            links.append((name, dept, s["skill"], round(conf, 2)))
        out.append(
            "INSERT INTO teachers (name, title, department_id, expertise, research, coaching, profile_url, source_url, crawled_at)\n"
            f"SELECT {q(name)}, {q(text(t.get('title'), 60))}, d.id, {qs(text(exp, 1000))}, {qs(research)}, "
            f"{qs(coaching)}, {q(t.get('profile_url'))}, {q(t.get('source_url'))}, {q(date(t.get('crawled_at') or t.get('checked_at') or crawled, name, errs))}\n"
            f"FROM departments d WHERE d.name = {q(dept)} AND NOT EXISTS (SELECT 1 FROM teachers x WHERE x.name = {q(name)} AND x.department_id = d.id);")
    if links:
        out.append("INSERT INTO teacher_skills (teacher_id, skill_id, confidence, source)\nSELECT t.id, s.id, v.c, 'LLM' FROM (VALUES\n  "
                   + ",\n  ".join(f"({q(n)}, {q(d)}, {q(s)}, {c})" for n, d, s, c in links)
                   + "\n) AS v(n, d, s, c) JOIN departments d ON d.name = v.d JOIN teachers t ON t.name = v.n AND t.department_id = d.id JOIN skills s ON s.name = v.s\nON CONFLICT DO NOTHING;")
    out.append("COMMIT;")
    return out, len(seen)


def syllabi(errs, warns):
    """課綱節錄（tools/fcu_syllabus.py batch 的輸出）→ ref-syllabus.sql：示範與離線時不必連到學校網站；只存節錄（≤ 1,500 字）與來源連結"""
    p = os.path.join(DATA, "syllabus_samples.json")
    out = ["-- 課綱節錄：由 tools/ref_napai.py 從 tools/data/syllabus_samples.json 產生（來源：逢甲大學課程檢索系統＋教學大綱查詢，公開頁面）", "BEGIN;"]
    if not os.path.exists(p): return out + ["COMMIT;"], 0
    n = 0
    for r in json.load(open(p, encoding="utf-8")).get("results", []):
        if r.get("status") != "ok": continue
        s = r["syllabus"]
        parts = [("課程描述", s.get("description")), ("課程目標", "；".join(s.get("objectives") or [])), ("核心能力", "；".join(s.get("core_abilities") or [])),
                 ("學習工具", "、".join(s.get("tools") or [])), ("授課進度", "；".join((w.get("topic") or "").replace("\n", " ") for w in s.get("weekly") or [] if w.get("topic")))]
        body = "\n".join(f"【{k}】{v}" for k, v in parts if v)
        if CONTACT.search(body): errs.append(f"課綱 {r['course']}：含聯絡方式"); continue
        body = body if len(body) <= 1500 else body[:1499] + "…"
        out.append(f"INSERT INTO course_syllabus (course_name, department, year, sms, text, source_url) VALUES ({q(r['course'])}, NULL, {int(r['year'])}, {int(r['sms'])}, {q(body)}, {q(r['source_url'])}) "
                   f"ON CONFLICT (course_name, department) DO NOTHING;")
        n += 1
    out.append("COMMIT;")
    return out, n


def main():
    check = "--check" in sys.argv
    skills, errs, warns = skill_names(), [], []
    comp, nc = competitions(skills, errs, warns)
    teach, nt = teachers(skills, errs, warns)
    syl, ns = syllabi(errs, warns)
    for w in warns: print("WARN ", w)
    for e in errs: print("ERROR", e)
    print(f"skills {len(skills)}｜competitions {nc}｜teachers {nt}｜syllabi {ns}｜errors {len(errs)}｜warnings {len(warns)}")
    if errs: sys.exit(1)
    if check: return
    for name, lines in (("ref-competitions.sql", comp), ("ref-teachers.sql", teach), ("ref-syllabus.sql", syl)):
        with open(os.path.join(DB, name), "w", encoding="utf-8") as f: f.write("\n".join(lines) + "\n")
        print("wrote", name, len(lines), "lines")


if __name__ == "__main__":
    main()
