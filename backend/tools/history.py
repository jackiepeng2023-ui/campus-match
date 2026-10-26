# 由 generate_seed.py 以 exec 載入；沿用其變數 students, rng, L, q, SKILL_ID
# 產生：(1) 12 個已結案的歷史案件（含申請、成員、互評），讓評價 R、回應率 P、儀表板一開始就有數據
#       (2) 6 個招募中的案件，讓學生端「推薦給我的案件」一開始就有內容
# Demo 角色 1, 4–8 不放歷史紀錄，確保劇本可預期；id 2、3 各有一筆良好紀錄

hist_rng = random.Random(SEED + 1)
by_id = {s["id"]: s for s in students}
pool = [s["id"] for s in students if not s["demo_tag"]]  # 9..50
case_id = 0
role_id = 0

def top_skills(uid, n=2):
    sk = sorted(by_id[uid]["skills"], key=lambda k: -k["level"])
    return [k for k in sk[:n]]

TITLES = {
    "PROJECT": ["校園二手書交換 App", "社團活動報名系統", "宿舍報修平台", "選課推薦工具", "校園導覽小程式"],
    "COMPETITION": ["智慧零售提案", "永續校園黑客松作品", "數位行銷企劃競賽", "資料分析挑戰賽"],
    "SHORT_TERM": ["社團海報設計支援", "問卷資料整理", "成果發表簡報美化"],
    "RESEARCH": ["使用者行為問卷研究", "校園能源資料分析"],
}

def add_case(owner, ctype, title, status, deadline, start, end, members_roles, closed_at=None, result=None):
    """members_roles: list of (uid, role_name, skill_name, hours)"""
    global case_id, role_id
    case_id += 1
    cid = case_id
    attr = "'ACK'" if ctype == "RESEARCH" else "NULL"
    L.append(f"INSERT INTO cases (owner_id, title, type, description, team_size, apply_deadline, start_date, end_date, attribution, status, close_result, created_at, closed_at) "
             f"VALUES ({owner}, {q(title)}, {q(ctype)}, {q('Demo 歷史資料')}, {len(members_roles) + 1}, {q(deadline)}, {q(start)}, {q(end)}, {attr}, {q(status)}, {q(result)}, {q(deadline)}, {q(closed_at)});")
    L.append(f"INSERT INTO case_members (case_id, user_id, is_owner, joined_at) VALUES ({cid}, {owner}, TRUE, {q(deadline)});")
    rids = []
    for uid, rname, sname, hours in members_roles:
        role_id += 1
        rids.append(role_id)
        filled = 1 if uid else 0
        L.append(f"INSERT INTO case_roles (case_id, role_name, headcount, filled_count, hours_per_week) VALUES ({cid}, {q(rname)}, 1, {filled}, {hours});")
        L.append(f"INSERT INTO case_role_skills VALUES ({role_id}, {SKILL_ID[sname]}, 3, TRUE);")
        if uid:
            L.append(f"INSERT INTO case_members (case_id, user_id, case_role_id, joined_at) VALUES ({cid}, {uid}, {role_id}, {q(deadline)});")
    return cid, rids

# ---------- (1) 歷史已結案案件 ----------
hist_members = []
special = [2, 3]
for i in range(12):
    owner = hist_rng.choice(pool)
    others = [u for u in pool if u != owner]
    m = hist_rng.sample(others, 2)
    if i < len(special):
        m[0] = special[i]
    ctype = hist_rng.choice(list(TITLES))
    title = hist_rng.choice(TITLES[ctype]) + f"（{2026}春）"
    mon = hist_rng.randint(3, 6)
    deadline = f"2026-{mon:02d}-05T12:00:00+08"
    start, end = f"2026-{mon:02d}-08", f"2026-{mon + 1:02d}-20"
    closed = f"2026-{mon + 1:02d}-25T18:00:00+08"
    roles = []
    for uid in m:
        ts = top_skills(uid, 1)
        roles.append((uid, ts[0]["skill"] if ts else "專案管理", ts[0]["skill"] if ts else "專案管理", hist_rng.choice([4, 6, 8])))
    cid, rids = add_case(owner, ctype, title, "CLOSED", deadline, start, end, roles, closed_at=closed, result="COMPLETED")
    for (uid, *_), rid in zip(roles, rids):
        direction = hist_rng.choice(["APPLY", "INVITE"])
        L.append(f"INSERT INTO engagements (case_role_id, user_id, direction, status, due_at, created_at, decided_at) "
                 f"VALUES ({rid}, {uid}, {q(direction)}, 'ACCEPTED', '2026-{mon:02d}-04T12:00:00+08', '2026-{mon:02d}-01T12:00:00+08', '2026-{mon:02d}-02T12:00:00+08');")
    team = [owner] + m
    for a in team:
        for b in team:
            if a == b:
                continue
            good = b in special
            sat = hist_rng.choice([4, 5, 5]) if good else hist_rng.choice([3, 4, 4, 5])
            match = hist_rng.choice([4, 5]) if good else hist_rng.choice([3, 4, 4, 5])
            on_time = hist_rng.choice([4, 5]) if good else hist_rng.choice([3, 4, 5])
            comm = hist_rng.choice([4, 5]) if good else hist_rng.choice([3, 4, 5])
            L.append(f"INSERT INTO reviews (case_id, reviewer_id, reviewee_id, satisfaction, match_score, on_time, communication, comment, due_at, submitted_at, revealed_at) "
                     f"VALUES ({cid}, {a}, {b}, {sat}, {match}, {on_time}, {comm}, NULL, {q(closed)}, {q(closed)}, {q(closed)});")
    hist_members += m

