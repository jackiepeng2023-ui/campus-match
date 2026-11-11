#!/usr/bin/env python3
"""
跨系資源媒合平台 — Demo 用學生檔案產生器
- 固定亂數種子，每次執行結果相同（可重現）
- 產出：db/data.sql（學生、成績、得獎、歷史案件與互評）、db/data-post.sql（需要參考資料的證照／作品集／自我評估）、
        out/students.json、out/students_summary.csv
- 只產生「原始證據」；Skill Profile（技能分數、三階等級、已驗證／自述）由後端能力盤點模組在啟動時依同一套規則算出，不在這裡寫死
- 所有姓名、學號、Email 皆為虛構；Email 與證明連結使用保留網域 example.edu
對應決策：D5 成績/得獎/技能檔、D10 科目→技能、D29 預計畢業、D41 得獎矩陣、D53–D55 三階等級與證據
"""
import json, csv, random, os
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT_DIR, exist_ok=True)
OUT_SQL = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "main", "resources", "db", "data.sql")
OUT_POST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "main", "resources", "db", "data-post.sql")
from datetime import date

SEED = 20261120
rng = random.Random(SEED)

# ---------- 參考資料 ----------
COLLEGES = {
    "資訊電機學院": ["資訊工程學系", "電機工程學系"],
    "商學院": ["企業管理學系", "行銷學系", "統計學系"],
    "建設學院": ["土木工程學系"],
    "建築專業學院": ["建築學士學位學程"],
    "工程與科學學院": ["工業工程與系統管理學系"],
    "人文社會學院": ["中國文學系", "外國語文學系"],
    "創意設計學院": ["創意設計學系"],  # 虛構學院，供 UI/UX 需求 Demo
}

SKILLS = [  # (name, category)
    ("Java", "後端"), ("Spring Boot", "後端"), ("Python", "後端"), ("SQL", "後端"), ("Node.js", "後端"),
    ("HTML/CSS", "前端"), ("JavaScript", "前端"), ("Vue", "前端"), ("React", "前端"), ("SwiftUI", "前端"),
    ("資料分析", "資料分析"), ("統計", "資料分析"), ("資料視覺化", "資料分析"), ("機器學習", "資料分析"),
    ("UI/UX 設計", "設計"), ("Figma", "設計"), ("平面設計", "設計"),
    ("簡報設計", "簡報"), ("商業企劃", "簡報"), ("行銷企劃", "簡報"), ("財務分析", "簡報"),
    ("英文寫作", "語言"), ("問卷設計", "其他"), ("專案管理", "商管"), ("研究方法", "其他"),   # 分類與 ref-base.sql 的共用 Skill 資料庫一致
]
SKILL_ID = {s[0]: i + 1 for i, s in enumerate(SKILLS)}

# 各系代表課程 → 對應技能（D10 預設對照）
COURSES = {
    "資訊工程學系": [("程式設計", ["Java"]), ("資料結構", ["Java"]), ("演算法", ["Python"]),
                ("資料庫系統", ["SQL"]), ("網頁程式設計", ["HTML/CSS", "JavaScript", "Vue"]),
                ("軟體工程", ["專案管理", "Spring Boot"]), ("行動應用程式開發", ["SwiftUI"]),
                ("人工智慧導論", ["機器學習", "Python"])],
    "電機工程學系": [("計算機程式", ["Python"]), ("訊號與系統", ["資料分析"]),
                ("嵌入式系統", ["Java"]), ("機器學習概論", ["機器學習"])],
    "企業管理學系": [("管理學", ["專案管理"]), ("創業管理", ["商業企劃"]),
                ("財務管理", ["財務分析"]), ("企業簡報實務", ["簡報設計"])],
    "行銷學系": [("行銷管理", ["行銷企劃"]), ("消費者行為", ["問卷設計"]),
              ("數位行銷", ["行銷企劃", "資料分析"]), ("品牌與設計", ["平面設計"])],
    "統計學系": [("統計學", ["統計"]), ("迴歸分析", ["統計", "資料分析"]),
              ("統計軟體", ["Python", "SQL"]), ("資料視覺化", ["資料視覺化"])],
    "土木工程學系": [("工程數學", ["資料分析"]), ("營建管理", ["專案管理"]), ("計算機概論", ["Python"])],
    "建築學士學位學程": [("建築設計", ["平面設計"]), ("數位建築", ["UI/UX 設計"]), ("建築表現法", ["簡報設計"])],
    "工業工程與系統管理學系": [("作業研究", ["資料分析"]), ("品質管理", ["統計"]),
                       ("人因工程", ["UI/UX 設計"]), ("生產管理", ["專案管理"])],
    "中國文學系": [("文學寫作", ["簡報設計"]), ("文案企劃", ["行銷企劃"])],
    "外國語文學系": [("英文寫作", ["英文寫作"]), ("專業簡報", ["簡報設計"])],
    "創意設計學系": [("使用者經驗設計", ["UI/UX 設計", "Figma"]), ("視覺傳達", ["平面設計"]),
                ("介面原型", ["Figma"]), ("設計簡報", ["簡報設計"])],
}
GRAD_COURSES = [("研究方法", ["研究方法"]), ("進階統計", ["統計"]), ("學術英文寫作", ["英文寫作"])]

