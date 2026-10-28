#!/usr/bin/env python3
"""
逢甲大學正式科目表匯入工具（資料來源：註冊課務組「各學系、所(學位學程)應修學分」各入學學年度索引頁）

用法：
  python3 fcu_curriculum.py fetch --year 115 [--year 114 ...] --out curriculum/
      下載索引頁與所有主修（學系／學位學程）及校共同必修／通識 PDF，寫出 index.csv
  python3 fcu_curriculum.py parse --out curriculum/
      解析 PDF 表格 → courses.csv（entry_year, college, program, department, degree, course, requirement, group_code, credits, grade_year, term, source_url）
  python3 fcu_curriculum.py sql --out curriculum/ > ../src/main/resources/db/ref-courses.sql
      產生 colleges / departments / courses 的 INSERT（正式模式參考資料）

索引頁網址（可依年度擴充）：
  115: https://registration.fcu.edu.tw/courses/req-credits/req-credits_115v2/
  114: https://registration.fcu.edu.tw/freshmen_curriculum/req-credits_114/
  113: https://registration.fcu.edu.tw/req-credits/req-credits_113/
  112: https://registration.fcu.edu.tw/req-credits/req-credits_112/
  111: https://registration.fcu.edu.tw/req-credits/req-credits_111/
"""
import argparse, csv, hashlib, html, os, re, ssl, sys, urllib.request, concurrent.futures

INDEX_URLS = {
    115: "https://registration.fcu.edu.tw/courses/req-credits/req-credits_115v2/",
    114: "https://registration.fcu.edu.tw/freshmen_curriculum/req-credits_114/",
    113: "https://registration.fcu.edu.tw/req-credits/req-credits_113/",
    112: "https://registration.fcu.edu.tw/req-credits/req-credits_112/",
    111: "https://registration.fcu.edu.tw/req-credits/req-credits_111/",
}
UA = {"User-Agent": "Mozilla/5.0 (campus-match curriculum importer)"}

# 校共同必修／通識：出現在幾乎每個系的必修區，對外歸類為 GENERAL（不屬任何系）
GENERAL_PATTERNS = [r"^體育", r"^國防科技", r"^全民國防", r"^中文思辨與表達", r"^大學基礎英文", r"^大學精進英文",
                    r"^科學與人文的對話", r"^現代公民與社會實踐", r"^班級活動", r"^服務學習", r"^英文\(", r"^大學英文"]
PROGRAM_EXCLUDE = ["學分學程", "微學程", "輔系", "雙主修", "第二主修", "輔修", "跨領域"]
EXCLUDE_RE = re.compile(r"(?<!學位)學程\(")   # 「學分學程(…)」「微學程(…)」等；「碩士在職學位學程(高階管理組)」是正式學程，保留


def ssl_context():
    """沿用系統／環境變數指定的 CA（SSL_CERT_FILE）；Python 3.13 預設的 X509_STRICT 會拒絕缺少 SKI 的企業代理 CA，只關閉該旗標、仍驗證憑證鏈"""
    ctx = ssl.create_default_context(cafile=os.environ.get("SSL_CERT_FILE") or None)
    ctx.verify_flags &= ~getattr(ssl, "VERIFY_X509_STRICT", 0)
    return ctx


_CTX = ssl_context()


def get(url, binary=False, timeout=60):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout, context=_CTX) as r:
        data = r.read()
    return data if binary else data.decode("utf-8", "replace")


