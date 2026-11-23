#!/usr/bin/env python3
"""
NAPAI 版端到端測試：AI 助理入口＋三個媒合 Agent＋能力盤點＋待確認動作＋治理機制。

  # 1. 啟動測試替身與後端（LLM 模式走測試替身；沒有金鑰也能跑）
  python3 tools/mock_anthropic.py 8089 &
  APP_ANTHROPIC_BASE_URL=http://localhost:8089 APP_ANTHROPIC_API_KEY=test-key java -jar target/campus-match-1.0.0.jar &
  # 2. 執行
  python3 tools/napai_e2e.py [http://localhost:8080] [http://localhost:8089]

涵蓋：多步驟工具呼叫（含同一輪兩個工具）、跨回合脈絡、工具錯誤後修正、輪數上限中止、拒答、429 重試、5xx 降級為規則模式、
輸出檢核、去識別化（送出的請求不含任何學生姓名／學號／Email）、同意與撤回、每日上限、人工確認才執行、重複確認與越權、
操作軌跡匯出、評測指標、競賽與教師資料的管理。
"""
import datetime, json, os, re, sys, time, urllib.parse, urllib.request

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080") + "/api/v1"
MOCK = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8089"
PW = os.environ.get("APP_DEMO_PASSWORD", "demo1234")
PASSED = []