# 舊版 D14 的 1–5 級換算：只用來維持亂數序列與歷史案件的角色指派（示範人物、姓名、案件不因改版而變動）；
# 寫進資料庫的是原始證據，等級由後端依 D53 三階規則計算
CONVERSION = {
    "BACHELOR": [(90, 5), (80, 4), (70, 3), (60, 2), (0, 1)],
    "GRADUATE": [(90, 5), (85, 4), (80, 3), (70, 2), (0, 1)],
}
def to_level(score, degree):
    table = CONVERSION["BACHELOR" if degree == "BACHELOR" else "GRADUATE"]
    return next(lv for lo, lv in table if score >= lo)

# D41 得獎矩陣
AWARD_MATRIX = {
    ("FIRST", "CAMPUS"): 0.5, ("FIRST", "NATIONAL"): 0.8, ("FIRST", "INTERNATIONAL"): 1.0,
    ("TOP3", "CAMPUS"): 0.4, ("TOP3", "NATIONAL"): 0.65, ("TOP3", "INTERNATIONAL"): 0.8,
    ("HONORABLE", "CAMPUS"): 0.25, ("HONORABLE", "NATIONAL"): 0.4, ("HONORABLE", "INTERNATIONAL"): 0.5,
    ("FINALIST", "CAMPUS"): 0.15, ("FINALIST", "NATIONAL"): 0.25, ("FINALIST", "INTERNATIONAL"): 0.3,
}
COMPETITIONS = [  # 虛構競賽名稱
    ("校園創新創業競賽", "CAMPUS", ["商業企劃", "簡報設計"]),
    ("校園黑客松", "CAMPUS", ["JavaScript", "Vue"]),
    ("校園資料分析競賽", "CAMPUS", ["資料分析", "資料視覺化"]),
    ("全國大專校院程式競賽", "NATIONAL", ["Java", "Python"]),
    ("全國大專創業提案競賽", "NATIONAL", ["商業企劃", "財務分析"]),
    ("全國 UI/UX 設計競賽", "NATIONAL", ["UI/UX 設計", "Figma"]),
    ("全國資料科學競賽", "NATIONAL", ["機器學習", "資料分析"]),
    ("國際學生軟體創新競賽", "INTERNATIONAL", ["Spring Boot", "SwiftUI"]),
    ("國際設計獎學生組", "INTERNATIONAL", ["平面設計", "UI/UX 設計"]),
]
RANKS = ["FIRST", "TOP3", "HONORABLE", "FINALIST"]

SURNAMES = list("陳林黃張李王吳劉蔡楊許鄭謝洪郭邱曾廖賴徐周葉蘇莊呂江何蕭羅高潘簡朱")
GIVEN = ["家豪", "怡君", "志明", "雅婷", "冠宇", "佳穎", "承翰", "詩涵", "柏宇", "欣妤", "宇翔", "郁婷",
         "俊傑", "宜蓁", "彥廷", "思妤", "子豪", "品妍", "哲瑋", "芷晴", "冠廷", "語彤", "博文", "筱涵",
         "建宏", "婉婷", "昱辰", "沛珊", "宗翰", "亭妤", "子軒", "以晴", "致遠", "心怡", "睿哲", "庭瑄"]

TODAY = date(2026, 10, 26)
ACADEMIC_YEAR_START = 2026  # 115 學年度

