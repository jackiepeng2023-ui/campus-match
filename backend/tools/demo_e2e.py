#!/usr/bin/env python3
"""端到端跑一次 Demo 劇本（對應規格書「Demo 劇本」8 步）。用法：python3 demo_e2e.py [http://localhost:8080]"""
import json, sys, urllib.request

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080") + "/api/v1"
PW = "demo1234"

def call(method, path, body=None, token=None, expect=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r:
            status, data = r.status, r.read()
    except urllib.error.HTTPError as e:
        status, data = e.code, e.read()
    out = json.loads(data) if data else None
    if expect is not None and status != expect:
        print(f"FAIL {method} {path} → {status}: {out}"); sys.exit(1)
    return status, out

def login(email):
    s, r = call("POST", "/auth/login", {"account": email, "password": PW}, expect=200)
    return r["token"], r["user"]

def step(n, msg): print(f"\n=== 步驟 {n}：{msg}")

# 重置，確保劇本可重複
admin, _ = login("admin@example.edu")
call("POST", "/admin/reset", {}, admin, 200)

# 示範帳號：student001 企管(發案方) / 002 資工 Vue 5 / 003 資工 Spring Boot / 004 統計 / 005 創設 / 006 創設(2h) / 007 資工 Vue 自評上調 / 008 博士
T = {i: login(f"student{i:03d}@example.edu")[0] for i in range(1, 9)}
meta = call("GET", "/meta", expect=200)[1]
SK = {s["name"]: s["id"] for s in meta["skills"]}

step(1, "企管學生開案「創業競賽需要網站 Demo」：每隊 3 人，前端 Vue≥3、後端 Spring Boot≥3")
s, case = call("POST", "/cases", {
    "title": "創業競賽需要網站 Demo", "type": "COMPETITION", "description": "校園創業競賽決賽需要可操作的網站 Demo",
    "teamSize": 3, "applyDeadline": "2026-11-05", "startDate": "2026-11-06", "endDate": "2026-12-15",
    "roles": [
        {"roleName": "前端", "headcount": 1, "hoursPerWeek": 6, "skills": [{"skillId": SK["Vue"], "minLevel": 3, "isRequired": True}, {"skillId": SK["HTML/CSS"], "minLevel": 2, "isRequired": False}]},
        {"roleName": "後端", "headcount": 1, "hoursPerWeek": 6, "skills": [{"skillId": SK["Spring Boot"], "minLevel": 3, "isRequired": True}]},
    ]}, T[1], 200)
cid = case["id"]; fe, be = case["roles"][0]["id"], case["roles"][1]["id"]
call("POST", f"/cases/{cid}/publish", {}, T[1], 200)
print("案件", cid, "已發布；角色 前端", fe, "後端", be)

step(2, "前端推薦名單：分項分數＋理由")
rec = call("GET", f"/roles/{fe}/recommendations", None, T[1], 200)[1]
for r in rec["recommended"][:5]:
    print(f"  {r['score']:5.1f}  {r['name']}（{r['dept']}）  S={r['breakdown']['S']} T={r['breakdown']['T']} R={r['breakdown']['R']} P={r['breakdown']['P']} C={r['breakdown']['C']}  可信度={r['breakdown']['credibility']}")
    print("         理由：", "；".join(r["reasons"][:4]))
names = [r["name"] for r in rec["recommended"]]
assert "王雅婷" in names and "葉品妍" in names, names
print("  被擋下：", [(b["name"], b["blockedBy"][0]) for b in rec["blocked"][:3]])

step(3, "邀請葉品妍（id 7）加入前端；葉宇翔（id 3）申請後端 → 核准 → 自動 FORMED")
inv = call("POST", f"/roles/{fe}/engagements", {"direction": "INVITE", "userId": 7, "message": "一起來？"}, T[1], 200)[1]
print("  邀請建立，到期", inv["dueAt"], "分數", inv["score"])
# 名額 1，邀請 1 筆待處理 → 再邀請應被擋（D25）
s, r = call("POST", f"/roles/{fe}/engagements", {"direction": "INVITE", "userId": 2}, T[1])
print("  再邀請第二人 →", s, r["message"]); assert s == 409
# 葉品妍接受邀請
call("POST", f"/engagements/{inv['id']}/accept", {}, T[7], 200)
app = call("POST", f"/roles/{be}/engagements", {"direction": "APPLY", "message": "我做過 Spring Boot 專題"}, T[3], 200)[1]
# 發案方核准
d = call("POST", f"/engagements/{app['id']}/accept", {}, T[1], 200)[1]
print("  案件狀態：", d["status"], "成員：", [m["name"] for m in d["members"]]); assert d["status"] == "FORMED"

step(4, "博士生開研究協作「問卷與統計支援」，成果歸屬＝致謝；統計系郭昱辰跨學院加分")
s, rc = call("POST", "/cases", {
    "title": "大學生學習動機問卷研究", "type": "RESEARCH", "description": "需要問卷設計與統計分析支援", "teamSize": 2,
    "applyDeadline": "2026-11-05", "startDate": "2026-11-06", "endDate": "2026-12-20", "attribution": "ACK",
    "roles": [{"roleName": "問卷與統計", "headcount": 1, "hoursPerWeek": 4, "skills": [{"skillId": SK["統計"], "minLevel": 3, "isRequired": True}, {"skillId": SK["資料視覺化"], "minLevel": 2, "isRequired": False}]}]}, T[8], 200)
call("POST", f"/cases/{rc['id']}/publish", {}, T[8], 200)
rec2 = call("GET", f"/roles/{rc['roles'][0]['id']}/recommendations", None, T[8], 200)[1]
top = rec2["recommended"][0]
print("  第 1 名：", top["name"], top["dept"], "C =", top["breakdown"]["C"], "|", [x for x in top["reasons"] if "學院" in x or "系" in x][:1])

step(5, "短期 UI/UX 支援：簡建宏技能符合但每週 2 小時 → 時間閘門擋下並顯示原因")
s, uc = call("POST", "/cases", {
    "title": "短期需要 UI/UX 設計支援", "type": "SHORT_TERM", "description": "兩週內完成 App 介面 mockup", "teamSize": 2,
    "applyDeadline": "2026-11-03", "startDate": "2026-11-04", "endDate": "2026-11-18",
    "roles": [{"roleName": "UI/UX", "headcount": 1, "hoursPerWeek": 4, "skills": [{"skillId": SK["UI/UX 設計"], "minLevel": 3, "isRequired": True}, {"skillId": SK["Figma"], "minLevel": 3, "isRequired": False}]}]}, T[1], 200)
call("POST", f"/cases/{uc['id']}/publish", {}, T[1], 200)
rec3 = call("GET", f"/roles/{uc['roles'][0]['id']}/recommendations", None, T[1], 200)[1]
print("  推薦：", [(r["name"], r["score"]) for r in rec3["recommended"][:3]])
blocked = {b["name"]: b["blockedBy"] for b in rec3["blocked"]}
print("  被擋下：", {k: v for k, v in blocked.items() if k == "簡建宏"}); assert "簡建宏" in blocked
s, r = call("POST", f"/roles/{uc['roles'][0]['id']}/engagements", {"direction": "INVITE", "userId": 6}, T[1])
print("  硬邀請簡建宏 →", s, r["reasons"]); assert s == 422
# 學生端：王子軒看「推薦給我的案件」
mine = call("GET", "/me/recommended-cases", None, T[5], 200)[1]
print("  王子軒的推薦案件：", [(m["caseTitle"], m["score"]) for m in mine[:3]])
# 王子軒申請
a5 = call("POST", f"/roles/{uc['roles'][0]['id']}/engagements", {"direction": "APPLY"}, T[5], 200)[1]

step(6, "時鐘快轉 73 小時：王子軒的申請逾時自動 pass、名額釋放；先驗證提醒在 24 小時前送出")
r = call("POST", "/admin/clock", {"hours": 49}, admin, 200)[1]
print("  +49h 排程結果：", {k: r[k] for k in ("remind", "expire")})
n5 = call("GET", "/me/notifications", None, T[1], 200)[1]
print("  發案方最新通知：", n5["items"][0]["title"])
r = call("POST", "/admin/clock", {"hours": 24}, admin, 200)[1]
print("  +24h 排程結果：", {k: r[k] for k in ("remind", "expire")}); assert r["expire"] >= 1
e5 = [e for e in call("GET", "/me/engagements", None, T[5], 200)[1] if e["id"] == a5["id"]][0]
print("  王子軒的申請狀態：", e5["status"]); assert e5["status"] == "EXPIRED"
st1 = call("GET", "/me", None, T[1], 200)[1]["stats"]
print("  發案方（未審核者）回應率：", st1["responseRate"], "responded/missed =", st1["responded"], st1["missed"])

step(7, "競賽案件：開始執行 → 發案方提出結案 → 成員確認 → CLOSED → 雙盲互評（葉品妍相符度 2 分）")
call("POST", f"/cases/{cid}/start", {}, T[1], 200)
d = call("POST", f"/cases/{cid}/close-requests", {"result": "COMPLETED"}, T[1], 200)[1]
print("  結案申請：", d["status"], "需成員確認", len(d["closeRequest"]["votes"]), "票已投")
rq = d['closeRequest']['id']
d = call("POST", f"/close-requests/{rq}/votes", {"agree": True}, T[3], 200)[1]
print("  葉宇翔同意後狀態：", d["status"], "（2 位成員需 2 票才過半）"); assert d["status"] == "CLOSING"
d = call("POST", f"/close-requests/{rq}/votes", {"agree": True}, T[7], 200)[1]
print("  葉品妍同意後狀態：", d["status"]); assert d["status"] == "CLOSED"
pend = call("GET", f"/cases/{cid}/reviews/pending", None, T[1], 200)[1]
print("  發案方待評：", [p["name"] for p in pend["items"]])
# 三人互評；對葉品妍一致給相符度 2
def review(tok, reviewees):
    body = []
    for rid, name in reviewees:
        low = (name == "葉品妍")
        body.append({"revieweeId": rid, "satisfaction": 3 if low else 5, "matchScore": 2 if low else 5, "onTime": 4 if low else 5, "communication": 4 if low else 5,
                     "comment": "檔案寫 Vue 5 級，實際約 3 級" if low else "合作愉快"})
    call("POST", f"/cases/{cid}/reviews", body, tok, 200)
review(T[1], [(7, "葉品妍"), (3, "葉宇翔")])
review(T[3], [(1, "江筱涵"), (7, "葉品妍")])
me7 = call("GET", "/me", None, T[7], 200)[1]["stats"]
print("  葉品妍尚未送出自己的評價 → 雙盲未公開，可信度仍", me7["credibility"]); assert me7["credibility"] == 1.0
review(T[7], [(1, "江筱涵"), (3, "葉宇翔")])
me7 = call("GET", "/me", None, T[7], 200)[1]["stats"]
print("  雙方送出後公開：葉品妍相符度平均", me7["avgMatch"], "→ 可信度係數", me7["credibility"]); assert me7["credibility"] < 1
recv = call("GET", "/me/reviews", None, T[7], 200)[1]
print("  葉品妍收到：", recv["overall"], "| 單案可見：", [(c["title"], c.get("hidden")) for c in recv["cases"]])

step(8, "再開一個前端案件：葉品妍從名單前段掉下，王雅婷維持")
s, c2 = call("POST", "/cases", {
    "title": "校園活動報名網站", "type": "PROJECT", "teamSize": 2, "applyDeadline": "2026-11-20", "startDate": "2026-11-21", "endDate": "2026-12-31",
    "roles": [{"roleName": "前端", "headcount": 1, "hoursPerWeek": 6, "skills": [{"skillId": SK["Vue"], "minLevel": 3, "isRequired": True}, {"skillId": SK["HTML/CSS"], "minLevel": 2, "isRequired": False}]}]}, T[4], 200)
call("POST", f"/cases/{c2['id']}/publish", {}, T[4], 200)
rec4 = call("GET", f"/roles/{c2['roles'][0]['id']}/recommendations", None, T[4], 200)[1]
order = [(r["name"], r["score"]) for r in rec4["recommended"][:6]]
print("  名單：", order)
pos = {r["name"]: i for i, r in enumerate(rec4["recommended"])}
assert pos["王雅婷"] < pos["葉品妍"] and pos["邱承翰"] < pos["葉品妍"], pos
print("  同樣條件下：步驟 2 葉品妍 74.2 分第 3 名 → 現在", order[pos["葉品妍"]][1], "分第", pos["葉品妍"] + 1, "名（被邱承翰超越）")

step("補", "成長儀表板、AI Prompt、管理分析、隱私")
g = call("GET", "/me/growth", None, T[7], 200)[1]
print("  葉品妍時間軸最新 3 筆：", [t["text"] for t in g["timeline"][:3]])
p = call("POST", "/me/growth-prompt", {"goal": "成為前端工程師", "question": "下學期該補什麼？"}, T[7], 200)[1]
assert "江筱涵" not in p["prompt"] and "檔案寫 Vue" not in p["prompt"] and "創業競賽" not in p["prompt"]
print("  Prompt 長度", len(p["prompt"]), "字，不含隊友姓名、評語、案件名稱 ✓")
pub = call("GET", "/users/7", None, T[1], 200)[1]
assert "grades" not in pub and "score" not in json.dumps(pub["skills"])
print("  公開檔案不含成績 ✓；技能：", [(s["name"], s["level"]) for s in pub["skills"][:3]])
print("  漏斗：", [(f["stage"], f["n"]) for f in call("GET", "/analytics/funnel", None, admin, 200)[1]])
print("  推薦品質：", call("GET", "/analytics/recommendation-quality", None, admin, 200)[1])
print("  跨學院合作前 3：", call("GET", "/analytics/network", None, admin, 200)[1][:3])
# 學生端撤回 / 拒絕 / 權限
s, r = call("POST", f"/cases/{cid}/start", {}, T[2]); assert s == 403
s, r = call("GET", "/users/7", None, None); assert s == 401
print("  權限：非發案方操作 403、未登入 401 ✓")
call("POST", "/admin/clock/reset", {}, admin, 200)
print("\n全部通過：閉環 技能條件 → 推薦排序 → 申請成案 → 成案追蹤 → 評價回饋 → 重新排序 ✓")
