#!/usr/bin/env python3
"""
逢甲大學課綱（教學大綱）擷取工具：由公開的「課程檢索系統」找出開課，再向「教學大綱查詢〈W320104〉」取課綱 JSON。
不需登入；只用 Python 標準函式庫。

用法：
  python3 fcu_syllabus.py search --year 115 --sms 1 --name 資料結構 [--dept 資訊] [--code IECS2001]
      列出科目名稱含關鍵字的開課（JSON 陣列，最符合的在前）；結束碼 0=有結果、1=沒有、2=錯誤
  python3 fcu_syllabus.py fetch  --year 115 --sms 1 --name 資料結構 [--dept 資訊] [--code IECS2001] [--fallback 114-2,114-1]
      取最符合的那一班的課綱（JSON 物件）；結束碼 0=ok、1=not_found、2=error
  python3 fcu_syllabus.py batch  --year 115 --sms 1 --input names.txt --out out.json [--fallback 114-2,114-1]
      names.txt 每行「科目名稱[<TAB>系所關鍵字[<TAB>課程編碼]]」，# 開頭為註解；逐科輸出 status = ok / not_found / error

  --year     民國學年度（115 = 2026–27）；--sms 1 = 上學期、2 = 下學期（3、4 = 暑修）。
  --name     科目名稱關鍵字，至少 2 個字；站方以子字串比對（英文字母不分大小寫）。
  --dept     開課班級關鍵字：檢索系統的班級簡稱（資訊、企管）或系所全名（資訊工程學系，會以縮寫規則對到「資訊二甲」）。
  --code     課程編碼（站方的 sub_id3，例 IECS2001；正式科目表 courses.csv 的 code 欄就是它），有給就優先選同編碼的開課。
  --fallback 指定學期沒有「同名」或「同名加(一)(二)」的開課（或指定的系所／編碼對不上）時，依序加查這些學期；
             名稱符合程度相同時仍以指定學期優先。
  --interval 兩個請求的最短間隔秒數，預設 0.6、下限 0.5。

輸出：
  search → [{course 科目名稱, course_code 課程編碼, department 開課班級, class_id, credits, required 必選修, year, sms,
             selcode 選課代號, course_id（學年+學期+選課代號，教學大綱的識別碼）, source_url 教學大綱網址, match}]
  fetch  → {status, query, match, candidates, course, course_en, course_code, department, class_id, credits, required, year, sms,
            selcode, source_url, alternatives（其他課名的候選）,
            syllabus: {description 課程描述, description_en, topic 探究主題, prerequisites 前置課程, objectives[] 課程目標,
                       core_abilities[] 基本／核心能力, textbooks[], tools[] 學習工具, weekly[{week, topic, activity}] 授課進度,
                       grading[], empty, raw_text（整理後的純文字，≤ 4000 字）}}
            找不到：{status: "not_found", reason: "no_offering" 沒有開課 | "no_syllabus" 有開課但查無課綱, message}
            失敗：{status: "error", message}（站方拒絕時另有 blocked: true）
  batch  → {generated_at, source, year, sms, fallback, requests, summary, aborted, results: [每科一筆，格式同 fetch]}
  match：exact 同名、numbered 同名加(一)(二)、affix 以關鍵字開頭或結尾、contains 僅包含。不輸出教師姓名、email、電話。

使用的端點（2026-11-11 實測，皆可匿名存取）：
  1. GET  https://coursesearch.fcu.edu.tw/
       分流入口：回傳 meta refresh → https://coursesearch0N.fcu.edu.tw/main.aspx?token=<1 小時有效的 JWT>（實測被指派過 01、02）。
       本工具照瀏覽器流程走一次，之後只打被指派的節點（分流主機自己的 /Service/* 會回 401）。
  2. POST https://coursesearch0N.fcu.edu.tw/Service/Search.asmx/GetType2Result
       標頭 Content-Type: application/json; charset=utf-8（實測不需 cookie、token 或 Referer）
       本文 {"baseOptions":{"lang":"cht","year":115,"sms":1},
             "typeOptions":{"course":{"enabled":true,"value":"資料結構"}, …其餘條件 enabled:false，見 TYPE2_OPTIONS}}
       回傳 {"message":"","total":N,"items":[{scr_selcode 選課代號, sub_id3 課程編碼, sub_name 科目名稱, cls_name 開課班級,
             cls_id, scr_credit 學分, scj_scr_mso 必選修, scr_teacher, scr_period, …}]}
       一次回傳全部結果、不分頁（「英文」229 筆；單一個「學」字 1,093 筆約 530 KB，所以本工具要求至少 2 個字）。
  3. GET  https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx?courseid=<學年><學期><選課代號>&lang=cht
       （檢索結果的課名連結 /CourseOutline.aspx?lang=cht&courseid=… 會 302 到這個網址）
       回傳 302：Location 帶 ?token=<JWT>（payload 的 user 為 "public"，約 3 小時有效）；查無此課時轉到 view/noCourse.html。
  4. POST https://ilearntools.fcu.edu.tw/W320104/W320104_syllabus.aspx/GetCourseDetail
       本文 {"access_token":"<上一步的 token>"}（實測不需 cookie；token 無效時回 401）
       回傳課綱 JSON：info（開課資訊）、description（課程描述、前置課程）、targets（課程目標）、weeklyScds（授課進度）、
       textBooks、readings、iSoftwares、assistSoftwares、gradeRules、courseBankC（核心能力對應）、topicSdgs、topicAiIndicators …
       另有 teachersInfo（教師與助教的 email、分機）——本工具不讀取、不輸出，自由文字中的 email／電話也會遮蔽。

觀察到的限制：
  - 兩台主機都沒有 robots.txt（coursesearch 會 302 回首頁、ilearntools 回 404），也沒看到針對自動化存取的使用條款；
    檢索系統頁尾標示「系統內之所有內容及版面設計－著作權屬逢甲大學」。建議大量擷取或對外公開課綱內容前，先徵得教務處同意。
  - 回應帶 FCU_WAF cookie（站方應有 WAF）；實測約 1 req/s、單次 batch 65 個請求未被限速或封鎖，更高的頻率沒有測。
    本工具每 0.6 秒最多送一個請求（< 2 req/s），逾時與 5xx 以退避重試、最多 3 次；遇到 401／403／429、被導向登入、
    或 API 回了非 JSON（可能是封鎖或驗證頁）就立即中止並回報，不會嘗試繞過。batch 連續 3 科失敗也會中止。
  - 課綱頁的「列印本頁」PDF（DownloadPdf）依頁面程式是登入後才能用的功能，本工具不使用。
  - 檢索系統只有 107 學年度以後的開課。課程描述與課程目標是科目層級的資料，授課進度由各班教師填寫，可能空白，
    各班內容也可能不同：最符合的那班沒填授課進度時，會改試同學期同課名的其他班（最多 3 班），取內容最完整者。
  - 只給科目名稱時常有多個同名或近似的開課（不同系、不同編碼），本工具取「開最多班」的那個課名；要對到特定系所請給 --dept 或 --code。
"""
import argparse, datetime, html, http.client, http.cookiejar, json, os, re, ssl, sys, time, unicodedata
import urllib.error, urllib.parse, urllib.request