# ---------- D53–D55：證據（證照、作品集、自我評估） ----------
ev_rng = random.Random(SEED + 2)          # 另一顆亂數：新增的證據不影響原有的學生／成績／得獎序列
ai_rng = random.Random(SEED + 3)          # 第三顆：AI 與專題相關的課外證據
CLAIM = {1: 65, 2: 78, 3: 93}             # 自選階級的代表分數（初階／中階／進階的區間中點）
def common_score(score, degree):          # 研究所成績 → 共同量尺（預設門檻 70／80／90 → 60／70／85）
    if degree == "BACHELOR": return score
    a, b = [0, 70, 80, 90, 100], [0, 60, 70, 85, 100]
    for i in range(4):
        if score <= a[i + 1] or i == 3:
            return int(b[i] + (score - a[i]) * (b[i + 1] - b[i]) / (a[i + 1] - a[i]) + 0.5)
def tier_of(score): return 3 if score >= 85 else 2 if score >= 70 else 1 if score >= 60 else 0
CERTS = {  # 名稱須與 ref-base.sql 的證照對照表一致
    "資訊工程學系": ["TQC+ 程式語言 Python", "網頁設計丙級技術士", "AWS Certified Cloud Practitioner", "電腦軟體設計丙級技術士", "iPAS 資訊安全工程師（初級）"],
    "電機工程學系": ["TQC+ 程式語言 Python", "ITS Python", "Microsoft Azure AI Fundamentals（AI-900）"],
    "企業管理學系": ["TOEIC 多益 750 分以上", "CAPM 專案管理助理師", "會計事務丙級技術士"],
    "行銷學系": ["TOEIC 多益 750 分以上", "Google Data Analytics Certificate", "Adobe Certified Professional（Photoshop／Illustrator）"],
    "統計學系": ["iPAS 巨量資料分析師（初級）", "Tableau Desktop Specialist", "Google Data Analytics Certificate"],
    "土木工程學系": ["Autodesk Certified User：AutoCAD", "TOEIC 多益 550 分以上"],
    "建築學士學位學程": ["Autodesk Certified User：AutoCAD", "Adobe Certified Professional（Photoshop／Illustrator）"],
    "工業工程與系統管理學系": ["CAPM 專案管理助理師", "SOLIDWORKS CSWA", "TOEIC 多益 750 分以上"],
    "中國文學系": ["TOEIC 多益 550 分以上", "JLPT 日本語能力試驗 N3"],
    "外國語文學系": ["TOEIC 多益 900 分以上", "TOEFL iBT 80 分以上", "JLPT 日本語能力試驗 N2"],
    "創意設計學系": ["Google UX Design Certificate", "Adobe Certified Professional（Photoshop／Illustrator）"],
}
PERSONA_EVIDENCE = {  # 示範人物的證據（決賽 Demo 講稿會指到這幾筆）
    "DEMO_OWNER_BIZ": [dict(type="CERTIFICATE", catalog="TOEIC 多益 750 分以上", verified=True, on="2025-11-16")],
    "DEMO_FE_STRONG": [dict(type="CERTIFICATE", catalog="網頁設計乙級技術士", verified=True, on="2025-08-09"),
                       dict(type="PORTFOLIO", title="作品集：社團活動報名前台（Vue 3）", tier=3, skills=["Vue", "JavaScript"], verified=False, on="2026-03-02")],
    "DEMO_BE_STRONG": [dict(type="CERTIFICATE", catalog="AWS Certified Cloud Practitioner", verified=True, on="2026-01-24"),
                       dict(type="PORTFOLIO", title="作品集：課程問答機器人（RAG＋Spring Boot）", tier=3, skills=["生成式 AI 應用", "Spring Boot", "Python"], verified=True, on="2026-06-08")],
    "DEMO_DATAVIZ": [dict(type="CERTIFICATE", catalog="Tableau Desktop Specialist", verified=True, on="2026-02-21"),
                     dict(type="PORTFOLIO", title="作品集：台中市 YouBike 站點儀表板", tier=3, skills=["資料視覺化", "資料分析"], verified=False, on="2026-04-18")],
    "DEMO_UIUX": [dict(type="CERTIFICATE", catalog="Google UX Design Certificate", verified=False, on="2026-05-30")],
    "DEMO_LOW_CRED": [dict(type="PORTFOLIO", title="作品集：Vue 電商前台", tier=3, skills=["Vue", "HTML/CSS"], verified=False, on="2026-09-12")],   # 課程 72 分（中階），自述進階
    "DEMO_PHD_OWNER": [dict(type="CERTIFICATE", catalog="TOEFL iBT 80 分以上", verified=True, on="2024-12-07")],
}

# ---------- 人口組成：50 人 ----------
# 學士 35（各年級分布）、碩士 10、博士 5
PLAN = ([("BACHELOR", y) for y in [1]*6 + [2]*9 + [3]*10 + [4]*10] +
        [("MASTER", y) for y in [1]*5 + [2]*5] +
        [("PHD", y) for y in [1, 2, 3, 3, 4]])