# 兩位成員被評為「能力與檔案不符」，示範可信度係數 < 1（不含 Demo 角色）
for uid in hist_rng.sample([u for u in set(hist_members) if u not in special], 2):
    L.append(f"UPDATE reviews SET match_score = 2 WHERE reviewee_id = {uid};")

# 一些過期未回應的邀請，讓回應率 P 有差異
for uid in hist_rng.sample(pool, 8):
    role = hist_rng.randint(1, role_id)
    L.append(f"INSERT INTO engagements (case_role_id, user_id, direction, status, due_at, created_at, decided_at) "
             f"VALUES ({role}, {uid}, 'INVITE', 'EXPIRED', '2026-05-10T12:00:00+08', '2026-05-07T12:00:00+08', '2026-05-10T12:00:00+08');")

# 歷史結案帶來的技能成長紀錄（D30 時間軸）
for uid in sorted(set(hist_members)):
    for k in top_skills(uid, 1):
        if k["level"] < 5:
            L.append(f"INSERT INTO skill_level_history (user_id, skill_id, old_level, new_level, reason, changed_at) "
                     f"VALUES ({uid}, {SKILL_ID[k['skill']]}, {k['level']}, {k['level']}, 'CASE_CLOSED', '2026-07-25T18:00:00+08');")

# ---------- (2) 招募中的案件 ----------
OPEN_CASES = [
    ("COMPETITION", "智慧城市黑客松組隊", [("前端", "Vue", 6), ("資料分析", "資料分析", 4)]),
    ("PROJECT", "校園失物招領 App 專題", [("iOS 開發", "SwiftUI", 6), ("後端", "Spring Boot", 6)]),
    ("SHORT_TERM", "社團成果展海報設計", [("視覺設計", "平面設計", 4)]),
    ("RESEARCH", "大學生學習動機問卷研究", [("問卷與統計", "統計", 4)]),
    ("COMPETITION", "金融科技創新提案", [("財務分析", "財務分析", 4), ("簡報設計", "簡報設計", 4)]),
    ("PROJECT", "選課評價資料視覺化", [("資料視覺化", "資料視覺化", 6), ("後端", "Python", 6)]),
]
open_owners = hist_rng.sample(pool, len(OPEN_CASES))
for (ctype, title, roles), owner in zip(OPEN_CASES, open_owners):
    add_case(owner, ctype, title, "OPEN", "2026-11-06T23:59:00+08", "2026-11-09", "2026-12-20",
             [(None, rname, sname, hrs) for rname, sname, hrs in roles])

L.append(f"SELECT setval('cases_id_seq', {case_id});")
L.append(f"SELECT setval('case_roles_id_seq', {role_id});")
print("history cases:", 12, "open cases:", len(OPEN_CASES), "roles:", role_id)

# ---------- 管理員帳號 ----------
L.append("INSERT INTO users (student_no, name, email, password_hash, degree, year, department_id, expected_graduation, role) "
         "VALUES ('ADMIN', '系統管理員', 'admin@example.edu', '{RESET_ON_BOOT}', 'MASTER', 1, 1, '2030-06-30', 'ADMIN');")
# 全員註冊同意紀錄（D26）
L.append("INSERT INTO consents (user_id, purpose, terms_version) SELECT id, 'MATCHING', 'v1' FROM users;")
L.append("INSERT INTO consents (user_id, purpose, terms_version) SELECT id, 'RETENTION', 'v1' FROM users;")