ENTRY_URL = "https://coursesearch.fcu.edu.tw/"
NODE_RE = re.compile(r"url=(https://coursesearch\d+\.fcu\.edu\.tw)(/main\.aspx\?token=[\w.\-]+)")
SEARCH_PATH = "/Service/Search.asmx/GetType2Result"
SYLLABUS_PAGE = "https://ilearntools.fcu.edu.tw/W320104/W320104_SyllabusFullVer.aspx"
SYLLABUS_API = "https://ilearntools.fcu.edu.tw/W320104/W320104_syllabus.aspx/GetCourseDetail"
UA = "Mozilla/5.0 (campus-match syllabus importer)"
MIN_INTERVAL = 0.6      # 兩個請求的最短間隔（秒）
TIMEOUT = 30            # 單一請求逾時（秒）
RETRIES = 3             # 逾時／連線錯誤／5xx 的嘗試次數
MAX_TRIES = 3           # 授課進度沒填時，同一科最多試幾個班
MAX_ERRORS = 3          # batch 連續幾科失敗就中止
RAW_LIMIT = 4000        # raw_text 字數上限
# 檢索頁「依輸入條件查詢」的全部條件；只啟用 course（科目名稱）
TYPE2_OPTIONS = {"code": {"enabled": False, "value": ""}, "weekPeriod": {"enabled": False, "week": "*", "period": "*"},
                 "course": {"enabled": False, "value": ""}, "teacher": {"enabled": False, "value": ""},
                 "useEnglish": {"enabled": False}, "useLanguage": {"enabled": False, "value": "01"},
                 "specificSubject": {"enabled": False, "value": "1"}, "courseDescription": {"enabled": False, "value": ""}}
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+\s*[@＠]\s*[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+")
PHONE_RE = re.compile(r"09\d{2}[-\s]?\d{3}[-\s]?\d{3}|\(?0\d{1,2}\)?[-\s]\d{3,4}[-\s]?\d{4}|(?:分機|ext\.?)\s*[:：]?\s*\d{3,5}", re.I)
GRADE_RE = re.compile(r"(?:進修|碩專|專碩|碩|博)?[一二三四五六]")     # 班級名稱中的年級：資訊二甲、企管碩一、人工智慧二學位學程


class Blocked(RuntimeError):
    """站方拒絕（401／403／429）或回了非預期內容：停止，不重試、不繞過"""


# ---------- HTTP ----------
def ssl_context():
    """沿用 SSL_CERT_FILE（若有設定）；只關閉 Python 3.13 預設的 X509_STRICT（企業代理 CA 常缺 SKI），憑證鏈仍完整驗證"""
    ctx = ssl.create_default_context(cafile=os.environ.get("SSL_CERT_FILE") or None)
    ctx.verify_flags &= ~getattr(ssl, "VERIFY_X509_STRICT", 0)
    return ctx


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None     # 不自動跟隨：教學大綱頁把公開 token 放在 302 的 Location，由呼叫端讀取


class Http:
    """限速＋重試的小型 HTTP 用戶端（帶 cookie，行為同一般瀏覽器工作階段）"""

    def __init__(self, interval=MIN_INTERVAL):
        self.interval, self.last, self.count = max(interval, 0.5), 0.0, 0
        self.opener = urllib.request.build_opener(urllib.request.HTTPSHandler(context=ssl_context()),
                                                  urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()), _NoRedirect())

    def send(self, url, payload=None, referer=None):
        """GET（payload=None）或 JSON POST；回傳 (status, headers, text)"""
        headers = {"User-Agent": UA, "Accept": "application/json, text/html;q=0.9, */*;q=0.8"}
        data = None
        if payload is not None:
            data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            headers["Content-Type"] = "application/json; charset=utf-8"
        if referer:
            headers["Referer"] = referer
        error = None
        for attempt in range(1, RETRIES + 1):
            time.sleep(max(0.0, self.last + self.interval - time.monotonic()))
            self.last, self.count = time.monotonic(), self.count + 1
            try:
                with self.opener.open(urllib.request.Request(url, data=data, headers=headers), timeout=TIMEOUT) as r:
                    status, hdrs, body = r.status, r.headers, r.read()
            except urllib.error.HTTPError as e:                     # 3xx（未跟隨）、4xx、5xx
                status, hdrs, body = e.code, e.headers, e.read()
            except (OSError, http.client.HTTPException) as e:       # 逾時、連線中斷（URLError 也是 OSError）
                error = e
                time.sleep(2 * attempt)
                continue
            if status in (401, 403, 429):
                raise Blocked(f"HTTP {status}：{url.split('?')[0]}")
            if status >= 500:
                error = RuntimeError(f"HTTP {status}")
                time.sleep(2 * attempt)
                continue
            return status, hdrs, body.decode("utf-8", "replace")
        raise RuntimeError(f"{url.split('?')[0]} 連續 {RETRIES} 次失敗：{error}")

    def post_json(self, url, payload, referer=None):
        status, _, text = self.send(url, payload, referer)
        try:
            data = json.loads(text)
        except ValueError:
            raise Blocked(f"HTTP {status}，預期 JSON 卻收到其他內容（可能是封鎖／驗證頁）：{url}") from None
        data = data.get("d", data) if isinstance(data, dict) else data      # ASP.NET 可能包一層 {"d": …}
        return json.loads(data) if isinstance(data, str) else data