# Demo 劇本指定角色（固定前 8 人，確保劇本可跑）
DEMO_PERSONAS = [
    dict(tag="DEMO_OWNER_BIZ", dept="企業管理學系", degree="BACHELOR", year=3,
         note="發案方：創業競賽需要網站 Demo", force={"商業企劃": 92, "簡報設計": 88}),
    dict(tag="DEMO_FE_STRONG", dept="資訊工程學系", degree="BACHELOR", year=3,
         note="推薦第 1 名：前端強、時間足、跨學院", force={"Vue": 95, "JavaScript": 93, "HTML/CSS": 91}),
    dict(tag="DEMO_BE_STRONG", dept="資訊工程學系", degree="BACHELOR", year=4,
         note="後端強、有全國得獎", force={"Spring Boot": 94, "Java": 92, "SQL": 90}),
    dict(tag="DEMO_DATAVIZ", dept="統計學系", degree="BACHELOR", year=3,
         note="專題缺資料視覺化夥伴：同學院不同系", force={"資料視覺化": 93, "統計": 90}),
    dict(tag="DEMO_UIUX", dept="創意設計學系", degree="BACHELOR", year=2,
         note="短期 UI/UX 支援人選", force={"UI/UX 設計": 94, "Figma": 92}),
    dict(tag="DEMO_TIME_BLOCKED", dept="創意設計學系", degree="BACHELOR", year=4,
         note="技能符合但每週僅 2 小時 → 被時間閘門擋下", force={"UI/UX 設計": 91, "Figma": 90}, hours=2),
    dict(tag="DEMO_LOW_CRED", dept="資訊工程學系", degree="BACHELOR", year=2,
         note="自評上調幅度大，Demo 結案後相符度低 → 可信度係數下降", force={"Vue": 72}, self_boost=2),
    dict(tag="DEMO_PHD_OWNER", dept="資訊工程學系", degree="PHD", year=3,
         note="研究協作發案方：需要問卷與統計支援", force={"研究方法": 93, "機器學習": 91}),
]

def student_no(degree, entry_year, seq):
    prefix = {"BACHELOR": "D", "MASTER": "M", "PHD": "P"}[degree]
    return f"{prefix}{(entry_year - 1911) % 100:02d}{seq:05d}"  # 虛構格式

def expected_grad(degree, year):
    total = {"BACHELOR": 4, "MASTER": 2, "PHD": 4}[degree]
    remaining = max(total - year, 0)
    return date(ACADEMIC_YEAR_START + remaining + 1, 6, 30)

students, used_names = [], set()
dept_list = [(c, d) for c, ds in COLLEGES.items() for d in ds]
dept_id = {d: i + 1 for i, (_, d) in enumerate(dept_list)}
college_of = {d: c for c, d in dept_list}

plan = PLAN[:]
rng.shuffle(plan)
personas = DEMO_PERSONAS[:]