# ---------- fetch ----------
def parse_index(page_html, year):
    """回傳 [(college, label_text, degree_label, url)]；college 取連結前最近的 <h2>"""
    out = []
    pos_h2 = [(m.start(), re.sub(r"<[^>]+>", "", m.group(1)).strip()) for m in re.finditer(r"<h2[^>]*>(.*?)</h2>", page_html, flags=re.S)]
    for m in re.finditer(r'<a[^>]+href="(https://s3[^"]+\.pdf)"[^>]*>(.*?)</a>', page_html, flags=re.S):
        url, text = m.group(1), re.sub(r"<[^>]+>", "", m.group(2)).strip()
        college = ""
        for p, h in pos_h2:
            if p < m.start(): college = h
        # 連結前同一行的文字（學門名稱）
        line_start = max(page_html.rfind("<br", 0, m.start()), page_html.rfind("<p", 0, m.start()), page_html.rfind("</h2>", 0, m.start()))
        label = re.sub(r"<[^>]+>", " ", page_html[line_start:m.start()])
        label = re.sub(r"\s+", " ", html.unescape(label)).strip(" />")
        out.append((college, label, text, html.unescape(url)))
    # 去重
    seen, uniq = set(), []
    for row in out:
        if row[3] not in seen:
            seen.add(row[3]); uniq.append(row)
    return uniq


def is_major_code(url):
    """115 起檔名含代碼：…-B-FM-… 主修；舊年度無代碼則回 None（改以 PDF 標題判斷）"""
    fn = url.rsplit("/", 1)[1]
    m = re.search(r"-([A-Z])-([A-Z]{2})-", fn)
    if not m: return None
    degree, kind = m.groups()
    if kind == "FC": return True                 # 校共同必修／通識
    return kind == "FM" and degree in ("B", "M", "D")