# ---------- 比對 ----------
def norm(s):
    return re.sub(r"\s+", "", unicodedata.normalize("NFKC", s or "")).lower()


def name_match(query, name):
    """(分數, 標籤)：exact 同名 > numbered 同名加(一)(二) > affix 開頭或結尾 > contains 包含"""
    q, n = norm(query), norm(name)
    if n == q:
        return 4, "exact"
    if re.fullmatch(re.escape(q) + r"\(?[一二三四五六上下1-6iv]+\)?", n):
        return 3, "numbered"
    if n.startswith(q) or n.endswith(q):
        return 2, "affix"
    return (1, "contains") if q in n else (0, "none")


def dept_match(keyword, cls_name):
    """2 = 關鍵字出現在開課班級名；1 = 班級簡稱是關鍵字（系所全名）的縮寫，例 資訊二甲 ↔ 資訊工程學系；0 = 不符"""
    kw, cls = norm(keyword), norm(cls_name)
    if not kw:
        return 0
    if kw in cls:
        return 2
    stem = GRADE_RE.split(cls, maxsplit=1)[0]       # 資訊二甲 → 資訊；人工智慧二學位學程 → 人工智慧
    chars = iter(kw)
    return 1 if len(stem) >= 2 and stem[0] == kw[0] and all(c in chars for c in stem) else 0