for i in range(50):
    persona = personas.pop(0) if personas else None
    if persona:
        degree, year, dept = persona["degree"], persona["year"], persona["dept"]
        plan.remove((degree, year)) if (degree, year) in plan else plan.pop()
    else:
        degree, year = plan.pop()
        dept = rng.choice(list(COURSES.keys()))
    while True:
        name = rng.choice(SURNAMES) + rng.choice(GIVEN)
        if name not in used_names:
            used_names.add(name); break
    entry_year = ACADEMIC_YEAR_START - (year - 1)
    sid = i + 1
    s = dict(id=sid, student_no=student_no(degree, entry_year, 100 + sid), name=name,
             email=f"student{sid:03d}@example.edu", degree=degree, year=year, entry_year=entry_year,
             dept=dept, dept_id=dept_id[dept], college=college_of[dept],
             expected_graduation=expected_grad(degree, year).isoformat(),
             demo_tag=persona["tag"] if persona else None,
             demo_note=persona["note"] if persona else None)

    # 可投入時間（D4 時間閘門）
    s["hours_per_week"] = persona.get("hours") if persona and "hours" in persona else rng.choice([4, 6, 8, 10, 12, 15, 20])
    s["available_from"] = TODAY.isoformat()
    s["available_to"] = date(2027, rng.choice([1, 3, 6]), 30 if rng.random() < .5 else 28).isoformat()

    # 修課成績：本系課程 + 研究所課程 + 1–2 門跨系選修
    own = COURSES[dept]
    n_own = min(len(own), {1: 2, 2: 3, 3: 4, 4: 5}.get(year, 4) if degree == "BACHELOR" else len(own))
    taken = rng.sample(own, n_own)
    if degree != "BACHELOR":
        taken += GRAD_COURSES[: 2 if degree == "MASTER" else 3]
    other_dept = rng.choice([d for d in COURSES if d != dept])
    taken += rng.sample(COURSES[other_dept], 1 if rng.random() < .6 else min(2, len(COURSES[other_dept])))

    force = persona.get("force", {}) if persona else {}
    grades = []
    base = rng.gauss(80, 7)
    for cname, skl in taken:
        hit = [force[k] for k in skl if k in force]
        score = hit[0] if hit else int(max(55, min(99, rng.gauss(base, 8))))
        sem = f"{ACADEMIC_YEAR_START - 1911 - rng.randint(0, max(year - 1, 0))}-{rng.choice([1, 2])}"
        grades.append(dict(course=cname, score=score, semester=sem, skills=skl))
    # 確保 persona 指定技能都有對應成績
    for k, sc in force.items():
        if not any(k in g["skills"] for g in grades):
            grades.append(dict(course=f"{k} 專題實作", score=sc, semester="114-2", skills=[k]))
    s["grades"] = grades

    # 技能檔：由成績換算預設等級，取該技能最高分；學生可自評調整（D10）
    skill_map = {}
    for g in grades:
        lv = to_level(g["score"], degree)
        for k in g["skills"]:
            if k not in skill_map or lv > skill_map[k]["default_level"]:
                skill_map[k] = dict(skill=k, default_level=lv, source="GRADE", semester=g["semester"])
    # 課外自學技能（無成績對應）
    for k in rng.sample([x[0] for x in SKILLS], rng.randint(0, 2)):
        if k not in skill_map:
            skill_map[k] = dict(skill=k, default_level=None, source="SELF")
    for k, v in skill_map.items():
        if v["source"] == "SELF":
            v["level"] = rng.randint(2, 4)
        else:
            boost = persona.get("self_boost", 0) if persona else (1 if rng.random() < .15 else 0)
            v["level"] = min(5, v["default_level"] + boost)
        v["adjustment"] = 0 if v["default_level"] is None else v["level"] - v["default_level"]
    s["skills"] = list(skill_map.values())

    # 得獎紀錄（D8、D41）：學士 35%、碩士 50%、博士 70% 機率
    p = {"BACHELOR": .35, "MASTER": .5, "PHD": .7}[degree]
    if persona and persona["tag"] in ("DEMO_BE_STRONG", "DEMO_UIUX", "DEMO_PHD_OWNER"):
        p = 1.0
    awards = []
    if rng.random() < p:
        for comp, lvl, cskills in rng.sample(COMPETITIONS, rng.randint(1, 2)):
            rank = rng.choices(RANKS, weights=[1, 2, 3, 4])[0]
            awards.append(dict(competition=comp, level=lvl, rank=rank,
                               award_date=date(rng.randint(max(entry_year, 2023), 2026), rng.randint(1, 10), rng.randint(1, 28)).isoformat(),
                               skills=cskills, score=AWARD_MATRIX[(rank, lvl)]))
    if persona and persona["tag"] == "DEMO_BE_STRONG":
        awards = [dict(competition="全國大專校院程式競賽", level="NATIONAL", rank="FIRST",
                       award_date="2026-05-18", skills=["Java", "Python"], score=0.8)]
    s["awards"] = awards
    s["award_score"] = round(min(1.0, sum(a["score"] for a in awards)), 3)
    # 冷啟動：尚無互評 → 互評分數 0.5；R = 0.75×0.5 + 0.25×得獎分數
    s["r_cold_start"] = round(0.75 * 0.5 + 0.25 * s["award_score"], 4)
    students.append(s)

# 學期校正（不動亂數序列）：示範時間是 115 學年度上學期，已有成績的最後一個學期是 114-2。
# 二年級以上把 115-x 往前挪一年；一年級（115 入學）只有進行中的 115-1。
for s in students:
    for g in s["grades"]:
        y, t = g["semester"].split("-")
        if int(y) >= 115:
            g["semester"] = "115-1" if s["year"] == 1 else f"114-{t}"

