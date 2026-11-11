#!/usr/bin/env python3
"""
正式模式（APP_SEED_MODE=reference）的冒煙測試：沒有示範學生，從註冊開始走一遍
  註冊（條款 v2、AI 同意分開記錄）→ 從正式科目表填成績 → 能力盤點 → 自述證據與管理員驗證 → 三個 Agent → 規則模式的 AI 助理 → 待確認動作

  APP_SEED_MODE=reference APP_RESET_ON_START=true APP_DEMO_CLOCK=false APP_ADMIN_EMAIL=admin@campus.test APP_ADMIN_PASSWORD='Ref-Mode-Check-1' java -jar target/campus-match-1.0.0.jar
  python3 tools/reference_smoke.py [--base http://localhost:8080] [--admin admin@campus.test] [--password Ref-Mode-Check-1]

會註冊兩位測試學生並建立案件：只能對剛重建、可丟棄的資料庫執行，不要對正式資料庫執行。後端不要設定 APP_ANTHROPIC_API_KEY（這裡驗證的是沒有金鑰時的規則模式）。
"""
import argparse, json, sys, time, urllib.request, urllib.parse
ap = argparse.ArgumentParser(); ap.add_argument("--base", default="http://localhost:8080"); ap.add_argument("--admin", default="admin@campus.test"); ap.add_argument("--password", default="Ref-Mode-Check-1")
A = ap.parse_args()
BASE = A.base + "/api/v1"
def call(m, path, body=None, tok=None, expect=None):
    req=urllib.request.Request(BASE+path, method=m, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type","application/json")
    if tok: req.add_header("Authorization","Bearer "+tok)
    try:
        with urllib.request.urlopen(req, timeout=60) as r: s, d = r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e: s, d = e.code, json.loads(e.read() or b"null")
    if expect and s != expect: print("UNEXPECTED", m, path, s, d); sys.exit(1)
    return s, d
N=[0]
def ok(name, cond, detail=""):
    if not cond: print("  ✗", name, detail); sys.exit(1)
    N[0]+=1; print("  ✓", name, detail)
meta=call("GET","/meta",expect=200)[1]
ok("參考資料", len(meta["skills"])==57 and len(meta["departments"])>=70 and len(meta["certificateCatalog"])==36, f'{len(meta["skills"])} 技能、{len(meta["departments"])} 系所、{len(meta["certificateCatalog"])} 證照、條款 {meta["termsVersion"]}')
s,r=call("POST","/auth/login",{"account":"student001@example.edu","password":"demo1234"}); ok("沒有示範帳號", s in (400,401,404), str(s))
admin=call("POST","/auth/login",{"account":A.admin,"password":A.password},expect=200)[1]["token"]
ov=call("GET","/analytics/overview",None,admin,200)[1]; ok("沒有示範學生與案件", ov["students"]==0, str({k:ov[k] for k in list(ov)[:4]}))
comps=call("GET","/admin/competitions",None,admin,200)[1]; teachers=call("GET","/teachers",None,admin,200)[1]
ok("競賽與教師資料", len(comps)==28 and len(teachers)==305, f"{len(comps)} 競賽、{len(teachers)} 教師")
ok("教師資料沒有聯絡方式", not any("@" in json.dumps(t, ensure_ascii=False).replace(t.get("profileUrl") or "", "").replace(t.get("sourceUrl") or "", "") for t in teachers))
cs=[d for d in meta["departments"] if d["name"]=="資訊工程學系"][0]
def register(no, name, consent_ai):
    body={"studentNo":no,"name":name,"email":f"{no.lower()}@campus.test","password":"Ref-Mode-Stu-1","degree":"BACHELOR","year":3,"departmentId":cs["id"],"entryYear":113,"expectedGraduation":"2028-06-30","hoursPerWeek":10,"consent":True,"aiConsent":consent_ai}
    return call("POST","/auth/register",body,expect=200)[1]
s,r=call("POST","/auth/register",{"studentNo":"D0000000","name":"x","email":"x@campus.test","password":"Ref-Mode-Stu-1","degree":"BACHELOR","year":3,"departmentId":cs["id"],"entryYear":113,"expectedGraduation":"2028-06-30","hoursPerWeek":10,"consent":False})
ok("未同意條款不能註冊", s==400, r.get("message",""))
a=register("D1234501","測試生甲",True); b=register("D1234502","測試生乙",False)
TA,TB=a["token"],b["token"]
ok("註冊後 Skill Profile 是空的、AI 同意各自記錄", a["user"]["skills"]==[] and a["user"]["aiConsent"] is True and b["user"]["aiConsent"] is False)
courses=call("GET",f'/courses?departmentId={cs["id"]}&degree=BACHELOR&entryYear=113&requirement=REQUIRED',None,TA,200)[1]
mapped=[c for c in courses if c["skills"]][:8]
ok("正式科目表（資工 113 必修）", len(courses)>20 and len(mapped)==8, f'{len(courses)} 門，其中 {len([c for c in courses if c["skills"]])} 門有技能對照')
for tok,scores in ((TA,[92,88,85,81,78,74,70,66]),(TB,[65,72,90,60,83,77,95,68])):
    call("PUT","/me/grades",[{"courseId":c["id"],"score":sc,"semester":None,"skillIds":[]} for c,sc in zip(mapped,scores)],tok,200)
meA=call("GET","/me",None,TA,200)[1]
ok("能力盤點：成績 → 技能／等級／證據", len(meA["skills"])>=2 and all(s["trust"]=="COURSE" and s["evidence"] for s in meA["skills"]), "、".join(f'{s["name"]} {s["score"]}{s["tier"]}' for s in meA["skills"][:5]))
call("POST","/me/credentials",{"type":"PORTFOLIO","title":"課堂專題網站","tier":2,"proofUrl":"https://example.edu/p","skillIds":[meta["skills"][0]["id"]]},TA,200)
pend=call("GET","/admin/evidence?verified=false",None,admin,200)[1]
ok("自述證據進入待驗證清單", len(pend)==1 and pend[0]["title"]=="課堂專題網站")
call("PUT",f'/admin/evidence/credential/{pend[0]["id"]}',{"verified":True},admin,200)
sk=[s for s in call("GET","/me",None,TA,200)[1]["skills"] if s["skillId"]==meta["skills"][0]["id"]][0]
ok("管理員驗證後變成已驗證", sk["trust"]=="VERIFIED", f'{sk["name"]} {sk["tier"]}・{sk["trustLabel"]}')
rec=call("GET","/agents/competitions?limit=5",None,TA,200)[1]
ok("競賽 Agent", rec["recommended"] and all(c["reasons"] for c in rec["recommended"]), f'可報名 {rec["totalEligible"]} 筆，第一名「{rec["recommended"][0]["shortName"]}」{rec["recommended"][0]["fit"]}')
cid=rec["recommended"][0]["id"]
tm=call("POST","/agents/teammates",{"competitionId":cid,"limit":5},TA,200)[1]
ok("學生 Agent（只有兩位學生）", "gaps" in tm and "candidates" in tm, f'缺口 {len(tm["gaps"])}、候選 {len(tm["candidates"])}')
th=call("POST","/agents/teachers",{"competitionId":cid,"limit":3},TA,200)[1]
ok("教師 Agent", th["teachers"] and all(t["toConfirm"] and t["reasons"] for t in th["teachers"]), "、".join(f'{t["name"]}（{t["department"]}）{t["fit"]}' for t in th["teachers"]))
st=call("GET","/assistant/status",None,TA,200)[1]
ok("沒有金鑰 → 規則模式", st["mode"]=="RULE" and not st["llmEnabled"], st["notice"])
r=call("POST","/assistant/messages",{"sessionId":None,"text":"我想參加比賽，幫我規劃"},TA,200)[1]
for i in range(100):
    time.sleep(0.2); m=call("GET",f'/assistant/messages/{r["assistantMessageId"]}',None,TA,200)[1]
    if m["status"]!="RUNNING": break
ok("AI 助理（規則模式）完成多步驟任務", m["mode"]=="RULE" and m["status"]=="DONE" and [c["type"] for c in m["cards"]][:4]==["profile","competitions","teammates","teachers"], f'{[s["tool"] for s in m["steps"]]}')
act=[c for c in m["cards"] if c["type"]=="action"]
if act:
    done=call("POST",f'/assistant/actions/{act[0]["actionId"]}/confirm',{},TA,200)[1]
    ok("確認後建立案件", done["status"]=="DONE" and done["result"]["caseId"], str(done["result"].get("invited")))
s,r=call("POST","/admin/clock",{"hours":1},admin); ok("正式模式不能快轉時間", s in (400,403,404), str(s))
s,r=call("POST","/admin/reset",{},admin); ok("正式模式不能重置資料", s in (400,403,404), str(s))
ex=call("GET","/admin/extract/status",None,admin,200)[1]
ok("AI 擷取狀態", ex is not None, json.dumps(ex, ensure_ascii=False)[:160])
print(f"\n正式模式冒煙測試通過（{N[0]} 項）")