def rank(offerings, name, dept=None, code=None):
    """把開課依符合程度排序（最符合的在前），名稱不含關鍵字者剔除；回傳的每筆多一個 match 標籤。
    排序鍵由重到輕：課程編碼相符 > 名稱為 exact/numbered > 系所相符 > affix 先於 contains > 學期（依傳入順序）
    > 同名開課班數（開最多班的視為主流版本，例 微積分 → 微積分(一)）> exact 先於 numbered > 有學分 > 大學部一般班級"""
    terms, classes, matched = [], {}, []
    for o in offerings:
        score, label = name_match(name, o["course"])
        if score:
            term = (o["year"], o["sms"])
            if term not in terms:
                terms.append(term)
            classes[term, o["course"]] = classes.get((term, o["course"]), 0) + 1
            matched.append((score, term, dict(o, match=label)))
    ranked = []
    for score, term, o in matched:
        prefer = (bool(code) and norm(code) == norm(o["course_code"]), score >= 3, dept_match(dept, o["department"]), min(score, 3),
                  -terms.index(term), classes[term, o["course"]], score, (o["credits"] or 0) > 0,
                  bool(re.match(r"....1[1-6]", o["class_id"])))            # class_id 第 5 碼 1 = 大學部，第 6 碼 = 年級
        ranked.append((tuple(-int(p) for p in prefer), o["course"], o["class_id"], o["selcode"], o))
    return [r[-1] for r in sorted(ranked, key=lambda r: r[:-1])]


def satisfied(top, dept=None, code=None):
    """最佳候選已經夠好（名稱 exact/numbered，且有指定系所／編碼時也相符）→ 不必再查備援學期"""
    return (top["match"] in ("exact", "numbered") and (not dept or dept_match(dept, top["department"]) > 0)
            and (not code or norm(code) == norm(top["course_code"])))


# ---------- 課綱整理 ----------
def clean(value):
    """HTML → 純文字：區塊標籤換行、去標籤、還原實體、收斂空白，並遮蔽 email／電話"""
    s = re.sub(r"(?i)<\s*(?:br|/p|/div|/li|/tr|/h\d)\b[^>]*>", "\n", str(value or ""))
    s = html.unescape(re.sub(r"</?[A-Za-z][^>]*>", "", s)).replace("\xa0", " ")
    s = PHONE_RE.sub("[電話]", EMAIL_RE.sub("[email]", s))
    lines = (re.sub(r"[ \t\r\f\v]+", " ", line).strip() for line in s.split("\n"))
    return "\n".join(line for line in lines if line)


def week_line(w):
    """授課進度的一列 → 一行文字"""
    return (f"[{w['week']}] {w['topic']}" + (f" ／{w['activity']}" if w["activity"] else "")).replace("\n", " ")