# ---------- 證據：證照、作品集、自我評估（用另一顆亂數，不影響上面的序列） ----------
def portfolio_url(s, n): return f"https://example.edu/portfolio/{s['student_no'].lower()}/{n}"
for s in students:
    creds, tag = [], s["demo_tag"]
    best = {}                                   # 技能 → 課程成績換算後的最高分
    for g in s["grades"]:
        for k in g["skills"]:
            best[k] = max(best.get(k, 0), common_score(g["score"], s["degree"]))
    s["course_best"] = best
    for k in s["skills"]:
        if k["source"] == "SELF":               # 課外自學：作品集（附連結）或自我評估
            tier = {2: 1, 3: 2, 4: 3}[k["level"]]
            if ev_rng.random() < .55:
                creds.append(dict(type="PORTFOLIO", title=f"作品集：{k['skill']} 個人專案", tier=tier, skills=[k["skill"]],
                                  verified=ev_rng.random() < .35, on=f"2026-{ev_rng.randint(2, 9):02d}-{ev_rng.randint(1, 28):02d}"))
            else:
                creds.append(dict(type="SELF", title=f"自我評估：{k['skill']}", tier=tier, skills=[k["skill"]], verified=False, on="2026-09-20"))
        elif k["adjustment"] and not tag:       # 自評上調：比課程成績高一階的自我評估
            tier = min(3, tier_of(best.get(k["skill"], 0)) + 1)
            if tier > tier_of(best.get(k["skill"], 0)):
                creds.append(dict(type="SELF", title=f"自我評估：{k['skill']}", tier=tier, skills=[k["skill"]], verified=False, on="2026-09-20"))
    if tag in PERSONA_EVIDENCE:
        creds += [dict(c) for c in PERSONA_EVIDENCE[tag]]
    elif not tag and ev_rng.random() < .45:     # 約四成五的學生有一到兩張證照，半數已驗證
        for name in ev_rng.sample(CERTS[s["dept"]], 2 if ev_rng.random() < .2 else 1):
            creds.append(dict(type="CERTIFICATE", catalog=name, verified=ev_rng.random() < .5,
                              on=f"{ev_rng.choice([2025, 2026])}-{ev_rng.randint(1, 9):02d}-{ev_rng.randint(1, 28):02d}"))
    # AI 與專題相關的課外證據（第三顆亂數，不影響前面已產生的證據）：讓競賽常見的需求技能在示範學生中有人具備
    if not tag:
        tech = s["dept"] in ("資訊工程學系", "電機工程學系", "統計學系", "工業工程與系統管理學系")
        day = lambda: f"2026-{ai_rng.randint(2, 10):02d}-{ai_rng.randint(1, 28):02d}"
        if tech and ai_rng.random() < .35:
            creds.append(dict(type="PORTFOLIO", title=ai_rng.choice(["作品集：課程筆記問答機器人（RAG）", "作品集：LINE 客服聊天機器人（LLM API）", "作品集：會議紀錄摘要 Agent"]),
                              tier=ai_rng.choice([1, 2, 2, 3]), skills=["生成式 AI 應用", "Python"], verified=ai_rng.random() < .3, on=day()))
        if tech and ai_rng.random() < .3:
            creds.append(dict(type="PORTFOLIO", title=ai_rng.choice(["作品集：瑕疵影像分類（CNN）", "作品集：中文新聞情緒分析（Transformer）", "作品集：手寫數字辨識"]),
                              tier=ai_rng.choice([1, 2, 2, 3]), skills=["深度學習", "機器學習"], verified=ai_rng.random() < .3, on=day()))
        if not tech and ai_rng.random() < .25:
            creds.append(dict(type="SELF", title="自我評估：生成式 AI 應用", tier=ai_rng.choice([1, 1, 2]), skills=["生成式 AI 應用"], verified=False, on="2026-09-20"))
        if s["year"] >= 3 and ai_rng.random() < .45:
            creds.append(dict(type="PORTFOLIO", title="作品集：" + ("畢業專題" if s["degree"] == "BACHELOR" else "研究計畫") + "成果報告", tier=ai_rng.choice([2, 2, 3]),
                              skills=["專題與實作"] + (["研究方法"] if s["degree"] != "BACHELOR" else []), verified=ai_rng.random() < .4, on=day()))
    for n, c in enumerate(creds, 1):
        if c["type"] != "SELF": c["proof_url"] = portfolio_url(s, f"{'cert' if c['type'] == 'CERTIFICATE' else 'work'}-{n}")
    s["credentials"] = creds
    for a in s["awards"]:                       # 得獎：四成附證明且已驗證；示範人物的全國第一名已驗證
        a["verified"] = tag == "DEMO_BE_STRONG" or ev_rng.random() < .4
        a["proof_url"] = portfolio_url(s, "award-" + a["award_date"]) if a["verified"] or ev_rng.random() < .3 else None