def cmd_fetch(args):
    os.makedirs(args.out, exist_ok=True)
    rows = []
    for year in args.year:
        url = INDEX_URLS[year]
        print(f"[{year}] 索引 {url}", file=sys.stderr)
        page = get(url)
        open(os.path.join(args.out, f"index_{year}.html"), "w", encoding="utf-8").write(page)
        items = parse_index(page, year)
        print(f"[{year}] PDF 連結 {len(items)}", file=sys.stderr)
        for college, label, text, pdf in items:
            if "reg-sch" in pdf: continue
            major = is_major_code(pdf)
            if major is False: continue            # 115 起可由代碼先排除輔系／學程
            rows.append(dict(entry_year=year, college=college, label=label, link_text=text, url=pdf, file=""))
    pdf_dir = os.path.join(args.out, "pdf"); os.makedirs(pdf_dir, exist_ok=True)

    def dl(row):
        name = f"{row['entry_year']}_{hashlib.md5(row['url'].encode()).hexdigest()[:10]}.pdf"
        path = os.path.join(pdf_dir, name)
        if not os.path.exists(path):
            try: open(path, "wb").write(get(row["url"], binary=True))
            except Exception as e: print("下載失敗", row["url"], e, file=sys.stderr); return row
        row["file"] = name; return row
    with concurrent.futures.ThreadPoolExecutor(8) as ex:
        rows = list(ex.map(dl, rows))
    with open(os.path.join(args.out, "index.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["entry_year", "college", "label", "link_text", "url", "file"]); w.writeheader(); w.writerows(rows)
    print(f"已下載 {sum(1 for r in rows if r['file'])} / {len(rows)}", file=sys.stderr)


# ---------- parse ----------
def pdf_title(pdf):
    txt = (pdf.pages[0].extract_text() or "")
    m = re.search(r"逢甲大學\s*(.+?)\s*必選修科目表\s*[（(](\d+)學年度", txt)
    return (m.group(1).strip(), int(m.group(2))) if m else (None, None)


def degree_of(program):
    if "博士" in program: return "PHD"
    if "碩士" in program: return "MASTER"
    return "BACHELOR"


def department_of(program):
    """正式系所名：只去掉研究所後綴（資訊工程學系碩士班 → 資訊工程學系）；學位學程、進修學士班保留全名"""
    d = re.sub(r"(碩士在職專班|碩士班|博士班)$", "", program).strip()
    return d or program


def is_general(name):
    return any(re.search(p, name) for p in GENERAL_PATTERNS)


def parse_pdf(path):
    import pdfplumber
    courses = []
    with pdfplumber.open(path) as pdf:
        program, year = pdf_title(pdf)
        if not program: return program, year, courses
        section = None
        for page in pdf.pages:
            for table in page.extract_tables() or []:
                for row in table:
                    cells = [(c or "").replace("\n", "").strip() for c in row]
                    joined = "".join(cells).replace(" ", "")
                    if not joined: continue
                    if "必修科目" in joined and len(joined) <= 12: section = "REQUIRED"; continue
                    if "選修科目" in joined and len(joined) <= 12: section = "ELECTIVE"; continue
                    if cells[0] == "科目名稱" or (cells[1] in ("上", "") and cells[0] == "" and set(cells) <= {"", "上", "下"}): continue
                    if section is None: continue
                    for g in range(0, len(cells) - 2, 3):
                        name, up, down = cells[g], cells[g + 1], cells[g + 2]
                        if not name or name in ("科目名稱",): continue
                        m = re.match(r"^([a-zA-Z])[.\s]+(.+)$", name)
                        group_code = m.group(1) if m else ""
                        cname = (m.group(2) if m else name).strip()
                        code = ""                                   # 雙語版：「ATHL1003 體育(一) PHYSICAL EDUCATION (1)」→ 代碼、中文名
                        mc = re.match(r"^(" + CODE_RE + r")\s*(.+)$", cname)
                        if mc: code, cname = mc.group(1), mc.group(2)
                        mt = re.search(r"(?<![(（A-Za-z\-/])\s*([A-Za-z][A-Za-z0-9 ,:&'()\-/.]{3,})$", cname)   # 雙語版：去掉結尾英文名
                        if mt:
                            head, tail = cname[:mt.start()].strip(), mt.group(1)
                            if head and re.search(r"[\u4e00-\u9fff]", head) and head.count("(") == head.count(")") and not head.endswith(("-", "/", "(", "（")) \
                                    and (len(tail) >= 6 or " " in tail or (re.search(r"[a-z]", tail) and re.search(r"[A-Z]", tail))):
                                cname = head
                        cname = re.sub(r"\s+", "", cname)
                        if cname.count("(") == cname.count(")") + 1 and re.search(r"\([一二三四五六七八九十IVX\d]+$", cname): cname += ")"   # 儲存格被截斷的右括號
                        if len(cname) < 2: continue
                        if re.match(r"^[(（]\d+[)）]", cname) or "【" in cname or re.search(r"(學分|credits?)$", cname, re.I): continue   # 表尾的學分規定說明，不是科目
                        if cname in ("科目名稱", "課程名稱", "上", "下", "必修科目", "選修科目") or re.match(r"^(第?[一二三四五六七八九十]+年級|上學期|下學期)$", cname): continue   # 表頭
                        credit = up if up not in ("", None) else down
                        term = 1 if up not in ("", None) else (2 if down not in ("", None) else None)
                        try: credits = float(credit)
                        except (TypeError, ValueError): credits = None
                        req = "GENERAL" if is_general(cname) else section
                        courses.append(dict(code=code, course=cname, requirement=req, group_code=group_code, credits=credits, grade_year=g // 3 + 1, term=term))
    return program, year, courses



CODE_RE = r"[A-Z]{2,6}\d{3,4}[A-Z]?"
TOKEN_RE = re.compile(r"(" + CODE_RE + r")\s+(.+?)\s+(\d+(?:\.\d+)?)(?=\s+" + CODE_RE + r"\s|\s*$)")
YEAR_RE = re.compile(r"^([一二三四五六七])年級")
CN_NUM = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7}


def pdf_title_b(first_text):
    """115 起格式：第一行「資訊工程, 工學學士 (128學分)」、第三行「(115學年度入學學生適用)」"""
    lines = [l.strip() for l in first_text.split("\n") if l.strip()]
    if not lines: return None, None, None
    m = re.match(r"^(.+?),\s*(.+?)\s*\(\d+學分\)", lines[0])
    if not m: return None, None, None
    label, deg = m.group(1).strip(), m.group(2)
    year = None
    for l in lines[:6]:
        y = re.search(r"\((\d+)學年度", l)
        if y: year = int(y.group(1)); break
    degree = "PHD" if "博士" in deg else ("MASTER" if "碩士" in deg else "BACHELOR")
    return label, degree, year


def parse_pdf_b(path):
    """115 起格式：每頁文字以頁面中線分左右欄（第1／第2學期），逐行比對「課程編碼 科目名稱 學分」"""
    import pdfplumber
    courses, section, year = [], None, None
    with pdfplumber.open(path) as pdf:
        label, degree, entry_year = pdf_title_b(pdf.pages[0].extract_text() or "")
        if not label: return None, None, None, courses, None
        unit = None                                        # 「管理單位：建設學院/土木工程學系」→ 正式學院與系所名
        for page in pdf.pages[-2:]:
            m = re.search(r"管理單位[：:]\s*([^/\s]+)/(\S+)", page.extract_text() or "")
            if m: unit = (m.group(1), m.group(2)); break
        mid = None
        for page in pdf.pages:
            words = page.extract_words(keep_blank_chars=False, use_text_flow=False)
            # 欄位分界：表頭第二個「課程編碼」的左緣（頁面寬度一半不準）
            names = sorted({round(w["x0"]) for w in words if "科目名稱" in w["text"]})
            codes = sorted({round(w["x0"]) for w in words if w["text"].startswith("課程編碼")})
            if len(names) >= 2 and codes: mid = names[1] - (names[0] - codes[0]) - 2
            elif mid is None: mid = page.width / 2
            lines = {}
            for w in words:
                lines.setdefault(round(w["top"] / 3), []).append(w)
            for key in sorted(lines):
                ws = sorted(lines[key], key=lambda w: w["x0"])
                full = " ".join(w["text"] for w in ws)
                if re.match(r"^(必修|選修|核心必修|核心選修|校共同|通識)", full) and ("學分" in full or len(full) <= 6):
                    section = "REQUIRED" if full.startswith(("必修", "核心必修")) else "ELECTIVE"
                    continue
                ym = YEAR_RE.match(full)
                if ym: year = CN_NUM[ym.group(1)]; continue
                if section is None: continue
                for term, half in ((1, [w for w in ws if w["x0"] < mid]), (2, [w for w in ws if w["x0"] >= mid])):
                    text = " ".join(w["text"] for w in half)
                    for m in TOKEN_RE.finditer(text):
                        code, name, credit = m.group(1), re.sub(r"\s+", "", m.group(2)), float(m.group(3))
                        if len(name) < 2 or name in ("科目名稱",): continue
                        req = "GENERAL" if is_general(name) else section
                        courses.append(dict(code=code, course=name, requirement=req, group_code="", credits=credit, grade_year=year, term=term))
    return label, degree, entry_year, courses, unit


def parse_ge_b(path, entry_year):
    """115 起：通識選修清單（必選修 課程編碼 科目名稱 學分 課程群）與校共同必修（純文字）"""
    import pdfplumber
    out = []
    with pdfplumber.open(path) as pdf:
        for page in pdf.pages:
            for line in (page.extract_text() or "").split("\n"):
                m = re.match(r"^(必修|選修)\s+(" + CODE_RE + r")\s+(.+?)\s+(\d+(?:\.\d+)?)(?:\s+(.*))?$", line.strip())
                if m:
                    out.append(dict(code=m.group(2), course=re.sub(r"\s+", "", m.group(3)), requirement="GENERAL", group_code=(m.group(5) or "")[:20], credits=float(m.group(4)), grade_year=None, term=None))
                    continue
                m = re.match(r"^(" + CODE_RE + r")\s+(.+?)\s+(\d+(?:\.\d+)?)\s*$", line.strip())
                if m:
                    out.append(dict(code=m.group(1), course=re.sub(r"\s+", "", m.group(2)), requirement="GENERAL", group_code="", credits=float(m.group(3)), grade_year=None, term=None))
    return out


# 學程／組別名稱 → 學生註冊時選擇的系所（同一系所的碩士班分組、在職專班合併為一份清單，組別保留在 group_code）
ALIASES = {
    "外國語文學系英語文研究": "外國語文學系", "英語文研究": "外國語文學系",
    "機械與電腦輔助工程學系機械工程": "機械與電腦輔助工程學系", "機械工程": "機械與電腦輔助工程學系", "機械與電腦輔助工程：半導體": "機械與電腦輔助工程學系",
    "統計學系統計與精算": "統計學系", "統計與精算": "統計學系",
    "行銷學系全球行銷": "行銷學系", "全球行銷": "行銷學系",
    "財經法律研究所碩士班(法律學組)": "財經法律研究所", "財經法律研究所碩士班(法律專業組)": "財經法律研究所",
    "財經法律": "財經法律研究所", "財經法律：法律學": "財經法律研究所", "財經法律：法律專業": "財經法律研究所",
    "高階管理": "經營管理碩士在職學位學程", "數位創新管理": "經營管理碩士在職學位學程", "文化創意產業管理": "經營管理碩士在職學位學程",
    "建築產業管理": "經營管理碩士在職學位學程", "經營管理": "經營管理碩士在職學位學程",
    "室內設計": "室內設計學士學位學程", "建築": "建築學士學位學程", "土木工程：營建工程與管理": "土木工程學系營建工程與管理進修學士班",
    "商學大數據分析": "美國加州聖荷西州立大學商學大數據分析雙學士學位學程", "商學與創新": "澳洲墨爾本皇家理工大學商學與創新雙學士學位學程",
    "經營管理碩士在職學位學程(高階管理組)": "經營管理碩士在職學位學程", "經營管理碩士在職學位學程(經營管理組)": "經營管理碩士在職學位學程",
    "經營管理碩士在職學位學程(建築產業管理組)": "經營管理碩士在職學位學程", "經營管理碩士在職學位學程(數位創新管理組)": "經營管理碩士在職學位學程",
    "經營管理碩士在職學位學程(文創管理組)": "經營管理碩士在職學位學程",
}
ALIASES_BY_DEGREE = {("商學", "PHD"): "商學博士學位學程", ("金融", "PHD"): "金融博士學位學程", ("金融", "MASTER"): "金融碩士在職學位學程",
                     ("建築", "MASTER"): "建築碩士學位學程"}
CEBACC_ALIASES = {"商學": "商學進修學士學位學程", "室內設計": "室內設計進修學士班", "營建工程與管理": "土木工程學系營建工程與管理進修學士班"}  # (CEBacc) = 進修學士
# 索引頁的學院標題對研究所並不可靠（多數碩博士班被歸到「學士後專班」標題下）；以學士班所在學院為準，找不到時用下表
DEPT_COLLEGE_FIX = {
    "財經法律研究所": "商學院", "建築碩士學位學程": "建築專業學院", "智慧城市碩士學位學程": "建設學院", "金融博士學位學程": "金融學院",
    "資訊工程學系學士後專班": "資訊電機學院", "學士後工程與科學學院淨零智慧永續學士班": "工程與科學學院",
    "土木工程學系營建工程與管理進修學士班": "建設學院", "室內設計學士學位學程": "建築專業學院", "建築專業學院學士班": "建築專業學院",
    "資訊電機學院學士班": "資訊電機學院", "人文社會學士學位學程": "人文社會學院", "商學進修學士學位學程": "商學院",
    "創新智慧製造與管理產業碩士專班": "工程與科學學院", "經營管理碩士在職學位學程": "經營管理學院",
}
UNRELIABLE_COLLEGES = {"學士後專班", "其他", ""}


def normalize(rows):
    """新格式（115 起）的學門名 → 舊格式 PDF 標題的正式系所名；套用別名；補齊學院"""
    def clean(label): return re.sub(r"\s*[（(].*?[)）]\s*", "", label).strip()
    for r in rows:                                   # 舊格式：先套別名（在職專班、分組 → 系所）
        if r["department"]:
            r["department"] = ALIASES_BY_DEGREE.get((r["department"], r["degree"]), ALIASES.get(r["department"], r["department"]))
    official = {r["department"] for r in rows if r["department"]}
    cache = {}
    for r in rows:
        if r["program"] == "校共同／通識": r["department"] = ""; continue
        if r["department"] is None:
            lab = clean(r["program"])
            cebacc = "CEBacc" in r["program"]
            ck = (lab, r["degree"], cebacc)
            if ck not in cache:
                if cebacc and lab in CEBACC_ALIASES: pick = CEBACC_ALIASES[lab]
                elif (lab, r["degree"]) in ALIASES_BY_DEGREE: pick = ALIASES_BY_DEGREE[(lab, r["degree"])]
                elif lab in ALIASES: pick = ALIASES[lab]
                else:
                    cands = [n for n in official if n.startswith(lab)]
                    exact = [n for n in cands if n in (lab + "學系", lab + "系", lab)]
                    if exact: pick = exact[0]
                    elif cands:
                        same_deg = [n for n in cands if (r["degree"] == "MASTER") == ("碩士" in n) and (r["degree"] == "PHD") == ("博士" in n)]
                        pick = min(same_deg or cands, key=len)
                    elif r["college"] == "國際科技與管理學院" and r["degree"] == "BACHELOR": pick = lab + "學士學位學程"
                    else: pick = lab                                       # 新設學程：保留學門名，由管理員後台修正
                cache[ck] = pick
            r["department"] = cache[ck]
            if r["department"] != lab and not r.get("group_code"): r["group_code"] = lab[:20]   # 分組名保留
        if r["department"] is None: r["department"] = ""
    college_of = {}
    for r in rows:                                   # 學院：優先採用學士班所在、可靠的學院標題
        if r["department"] and r["college"] not in UNRELIABLE_COLLEGES:
            if r["department"] not in college_of or r["degree"] == "BACHELOR": college_of[r["department"]] = r["college"]
    for d, c in DEPT_COLLEGE_FIX.items(): college_of.setdefault(d, c)
    for r in rows:
        if r["department"]: r["college"] = college_of.get(r["department"], r["college"] if r["college"] not in UNRELIABLE_COLLEGES else "")


def cmd_parse(args):
    idx = list(csv.DictReader(open(os.path.join(args.out, "index.csv"), encoding="utf-8")))
    out, stats, skipped = [], {}, []
    for row in idx:
        if not row["file"]: continue
        if re.search(r"EN\.pdf$", row["url"], re.I): skipped.append((row["url"], "英文版（與中文版重複）")); continue
        path = os.path.join(args.out, "pdf", row["file"])
        try:
            if "GE-" in row["url"] or row["link_text"] in ("校共同必修課程", "通識選修課程"):
                courses = parse_ge_b(path, int(row["entry_year"]))
                program, dept, deg, year = "校共同／通識", None, "BACHELOR", int(row["entry_year"])
            else:
                label, deg, year, courses, unit = parse_pdf_b(path)
                if label:
                    program = label
                    dept = None                                   # 新格式只有學門名，稍後對應正式系所名
                    if unit and unit[1] != unit[0] and not unit[1].endswith("學院"):
                        dept = department_of(unit[1]); row = dict(row, college=unit[0])
                else:
                    program, year, courses = parse_pdf(path)        # ≤114 舊格式
                    if not program: skipped.append((row["url"], "無標題")); continue
                    dept, deg = department_of(program), degree_of(program)
        except Exception as e: print("解析失敗", row["url"], e, file=sys.stderr); continue
        if any(x in program for x in PROGRAM_EXCLUDE) or EXCLUDE_RE.search(program): skipped.append((row["url"], program)); continue
        year = year or int(row["entry_year"])
        seen = set()
        for c in courses:
            c.setdefault("code", "")
            key = (c["course"], c["requirement"], c["grade_year"], c["term"])
            if key in seen: continue
            seen.add(key)
            out.append(dict(entry_year=year, college=row["college"], program=program, department=dept, degree=deg, source_url=row["url"], **c))
        stats[(year, program)] = len(seen)
    normalize(out)
    with open(os.path.join(args.out, "courses.csv"), "w", encoding="utf-8", newline="") as f:
        fields = ["entry_year", "college", "program", "department", "degree", "source_url", "code", "course", "requirement", "group_code", "credits", "grade_year", "term"]
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore"); w.writeheader(); w.writerows(out)
    with open(os.path.join(args.out, "parse_report.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f); w.writerow(["entry_year", "program", "courses"]); [w.writerow([y, p, n]) for (y, p), n in sorted(stats.items())]
    print(f"學程 {len(stats)}，課程列 {len(out)}，略過 {len(skipped)}（輔系／學程／無標題）", file=sys.stderr)
    for why in sorted({w for _, w in skipped}): print("  略過", why, file=sys.stderr)


# ---------- sql ----------
def q(v):
    if v is None or v == "": return "NULL"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def cmd_sql(args):
    rows = list(csv.DictReader(open(os.path.join(args.out, "courses.csv"), encoding="utf-8")))
    dept_college = {}
    for r in rows:
        if r["department"] and (r["department"] not in dept_college or (not dept_college[r["department"]] and r["college"])):
            dept_college[r["department"]] = r["college"]
    depts = sorted((c or "其他", d) for d, c in dept_college.items())
    colleges = sorted({c for c, _ in depts if c != "其他"})
    L = ["-- 逢甲大學正式科目表（來源：註冊課務組各入學學年度索引頁 https://registration.fcu.edu.tw/req-credits/ ）",
         "-- 由 tools/fcu_curriculum.py 產生；重新產生請依序執行 fetch → parse → sql", "BEGIN;"]
    for c in colleges + (["其他"] if any(d[0] == "其他" for d in depts) else []):
        L.append(f"INSERT INTO colleges (name) VALUES ({q(c)}) ON CONFLICT (name) DO NOTHING;")
    for c, d in depts:
        L.append(f"INSERT INTO departments (college_id, name) SELECT id, {q(d)} FROM colleges WHERE name={q(c)} ON CONFLICT (name) DO NOTHING;")
    seen, values = set(), []
    for r in rows:
        dept = r["department"]
        key = (dept, r["degree"] if dept else "BACHELOR", r["entry_year"], r["course"])
        if key in seen: continue
        seen.add(key)
        dsel = f"(SELECT id FROM departments WHERE name={q(dept)})" if dept else "NULL"
        values.append(f"({dsel}, {q(r['code'] or None)}, {q(r['course'])}, {q(r['degree'] if dept else 'BACHELOR')}, {r['entry_year']}, {q(r['requirement'])}, "
                      f"{q(r['group_code'] or None)}, {q(float(r['credits']) if r['credits'] else None)}, {q(int(float(r['grade_year'])) if r['grade_year'] else None)}, "
                      f"{q(int(float(r['term'])) if r['term'] else None)}, {q(r['source_url'])})")
    for i in range(0, len(values), 500):
        L.append("INSERT INTO courses (department_id, code, name, degree, entry_year, requirement, group_code, credits, grade_year, term, source_url) VALUES\n"
                 + ",\n".join(values[i:i + 500]) + "\nON CONFLICT DO NOTHING;")
    L.append("COMMIT;")
    print("\n".join(L))
    print(f"colleges {len(colleges)}, departments {len(depts)}, courses {len(values)}", file=sys.stderr)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("fetch"); f.add_argument("--year", type=int, action="append", required=True); f.add_argument("--out", default="curriculum")
    p = sub.add_parser("parse"); p.add_argument("--out", default="curriculum")
    s = sub.add_parser("sql"); s.add_argument("--out", default="curriculum")
    a = ap.parse_args()
    {"fetch": cmd_fetch, "parse": cmd_parse, "sql": cmd_sql}[a.cmd](a)