def parse_syllabus(d):
    """GetCourseDetail 的 JSON → 精簡課綱（不含教師個資、學術誠信與課堂規則等制式文字）"""
    info, desc = d.get("info") or {}, d.get("description") or {}
    sub = d.get("subTitleDesc") or {}
    weekly = []
    for w in d.get("weeklyScds") or []:
        acts = [clean(w.get(k)) for k in ("tpd_learn", "tpd_in", "tpd_rtime", "tpd_sync", "tpd_ass")]
        row = {"week": clean(w.get("tpd_week")), "topic": clean(w.get("tpd_reading")), "activity": "；".join(a for a in acts if a)}
        if row["topic"] or row["activity"]:
            weekly.append(row)
    tools = [" ".join(x for x in (clean(t.get("soft_name")), clean(t.get("soft_memo"))) if x)
             for t in (d.get("iSoftwares") or []) + (d.get("assistSoftwares") or [])]
    core = []
    for c in d.get("courseBankC") or []:
        item = clean(c.get("core_item"))
        if item and item not in core:
            core.append(item)
    s = {
        "description": clean(desc.get("describe_ch")),
        "description_en": clean(desc.get("describe_eh")),
        "topic": "：".join(x for x in (clean(sub.get("sub_title")), clean(sub.get("sub_describe"))) if x),
        "prerequisites": clean(desc.get("pre_subname")),
        "objectives": [t for t in (clean(x.get("describe_ch")) for x in d.get("targets") or []) if t],
        "core_abilities": core,
        "textbooks": [t for t in (clean((d.get("textBooks") or {}).get("tpb_book")), clean((d.get("readings") or {}).get("tpc_book"))) if t],
        "tools": [t for t in tools if t],
        "weekly": weekly,
        "grading": [f"{clean(g.get('evalb_name'))} {g.get('score_rate') or 0}%" for g in d.get("gradeRules") or [] if clean(g.get("evalb_name"))],
    }
    s["textbooks"] = list(dict.fromkeys(s["textbooks"]))        # 教科書與閱讀教材常填同一段
    s["empty"] = not (s["description"] or s["topic"] or s["objectives"] or s["weekly"])
    credit = info.get("scr_credit")
    head = (f"{clean(info.get('sub_name'))} {clean(info.get('sub_ename'))}（{clean(info.get('sub_id3'))}，"
            f"{credit if not isinstance(credit, float) else format(credit, 'g')} 學分，{clean(info.get('scr_mso'))}，{clean(info.get('cls_name'))}）")
    parts = [("課程", head), ("課程描述", s["description"]), ("探究主題", s["topic"]), ("前置課程", s["prerequisites"]),
             ("課程目標", "\n".join(f"{i}. {t}" for i, t in enumerate(s["objectives"], 1))),
             ("基本／核心能力", "；".join(core)), ("教材", "\n".join(s["textbooks"])), ("學習工具", "、".join(s["tools"])),
             ("授課進度", "\n".join(week_line(w) for w in weekly)), ("評分", "、".join(s["grading"]))]
    raw = "\n".join(f"【{label}】{text}" for label, text in parts if text)
    s["raw_text"] = raw if len(raw) <= RAW_LIMIT else raw[:RAW_LIMIT - 1] + "…"
    return s


def richness(syllabus):
    """課綱完整度：0 查無資料、1 空白、2 只有課程描述／目標、3 另有授課進度"""
    return 0 if syllabus is None else 1 + (not syllabus["empty"]) + bool(syllabus["weekly"])