def http(method, url, body=None, token=None):
    req = urllib.request.Request(url, method=method, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r: status, data = r.status, r.read()
    except urllib.error.HTTPError as e: status, data = e.code, e.read()
    return status, (json.loads(data) if data else None)


def call(method, path, body=None, token=None, expect=None):
    status, out = http(method, BASE + path, body, token)
    if expect is not None and status != expect:
        print(f"FAIL {method} {path} → {status}: {out}"); sys.exit(1)
    return status, out


def login(email): return call("POST", "/auth/login", {"account": email, "password": PW}, expect=200)[1]["token"]
def ok(name, cond, detail=""):
    if not cond: print(f"FAIL {name} {detail}"); sys.exit(1)
    PASSED.append(name); print(f"  ✓ {name}" + (f"　{detail}" if detail else ""))
def step(n, msg): print(f"\n=== {n}：{msg}")


def ask(token, text, sid=None):
    s, r = call("POST", "/assistant/messages", {"sessionId": sid, "text": text}, token, 200)
    for _ in range(600):
        time.sleep(0.2)
        m = call("GET", f"/assistant/messages/{r['assistantMessageId']}", None, token, 200)[1]
        if m["status"] != "RUNNING": return m, r["sessionId"]
    print("FAIL 助理逾時"); sys.exit(1)


def mock_requests(): return http("GET", MOCK + "/__requests")[1]
def mock_reset(): http("POST", MOCK + "/__reset", {})


admin = login("admin@example.edu")
call("POST", "/admin/reset", {}, admin, 200)
mock_reset()
T2, T5, T50 = login("student002@example.edu"), login("student005@example.edu"), login("student050@example.edu")
me2 = call("GET", "/me", None, T2, 200)[1]
students = call("GET", "/analytics/overview", None, admin, 200)[1]["students"]
mine_before = {2: len(call("GET", "/cases?mine=true", None, T2, 200)[1]), 50: len(call("GET", "/cases?mine=true", None, T50, 200)[1])}

step(1, "狀態：已設定金鑰且同意 → LLM 模式；工具白名單 7 個")
st = call("GET", "/assistant/status", None, T2, 200)[1]
ok("LLM 模式", st["mode"] == "LLM" and st["llmEnabled"] and st["aiConsent"], st["model"])
ok("工具白名單", len(st["tools"]) == 7 and not any("delete" in t["name"] or "send" in t["name"] for t in st["tools"]))

step(2, "一句話完成多步驟任務：能力盤點 → 推薦競賽 → 互補隊友 → 指導老師 → 待確認動作")
m, sid = ask(T2, "我想參加比賽，幫我規劃")
tools = [s["tool"] for s in m["steps"]]
print("  ", m["mode"], m["stop"], f"{m['durationMs']}ms", "LLM 呼叫", m["llmCalls"], "工具", tools)
ok("LLM 回合正常結束", m["mode"] == "LLM" and m["stop"] == "END_TURN" and m["status"] == "DONE")
ok("五個工具、依序推進", tools == ["get_my_skill_profile", "recommend_competitions", "recommend_teammates", "recommend_teachers", "draft_team_case"])
ok("同一輪兩個工具（平行）也能處理", m["llmCalls"] == 5 and m["toolCalls"] == 5 and m["toolErrors"] == 0)
ok("卡片由伺服器組成", [c["type"] for c in m["cards"]] == ["profile", "competitions", "teammates", "teachers", "action"])
ok("輸出檢核通過", m["checks"]["ok"] and m["checks"]["checked"] >= 2, str(m["checks"]))
comp = m["cards"][1]["recommended"][0]
team = m["cards"][2]
action = m["cards"][4]
pick = team["suggestedTeam"]["picks"][0]
ok("回覆中的代號已換成姓名", pick["name"] in m["content"] and "[[S" not in m["content"], pick["name"])
ok("優點／弱項／缺口分開", comp["strengths"] and comp["gaps"] is not None and "能力缺口" in m["content"])
ok("教師附待確認條件", all(t["toConfirm"] for t in m["cards"][3]["teachers"]))
ok("動作待確認、尚未建立案件", action["status"] == "PENDING" and len(call("GET", "/cases?mine=true", None, T2, 200)[1]) == mine_before[2])
def array_dates(v, path=""):
    """找出被寫成 [2026, 11, 20] 的日期（應為 "2026-11-20"）"""
    if isinstance(v, dict): return [x for k, y in v.items() for x in array_dates(y, f"{path}.{k}")]
    if isinstance(v, list):
        if len(v) in (3, 6, 7) and all(isinstance(x, int) and not isinstance(x, bool) for x in v) and 2000 <= v[0] <= 2100 and 1 <= v[1] <= 12: return [path]
        return [x for i, y in enumerate(v) for x in array_dates(y, f"{path}[{i}]")]
    return []
bad = array_dates(m["cards"])
ok("卡片裡的日期都是 ISO 字串", not bad and re.fullmatch(r"\d{4}-\d{2}-\d{2}", comp["applyDeadline"] or "") and re.fullmatch(r"\d{4}-\d{2}-\d{2}", comp["checkedAt"]), str(bad[:3]) or comp["applyDeadline"])

step(3, "去識別化：送到語言模型的請求不含任何學生姓名、學號、Email；其他學生以代號表示")
reqs = mock_requests()
blob = json.dumps([r["body"] for r in reqs], ensure_ascii=False)
people = [call("GET", f"/users/{i}", None, admin, 200)[1]["name"] for i in range(1, students + 1)]
leaked = [n for n in people if n in blob]
ok("請求中沒有學生姓名", not leaked, f"{len(people)} 位學生、{len(reqs)} 個請求")
ok("請求中沒有學號與 Email", me2["studentNo"] not in blob and "@example.edu" not in blob)
ok("其他學生以代號出現", "[[S1]]" in blob)
prof = json.loads([b for r in reqs for msg in r["body"]["messages"] if isinstance(msg["content"], list) for b in msg["content"] if b.get("type") == "tool_result" and '"level_scale"' in b["content"]][0]["content"])
ok("Skill Profile 只有階級與可信狀態", all(set(s) == {"skill", "category", "tier", "trust", "evidence"} for s in prof["skills"]))
tool_results = [b["content"] for r in reqs for msg in r["body"]["messages"] if isinstance(msg["content"], list) for b in msg["content"] if b.get("type") == "tool_result"]
ok("工具結果裡的日期都是 ISO 字串", tool_results and not any(re.search(r"\[\s*20\d\d\s*,\s*\d{1,2}\s*,\s*\d{1,2}\s*\]", t) for t in tool_results), f"{len(tool_results)} 筆工具結果")
team_results = [json.loads(t) for t in tool_results if '"candidates"' in t]
ok("候選人只給代號、系所、媒合分數與補位技能（沒有學制年級）", team_results and all(set(c) <= {"student", "department", "college", "score", "fills", "partial", "why", "other"} and re.fullmatch(r"\[\[S\d+\]\]", c["student"]) for tr in team_results for c in tr["candidates"]))
ok("標頭與參數符合 API 規定", all(r["headers"].get("anthropic-version") and "temperature" not in r["body"] and "tool_choice" not in r["body"] for r in reqs))

step(4, "人工確認才執行：確認 → 建立並發布案件、送出邀請；受邀者收到通知並接受")
s, r = call("POST", f"/assistant/actions/{action['actionId']}/confirm", {}, T5); ok("他人不能確認", s == 403)
done = call("POST", f"/assistant/actions/{action['actionId']}/confirm", {}, T2, 200)[1]
ok("動作完成", done["status"] == "DONE" and done["result"]["caseId"], str(done["result"]))
s, r = call("POST", f"/assistant/actions/{action['actionId']}/confirm", {}, T2); ok("重複確認被擋", s == 409, r["message"])
case = call("GET", f"/cases/{done['result']['caseId']}", None, T2, 200)[1]
ok("案件已發布並連結競賽", case["status"] == "OPEN" and case["competitionId"] == comp["id"], case["title"])
ok("邀請已送出", len(done["result"]["invited"]) == 1 and not done["result"]["failed"], done["result"]["invited"][0]["name"])
inv_uid = done["result"]["invited"][0]["userId"]
Ti = login(f"student{inv_uid:03d}@example.edu")
mine = [e for e in call("GET", "/me/engagements", None, Ti, 200)[1] if e["caseId"] == case["id"]]
ok("受邀者看到邀請", len(mine) == 1 and mine[0]["direction"] == "INVITE" and mine[0]["status"] == "PENDING")
d = call("POST", f"/engagements/{mine[0]['id']}/accept", {}, Ti, 200)[1]
ok("接受後成案", d["status"] == "FORMED", [x["name"] for x in d["members"]])
view = call("GET", f"/assistant/sessions/{sid}", None, T2, 200)[1]
ok("卡片顯示動作結果", view["messages"][-1]["cards"][4]["status"] == "DONE")

step(5, "跨回合脈絡與姓名代號化：下一句只說「誰可以指導」，沿用上一回合的競賽；訊息裡的隊友姓名先換成代號")
m2, _ = ask(T2, f"除了{pick['name']}還有誰？幫我找隊友", sid)
ok("沿用同一競賽", m2["steps"][0]["tool"] == "recommend_teammates" and json.loads(m2["steps"][0]["input"]).get("competition_id") == comp["id"])
last = mock_requests()[-1]["body"]
ok("使用者訊息中的姓名已代號化", pick["name"] not in json.dumps(last, ensure_ascii=False))
ok("歷史訊息合法（含上一回合的工具紀錄）", len(last["messages"]) > 9)

step(6, "依結果修正：工具回傳錯誤 → 模型改用另一個工具完成")
m3, _ = ask(T2, "error-test")
ok("錯誤被記錄並修正", [s["ok"] for s in m3["steps"]] == [False, True] and m3["toolErrors"] == 1 and m3["stop"] == "END_TURN", m3["content"][:40])

step(7, "中止機制：工具呼叫輪數上限、拒答")
m4, _ = ask(T2, "loop-test")
ok("達上限即中止", m4["stop"] == "MAX_STEPS" and m4["toolCalls"] == st["maxSteps"], f"{m4['toolCalls']} 輪")
m5, s5 = ask(T2, "refuse-test")
ok("拒答有固定回覆", m5["stop"] == "REFUSAL" and "無法協助" in m5["content"])
m5b, _ = ask(T2, "我的技能有哪些？", s5)
ok("中止後同一對話仍可繼續", m5b["stop"] == "END_TURN" and m5b["steps"][0]["tool"] == "get_my_skill_profile")

step(8, "失敗回復：429 自動重試一次；5xx 降級為規則模式，功能不中斷")
m6, _ = ask(T2, "429-test 我的技能有哪些？")
ok("429 重試後成功", m6["mode"] == "LLM" and m6["stop"] == "END_TURN")
m7, _ = ask(T2, "500-test 推薦我可以參加的比賽")
ok("5xx → 規則模式", m7["mode"] == "RULE" and m7["stop"] == "FALLBACK" and "規則模式" in m7["notice"] and m7["cards"][0]["type"] == "competitions", m7["notice"])

step(9, "輸出檢核：回覆裡出現工具結果沒有的分數或日期 → 標示")
m8, _ = ask(T2, "bad-number-test")
ok("未能對應的數字被標出", not m8["checks"]["ok"] and len(m8["checks"]["unverified"]) == 2, str(m8["checks"]["unverified"]))

step(10, "同意與撤回：未同意 → 規則模式，沒有任何請求送出")
st50 = call("GET", "/assistant/status", None, T50, 200)[1]
ok("未同意者為規則模式", st50["mode"] == "RULE" and not st50["aiConsent"])
before = len(mock_requests())
m9, s9 = ask(T50, "我想參加比賽，幫我規劃")
ok("規則模式完成同樣的流程", m9["mode"] == "RULE" and m9["stop"] == "RULE" and m9["toolCalls"] >= 4 and "尚未同意" in m9["notice"])
ok("沒有請求送到語言模型", len(mock_requests()) == before)
call("POST", "/me/consents/ai", {"agree": True}, T50, 200)
m10, _ = ask(T50, "我的技能有哪些？", s9)
ok("同意後改用 LLM", m10["mode"] == "LLM")
ok("規則回合的歷史只帶代號", not [n for n in people if n in json.dumps(mock_requests()[-1]["body"], ensure_ascii=False)])
call("POST", "/me/consents/ai", {"agree": False}, T50, 200)
ok("撤回後回到規則模式", ask(T50, "我的技能有哪些？", s9)[0]["mode"] == "RULE")

step(11, "取消動作、每日上限")
m11, _ = ask(T50, "幫我建立組隊案件")
a11 = [c for c in m11["cards"] if c["type"] == "action"]
ok("規則模式也只產生待確認動作", a11 and a11[0]["status"] == "PENDING")
c11 = call("POST", f"/assistant/actions/{a11[0]['actionId']}/cancel", {}, T50, 200)[1]
ok("取消後不建立案件", c11["status"] == "CANCELLED" and len(call("GET", "/cases?mine=true", None, T50, 200)[1]) == mine_before[50])
used = call("GET", "/assistant/status", None, T50, 200)[1]["usedToday"]
call("PUT", "/admin/params", {"params": {"assistant_daily_limit": used}}, admin, 200)
s, r = call("POST", "/assistant/messages", {"text": "再問一題"}, T50); ok("超過每日上限被擋", s == 429 and r["code"] == "DAILY_LIMIT", r["message"])
call("PUT", "/admin/params", {"params": {"assistant_daily_limit": 60}}, admin, 200)

step(12, "回饋、操作軌跡、評測指標")
call("POST", f"/assistant/messages/{m['id']}/feedback", {"value": 1, "note": "一次就找到隊友"}, T2, 200)
tr = call("GET", f"/assistant/sessions/{sid}/trace", None, T2, 200)[1]
steps = [s for x in tr["messages"] if x["role"] == "assistant" for s in x["steps"]]
ok("軌跡含每一步的輸入與輸出", len(steps) >= 6 and all("input" in s and "output" in s and "durationMs" in s for s in steps))
ok("軌跡中的學生是代號", not [n for n in people if n in json.dumps(steps, ensure_ascii=False)])
tra = call("GET", f"/assistant/sessions/{sid}/trace", None, admin, 200)[1]
ok("管理員看不到使用者原文", all("管理員檢視時不顯示" in x["content"] for x in tra["messages"] if x["role"] == "user"))
s, r = call("GET", f"/assistant/sessions/{sid}/trace", None, T5); ok("他人不能看軌跡", s == 403)
pg = call("POST", "/assistant/actions/draft-team", {"competitionId": comp["id"], "inviteUserIds": []}, T5, 200)[1]      # 競賽頁直接起草（不經過助理回合），隨即取消
call("POST", f"/assistant/actions/{pg['id']}/cancel", {}, T5, 200)
mt = call("GET", "/admin/assistant/metrics", None, admin, 200)[1]
t = mt["turns"]
print("   指標：", {k: t[k] for k in ("turns", "successRate", "fallbackRate", "abortRate", "toolSuccessRate", "outputCheckPassRate", "avgLatencyMs", "maxLatencyMs", "llmRetries", "estimatedCostUsd")},
      "人工介入率", mt["actions"]["humanInterventionRate"])
ok("指標齊全", t["turns"] >= 12 and t["fallback"] == 1 and t["aborted"] == 2 and t["llmRetries"] == 1 and mt["actions"]["confirmed"] == 1 and mt["actions"]["cancelled"] == 2 and t["feedbackUp"] == 1)
fb = mt["feedback"]
ok("回饋清單可供場域驗證匯出（不含使用者提問原文）", len(fb) == 1 and fb[0]["value"] == 1 and set(fb[0]) == {"messageId", "sessionId", "value", "note", "mode", "stop", "durationMs", "toolCalls", "createdAt"}, str(fb[0].get("note")))
act = mt["actions"]
ok("人工介入率只算助理回合（競賽頁直接起草的動作另計）", 0 < act["humanInterventionRate"] <= 1 and abs(act["humanInterventionRate"] - act["turnsWithAction"] / t["turns"]) < 0.0006 and act["fromPage"] == 1,
   f'{act["turnsWithAction"]}／{t["turns"]} 回合；競賽頁起草 {act["fromPage"]} 筆')
s, r = call("GET", "/admin/assistant/metrics", None, T2); ok("指標僅管理員可看", s == 403)

step(13, "三個 Agent 也可單獨使用（網頁的競賽、找隊友、找老師頁）")
rc = call("GET", "/agents/competitions?limit=3", None, T5, 200)[1]
ok("競賽 Agent", rc["agent"] == "COMPETITION" and rc["recommended"] and len(rc["trace"]) == 4, f"{rc['recommended'][0]['shortName']} {rc['recommended'][0]['fit']}")
det = call("GET", f"/competitions/{rc['recommended'][0]['id']}", None, T5, 200)[1]
ok("競賽詳情含來源與查證日", det["sourceUrl"] and det["checkedAt"] and "fit" in det)
rt = call("POST", "/agents/teammates", {"skills": [{"skillId": s["id"], "minLevel": 2} for s in call("GET", "/meta", expect=200)[1]["skills"] if s["name"] in ("Python", "資料視覺化")]}, T5, 200)[1]
ok("學生 Agent（自訂需求）", rt["agent"] == "STUDENT" and "gaps" in rt and "suggestedTeam" in rt)
ok("候選人不含分數（D16）", "score" in rt["candidates"][0] and all("score" not in json.dumps(c["fills"]) for c in rt["candidates"]))
rh = call("POST", "/agents/teachers", {"topic": "深度學習 醫療影像", "limit": 3}, T5, 200)[1]
ok("教師 Agent（主題關鍵字）", rh["agent"] == "TEACHER" and rh["teachers"] and all(t["sourceUrl"] for t in rh["teachers"]), rh["teachers"][0]["name"])
tj = json.dumps(call("GET", "/teachers", None, T5, 200)[1], ensure_ascii=False)
ok("教師資料不含 Email 與分機", not re.search(r"[\w.+-]+@[\w-]+\.\w|分機\s*\d", tj), f"{tj.count('profileUrl')} 位")
s, r = call("POST", "/agents/teammates", {}, T5); ok("沒有需求時回 400", s == 400)

step(14, "管理：競賽與教師資料")
SK = {s["name"]: s["id"] for s in call("GET", "/meta", expect=200)[1]["skills"]}
day = lambda n: (datetime.date.today() + datetime.timedelta(days=n)).isoformat()
body = {"name": "校內 AI 創意應用競賽（測試）", "shortName": "校內 AI 創意賽", "organizer": "資訊電機學院", "category": "AI 與資料", "level": "CAMPUS", "teamMin": 2, "teamMax": 4,
        "advisorRequired": False, "applyDeadline": day(20), "eventDate": day(40), "sourceUrl": "https://example.edu/contest", "approved": False,
        "skills": [{"skillId": SK["生成式 AI 應用"], "minLevel": 2, "importance": "CORE"}, {"skillId": SK["簡報設計"], "minLevel": 1, "importance": "SUPPORT"}]}
nc = call("POST", "/admin/competitions", body, admin, 200)[1]
ok("未核准的競賽學生看不到", nc["id"] not in [c["id"] for c in call("GET", "/competitions", None, T5, 200)[1]])
call("PUT", f"/admin/competitions/{nc['id']}/approval", {"approved": True}, admin, 200)
ok("核准後可見", nc["id"] in [c["id"] for c in call("GET", "/competitions?status=open", None, T5, 200)[1]])
s, r = call("POST", "/admin/competitions", {**body, "name": "沒有核心技能", "skills": [{"skillId": SK["簡報設計"], "importance": "SUPPORT"}]}, admin); ok("至少一項核心技能", s == 400)
s, r = call("POST", "/admin/competitions", body, T5); ok("學生不能新增競賽", s == 403)
call("DELETE", f"/admin/competitions/{nc['id']}", None, admin, 200)
dept = call("GET", "/meta", expect=200)[1]["departments"][0]["id"]
s, r = call("POST", "/admin/teachers", {"name": "測試老師", "departmentId": dept, "expertise": "機器學習，聯絡 test@fcu.edu.tw", "skills": []}, admin)
ok("教師資料拒收聯絡方式", s == 400, r["message"])
nt = call("POST", "/admin/teachers", {"name": "測試老師", "title": "助理教授", "departmentId": dept, "expertise": "生成式 AI、提示工程", "sourceUrl": "https://example.edu/t",
                                      "skills": [{"skillId": SK["生成式 AI 應用"], "confidence": 0.9}]}, admin, 200)[1]
ok("新增教師", nt["skills"][0]["name"] == "生成式 AI 應用")
# 教師下架：老師要求不被推薦時，名單、詳情與教師 Agent 都不再出現；恢復後回到名單
need = {"skills": [{"skillId": SK["生成式 AI 應用"], "minLevel": 1, "importance": "CORE"}], "limit": 50}
names = lambda: [t["name"] for t in call("POST", "/agents/teachers", need, T2, 200)[1]["teachers"]]
ok("新教師進入教師 Agent 的推薦", "測試老師" in names())
s, r = call("PUT", f"/admin/teachers/{nt['id']}/active", {"active": False}, T2); ok("學生不能下架教師", s == 403)
off = call("PUT", f"/admin/teachers/{nt['id']}/active", {"active": False}, admin, 200)[1]
listed = [t["id"] for t in call("GET", "/teachers?q=" + urllib.parse.quote("測試老師"), None, T2, 200)[1]]
s, r = call("GET", f"/teachers/{nt['id']}", None, T2)
ok("下架後名單、詳情、推薦都不再出現", off["active"] is False and nt["id"] not in listed and s == 404 and "測試老師" not in names())
s, r = call("POST", "/assistant/actions/draft-team", {"competitionId": comp["id"], "inviteUserIds": [], "advisorTeacherId": nt["id"]}, T5)
ok("已下架的教師不能被帶入案件草稿", s == 404, r.get("message", ""))
on = call("PUT", f"/admin/teachers/{nt['id']}/active", {"active": True}, admin, 200)[1]
ok("恢復後回到推薦", on["active"] is True and "測試老師" in names())

# 刪除對話：本人可刪，他人不行；訊息與操作軌跡一併清除
m5, sid5 = ask(T5, "我的技能強弱項是什麼？")
s, r = call("DELETE", f"/assistant/sessions/{sid5}", None, T2); ok("他人不能刪除對話", s == 403)
call("DELETE", f"/assistant/sessions/{sid5}", None, T5, 200)
s1, _ = call("GET", f"/assistant/sessions/{sid5}", None, T5); s2, _ = call("GET", f"/assistant/sessions/{sid5}/trace", None, T5)
ok("本人刪除後對話與軌跡都不存在", s1 == 404 and s2 == 404 and sid5 not in [x["id"] for x in call("GET", "/assistant/sessions", None, T5, 200)[1]])

# 刪除帳號：新資料表（證據、證照與作品、AI 助理對話、待確認動作）一併刪除，模型用量紀錄不再連到本人
T48 = login("student048@example.edu"); me48 = call("GET", "/me", None, T48, 200)[1]
call("POST", "/me/credentials", {"type": "PORTFOLIO", "title": "刪除測試作品", "tier": 2, "proofUrl": "https://example.edu/x", "skillIds": [SK["簡報設計"]]}, T48, 200)
m48, sid48 = ask(T48, "我想參加比賽，幫我規劃")
ok("刪除前：有對話、有待驗證的自述證據", m48["status"] == "DONE" and [e for e in call("GET", "/admin/evidence?verified=false", None, admin, 200)[1] if e["title"] == "刪除測試作品"])
call("DELETE", "/me", None, T48, 204)
s, r = call("POST", "/auth/login", {"account": "student048@example.edu", "password": PW}); ok("刪除後不能登入", s == 401)
pub = call("GET", f"/users/{me48['id']}", None, admin, 200)[1]
ok("公開檔案已去識別化、沒有技能", pub["name"] == "已離開的成員" and pub["skills"] == [], pub["name"])
s, r = call("GET", f"/assistant/sessions/{sid48}/trace", None, admin); ok("AI 助理對話與操作軌跡已刪除", s == 404)
ok("待驗證清單不再有這位學生的證據", not [e for e in call("GET", "/admin/evidence?verified=false", None, admin, 200)[1] if e["title"] == "刪除測試作品"])

print(f"\n全部通過（{len(PASSED)} 項）：AI 助理入口 → 能力盤點 → 競賽 Agent → 學生 Agent → 教師 Agent → 待確認動作 → 人工確認 → 成案 ✓")