# ---------- 輸出 JSON / CSV ----------
with open(os.path.join(OUT_DIR, "students.json"), "w", encoding="utf-8") as f:
    json.dump(dict(seed=SEED, generated_for="Demo", students=students), f, ensure_ascii=False, indent=2)

with open(os.path.join(OUT_DIR, "students_summary.csv"), "w", encoding="utf-8-sig", newline="") as f:
    w = csv.writer(f)
    w.writerow(["id", "學號", "姓名", "學制", "年級", "學院", "系所", "預計畢業", "每週時數",
                "修課數", "證照", "作品集", "自我評估", "得獎數", "已驗證證據", "得獎分數", "冷啟動R", "Demo角色", "Demo說明"])
    for s in students:
        cnt = lambda t: sum(1 for c in s["credentials"] if c["type"] == t)
        w.writerow([s["id"], s["student_no"], s["name"], s["degree"], s["year"], s["college"], s["dept"],
                    s["expected_graduation"], s["hours_per_week"], len(s["grades"]), cnt("CERTIFICATE"), cnt("PORTFOLIO"), cnt("SELF"),
                    len(s["awards"]), sum(1 for c in s["credentials"] if c["verified"]) + sum(1 for a in s["awards"] if a["verified"]),
                    s["award_score"], s["r_cold_start"], s["demo_tag"] or "", s["demo_note"] or ""])

# ---------- 輸出 PostgreSQL ----------
def q(v):
    if v is None: return "NULL"
    if isinstance(v, (int, float)): return str(v)
    return "'" + str(v).replace("'", "''") + "'"

L = []
L.append("-- 跨系資源媒合平台 Demo 種子資料（PostgreSQL）— 由 generate_seed.py 產生，seed=%d\n" % SEED)
for c in COLLEGES:
    L.append(f"INSERT INTO colleges (name) VALUES ({q(c)});")
for c, d in dept_list:
    L.append(f"INSERT INTO departments (college_id, name) SELECT id, {q(d)} FROM colleges WHERE name={q(c)};")
for n, cat in SKILLS:
    L.append(f"INSERT INTO skills (name, category) VALUES ({q(n)}, {q(cat)});")
for (rk, lvl), sc in AWARD_MATRIX.items():
    L.append(f"INSERT INTO award_matrix VALUES ({q(rk)}, {q(lvl)}, {sc});")

# 課程（含 persona 補的專題實作課，掛在學生本系）
course_keys = {}
def add_course(dept, name, skl, grad=False):
    key = (None if grad else dept, name)
    if key in course_keys: return
    course_keys[key] = skl
    dsel = "NULL" if grad else f"(SELECT id FROM departments WHERE name={q(dept)})"
    L.append(f"INSERT INTO courses (department_id, name, is_graduate) VALUES ({dsel}, {q(name)}, {'TRUE' if grad else 'FALSE'});")
    for k in skl:
        L.append(f"INSERT INTO course_skill_map SELECT c.id, s.id FROM courses c, skills s WHERE c.name={q(name)} AND c.department_id {'IS NULL' if grad else '= (SELECT id FROM departments WHERE name=' + q(dept) + ')'} AND s.name={q(k)};")
for d, cs in COURSES.items():
    for n, skl in cs:
        add_course(d, n, skl)
for n, skl in GRAD_COURSES:
    add_course(None, n, skl, grad=True)
grad_names = {n for n, _ in GRAD_COURSES}
course_dept = {}
for d, cs in COURSES.items():
    for n, _ in cs:
        course_dept.setdefault(n, d)
for s in students:
    for g in s["grades"]:
        if g["course"].endswith("專題實作"):
            add_course(s["dept"], g["course"], g["skills"])
            course_dept[g["course"]] = s["dept"]