# ---------- 站台存取 ----------
class Fcu:
    def __init__(self, interval=MIN_INTERVAL):
        self.http, self.host, self.cache = Http(interval), None, {}

    def node(self):
        """走公開入口取得被指派的檢索節點（每次執行只做一次）"""
        if not self.host:
            _, _, page = self.http.send(ENTRY_URL)
            m = NODE_RE.search(page)
            if not m:
                raise Blocked("課程檢索入口沒有指派節點（站方流程改變或管制中）")
            self.host = m.group(1)
            self.http.send(m.group(1) + m.group(2), referer=ENTRY_URL)
        return self.host

    def search(self, year, sms, name):
        """科目名稱子字串查詢 → 開課清單（未排序）"""
        if len(norm(name)) < 2:
            raise ValueError("科目名稱至少要 2 個字（單字查詢會讓站方一次回傳上千筆）")
        key = ("search", year, sms, name)
        if key not in self.cache:
            body = {"baseOptions": {"lang": "cht", "year": year, "sms": sms},
                    "typeOptions": dict(TYPE2_OPTIONS, course={"enabled": True, "value": name})}
            host = self.node()
            data = self.http.post_json(host + SEARCH_PATH, body, referer=host + "/main.aspx")
            self.cache[key] = [{
                "course": (it.get("sub_name") or "").strip(), "course_code": (it.get("sub_id3") or "").strip(),
                "department": (it.get("cls_name") or "").strip(), "class_id": (it.get("cls_id") or "").strip(),
                "credits": it.get("scr_credit"), "required": (it.get("scj_scr_mso") or "").strip(),
                "year": year, "sms": sms, "selcode": it["scr_selcode"], "course_id": f"{year}{sms}{it['scr_selcode']}",
                "source_url": f"{SYLLABUS_PAGE}?courseid={year}{sms}{it['scr_selcode']}&lang=cht",
            } for it in (data.get("items") or [])]
        return self.cache[key]

    def syllabus(self, offering):
        """取一個開課的課綱：先拿公開 token，再呼叫 GetCourseDetail；回傳 (課綱, 英文課名)，教學大綱系統查無此課時回傳 (None, "")"""
        key = ("syllabus", offering["course_id"])
        if key not in self.cache:
            status, headers, _ = self.http.send(offering["source_url"])
            location = headers.get("Location") or ""
            token = urllib.parse.parse_qs(urllib.parse.urlsplit(location).query).get("token")
            if token:
                data = self.http.post_json(SYLLABUS_API, {"access_token": token[0]}, referer=SYLLABUS_PAGE)
                if not data.get("success"):
                    raise RuntimeError(f"GetCourseDetail 回報失敗：{offering['source_url']}")
                self.cache[key] = (parse_syllabus(data), clean((data.get("info") or {}).get("sub_ename")))
            elif status == 302 and "noCourse" in location:       # 站方的「查無課程」頁
                self.cache[key] = (None, "")
            elif status == 302:
                raise Blocked(f"教學大綱頁轉往 {location.split('?')[0]} 而未發出公開 token（可能改為需登入）")
            else:
                raise RuntimeError(f"教學大綱頁回 HTTP {status}，沒有公開 token：{offering['source_url']}")
        return self.cache[key]

    def lookup(self, year, sms, name, dept=None, code=None, fallback=()):
        """找最符合的開課並取課綱；回傳 status 為 ok / not_found 的結果（錯誤以例外拋出）"""
        pool, best, searched = [], [], []
        for y, s in [(year, sms)] + list(fallback):
            pool += self.search(y, s, name)
            searched.append(f"{y}-{s}")
            best = rank(pool, name, dept, code)
            if best and satisfied(best[0], dept, code):
                break
        query = {"name": name, "dept": dept, "code": code, "searched": searched}
        if not best:
            return {"status": "not_found", "reason": "no_offering", "query": query,
                    "message": f"{'、'.join(searched)} 沒有科目名稱含「{name}」的開課"}
        # 授課進度由各班教師自行填寫：最符合的那班沒填時，改試同學期、同課名的其他班（最多 MAX_TRIES 班），取內容最完整者
        same = {}                                                               # course_id → 開課（合班課只算一次）
        for o in best:
            if (o["course"], o["year"], o["sms"]) == (best[0]["course"], best[0]["year"], best[0]["sms"]):
                same.setdefault(o["course_id"], o)
        tried = []
        for o in list(same.values())[:MAX_TRIES]:
            tried.append(o)
            if (self.syllabus(o)[0] or {}).get("weekly"):
                break
        offering = max(tried, key=lambda o: richness(self.syllabus(o)[0]))      # 同分取排序較前者
        syllabus, name_en = self.syllabus(offering)
        others = {}                                                             # 其他課名的候選（各取最符合的一班），供人工或 LLM 判斷
        for o in best:
            if o["course"] != offering["course"]:
                others.setdefault(o["course"], {k: o[k] for k in ("course", "course_code", "department", "year", "sms", "selcode", "match")})
        result = {"status": "ok", "query": query, "match": offering["match"], "candidates": len(best),
                  "course": offering["course"], "course_en": name_en, "course_code": offering["course_code"],
                  "department": offering["department"], "class_id": offering["class_id"], "credits": offering["credits"],
                  "required": offering["required"], "year": offering["year"], "sms": offering["sms"],
                  "selcode": offering["selcode"], "source_url": offering["source_url"], "syllabus": syllabus,
                  "alternatives": list(others.values())[:5]}
        if syllabus is None:
            result.update(status="not_found", reason="no_syllabus", message="有開課，但教學大綱系統查無這門課的資料")
        return result


# ---------- CLI ----------
def parse_fallback(text):
    try:
        terms = [tuple(int(x) for x in term.split("-")) for term in (text or "").split(",") if term.strip()]
    except ValueError:
        terms = [()]
    if any(len(t) != 2 for t in terms):
        raise argparse.ArgumentTypeError("格式為 學年-學期[,學年-學期…]，例 114-2,114-1")
    return terms


def safe_lookup(fcu, args, name, dept, code):
    """lookup 的例外一律轉成 status=error 的結果；站方拒絕（Blocked）另加 blocked=True，呼叫端應停止後續請求"""
    try:
        return fcu.lookup(args.year, args.sms, name, dept, code, args.fallback)
    except Exception as e:                                          # noqa: BLE001 逐科回報
        result = {"status": "error", "query": {"name": name, "dept": dept, "code": code}, "message": f"{type(e).__name__}: {e}"}
        if isinstance(e, Blocked):
            result["blocked"] = True
        return result


def cmd_search(fcu, args):
    found = rank(fcu.search(args.year, args.sms, args.name), args.name, args.dept, args.code)
    print(json.dumps(found, ensure_ascii=False, indent=1))
    return 0 if found else 1


def cmd_fetch(fcu, args):
    result = safe_lookup(fcu, args, args.name, args.dept, args.code)
    print(json.dumps(result, ensure_ascii=False, indent=1))
    return {"ok": 0, "not_found": 1}.get(result["status"], 2)


def cmd_batch(fcu, args):
    with open(args.input, encoding="utf-8-sig") as f:
        rows = [[c.strip() for c in line.split("\t")] + ["", ""] for line in f]
    rows = [r for r in rows if r[0] and not r[0].startswith("#")]
    results, aborted, streak = [], None, 0
    for i, (name, dept, code, *_) in enumerate(rows, 1):
        result = safe_lookup(fcu, args, name, dept or None, code or None)
        results.append(result)
        print(f"[{i}/{len(rows)}] {name}\t{result['status']}\t{result.get('course') or result.get('message', '')}", file=sys.stderr)
        streak = streak + 1 if result["status"] == "error" else 0
        if result.get("blocked") or streak >= MAX_ERRORS:           # 被拒絕或連續失敗：停手，不再打站方
            aborted = result["message"] if result.get("blocked") else f"連續 {streak} 科失敗"
            break
    counts = {k: sum(r["status"] == k for r in results) for k in ("ok", "not_found", "error")}
    out = {"generated_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
           "source": "逢甲大學課程檢索系統＋教學大綱查詢〈W320104〉（公開頁面，未登入）",
           "year": args.year, "sms": args.sms, "fallback": [f"{y}-{s}" for y, s in args.fallback],
           "requests": fcu.http.count, "summary": counts, "aborted": aborted, "results": results}
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(f"完成 {len(results)}/{len(rows)}：{counts}，共 {fcu.http.count} 個請求 → {args.out}"
          + (f"\n已中止：{aborted}" if aborted else ""), file=sys.stderr)
    return 2 if aborted else 0


def main():
    ap = argparse.ArgumentParser(description="逢甲大學課綱擷取（公開課程檢索系統＋教學大綱查詢）")
    sub = ap.add_subparsers(dest="cmd", required=True)
    for cmd, func in (("search", cmd_search), ("fetch", cmd_fetch), ("batch", cmd_batch)):
        p = sub.add_parser(cmd)
        p.set_defaults(func=func)
        p.add_argument("--year", type=int, required=True, help="民國學年度，例 115")
        p.add_argument("--sms", type=int, required=True, choices=(1, 2, 3, 4), help="1 上學期、2 下學期、3/4 暑修")
        p.add_argument("--interval", type=float, default=MIN_INTERVAL, help="請求最短間隔秒數（下限 0.5）")
        if cmd == "batch":
            p.add_argument("--input", required=True, help="每行：科目名稱[<TAB>系所關鍵字[<TAB>課程編碼]]")
            p.add_argument("--out", required=True, help="輸出 JSON 路徑")
        else:
            p.add_argument("--name", required=True, help="科目名稱（子字串）")
            p.add_argument("--dept", help="開課班級／系所關鍵字")
            p.add_argument("--code", help="課程編碼（sub_id3）")
        if cmd != "search":
            p.add_argument("--fallback", type=parse_fallback, default=[], help="找不到時依序改查的學期，例 114-2,114-1")
    args = ap.parse_args()
    try:
        return args.func(Fcu(args.interval), args)
    except Blocked as e:
        print(f"已中止（站方拒絕或流程改變，未嘗試繞過）：{e}", file=sys.stderr)
        return 2
    except Exception as e:                                          # noqa: BLE001
        print(f"錯誤：{type(e).__name__}: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