# 示範密碼統一為 demo1234（BCrypt 雜湊由後端啟動時產生；此處放占位字串）
for s in students:
    L.append(f"INSERT INTO users (student_no, name, email, password_hash, degree, year, department_id, entry_year, expected_graduation, demo_tag) "
             f"VALUES ({q(s['student_no'])}, {q(s['name'])}, {q(s['email'])}, '{{RESET_ON_BOOT}}', {q(s['degree'])}, {s['year']}, "
             f"(SELECT id FROM departments WHERE name={q(s['dept'])}), {s['entry_year'] - 1911}, {q(s['expected_graduation'])}, {q(s['demo_tag'])});")
    uid = f"(SELECT id FROM users WHERE student_no={q(s['student_no'])})"
    L.append(f"INSERT INTO user_availability VALUES ({uid}, {s['hours_per_week']}, {q(s['available_from'])}, {q(s['available_to'])});")
    for g in s["grades"]:
        if g["course"] in grad_names:
            csel = f"(SELECT id FROM courses WHERE name={q(g['course'])} AND department_id IS NULL)"
        else:
            csel = f"(SELECT id FROM courses WHERE name={q(g['course'])} AND department_id=(SELECT id FROM departments WHERE name={q(course_dept[g['course']])}))"
        L.append(f"INSERT INTO user_grades (user_id, course_id, score, semester) VALUES ({uid}, {csel}, {g['score']}, {q(g['semester'])}) ON CONFLICT DO NOTHING;")
    for a in s["awards"]:
        L.append(f"WITH a AS (INSERT INTO user_awards (user_id, competition, level, rank, award_date, proof_url, verified) VALUES ({uid}, {q(a['competition'])}, {q(a['level'])}, {q(a['rank'])}, {q(a['award_date'])}, {q(a['proof_url'])}, {'TRUE' if a['verified'] else 'FALSE'}) RETURNING id) "
                 f"INSERT INTO award_skills SELECT a.id, s.id FROM a, skills s WHERE s.name IN ({', '.join(q(x) for x in a['skills'])});")

# ---------- data-post.sql：參考資料（57 項技能、證照對照表）載入後才能寫的證據 ----------
P = ["-- 示範資料（二）：證照、作品集、自我評估 — 由 generate_seed.py 產生；在 ref-*.sql 之後載入", "BEGIN;"]
ADMIN = "(SELECT id FROM users WHERE email='admin@example.edu')"
for s in students:
    uid = f"(SELECT id FROM users WHERE student_no={q(s['student_no'])})"
    for c in s["credentials"]:
        ver = f"TRUE, {ADMIN}, {q(c['on'] + 'T12:00:00+08')}" if c["verified"] else "FALSE, NULL, NULL"
        if c["type"] == "CERTIFICATE":
            P.append(f"WITH c AS (INSERT INTO user_credentials (user_id, type, title, issuer, obtained_on, catalog_id, claimed_score, proof_url, verified, verified_by, verified_at, created_at) "
                     f"SELECT {uid}, 'CERTIFICATE', cc.name, cc.issuer, {q(c['on'])}, cc.id, cc.score, {q(c.get('proof_url'))}, {ver}, {q(c['on'] + 'T10:00:00+08')} "
                     f"FROM certificate_catalog cc WHERE cc.name={q(c['catalog'])} RETURNING id, catalog_id) "
                     f"INSERT INTO credential_skills SELECT c.id, cs.skill_id FROM c JOIN certificate_catalog_skills cs ON cs.catalog_id = c.catalog_id;")
        else:
            P.append(f"WITH c AS (INSERT INTO user_credentials (user_id, type, title, obtained_on, claimed_score, proof_url, verified, verified_by, verified_at, created_at) "
                     f"VALUES ({uid}, {q(c['type'])}, {q(c['title'])}, {q(c['on'])}, {CLAIM[c['tier']]}, {q(c.get('proof_url'))}, {ver}, {q(c['on'] + 'T10:00:00+08')}) RETURNING id) "
                     f"INSERT INTO credential_skills SELECT c.id, s.id FROM c, skills s WHERE s.name IN ({', '.join(q(x) for x in c['skills'])});")
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "history.py"), encoding="utf-8").read())
with open(OUT_SQL, "w", encoding="utf-8") as f:
    f.write("\n".join(L) + "\n")
P.append("COMMIT;")
with open(OUT_POST, "w", encoding="utf-8") as f:
    f.write("\n".join(P) + "\n")

# ---------- 統計摘要 ----------
from collections import Counter
print("students:", len(students))
print("degree:", Counter(s["degree"] for s in students))
print("college:", Counter(s["college"] for s in students))
print("grades:", sum(len(s["grades"]) for s in students), "awards:", sum(len(s["awards"]) for s in students),
      "credentials:", Counter(c["type"] for s in students for c in s["credentials"]),
      "verified:", sum(1 for s in students for c in s["credentials"] if c["verified"]) + sum(1 for s in students for a in s["awards"] if a["verified"]))
print("demo personas:", [(s["id"], s["name"], s["demo_tag"]) for s in students if s["demo_tag"]])
