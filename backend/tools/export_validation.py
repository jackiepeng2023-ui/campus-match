#!/usr/bin/env python3
"""
場域驗證紀錄匯出：把 AI 助理的線上指標、使用者回饋、每個對話的操作軌跡存成檔案（docs/napai/field-validation.md 第 6 節）。

  python3 tools/export_validation.py --admin admin@example.edu --password <管理員密碼> [--base http://localhost:8080] [--days 7] [--out validation-out]

Demo 模式的資料庫在後端重新啟動時會重建：請在每一場測試結束後、重啟之前執行。
輸出不含使用者的提問原文（管理員檢視的軌跡本來就不顯示），其他學生以代號表示；留言欄是使用者主動寫給團隊的意見，繳交前請自行檢查有沒有個資。
"""
import argparse, csv, datetime, json, os, sys, urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("--base", default="http://localhost:8080"); ap.add_argument("--admin", required=True); ap.add_argument("--password", required=True)
ap.add_argument("--days", type=int, default=7); ap.add_argument("--out", default="validation-out")
A = ap.parse_args()
BASE = A.base + "/api/v1"


def call(method, path, body=None, token=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=60) as r: return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e: return e.code, json.loads(e.read() or b"null")


s, r = call("POST", "/auth/login", {"account": A.admin, "password": A.password})
if s != 200: sys.exit(f"管理員登入失敗（{s}）：{r}")
T = r["token"]
s, m = call("GET", f"/admin/assistant/metrics?days={A.days}", None, T)
if s != 200: sys.exit(f"取得指標失敗（{s}）：{m}")
out = os.path.join(A.out, datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))
os.makedirs(out, exist_ok=True)
json.dump(m, open(os.path.join(out, "metrics.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
with open(os.path.join(out, "feedback.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["messageId", "sessionId", "value(+1 讚 / -1 倒讚)", "note", "mode", "stop", "durationMs", "toolCalls", "createdAt"])
    for x in m["feedback"]: w.writerow([x["messageId"], x["sessionId"], x["value"], x.get("note") or "", x["mode"], x["stop"], x["durationMs"], x["toolCalls"], x["createdAt"]])
with open(os.path.join(out, "sessions.csv"), "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["sessionId", "updatedAt", "turns", "toolCalls", "modes", "steps(依序)", "actions"])
    n = 0
    for x in m["recentSessions"]:
        s, tr = call("GET", f"/assistant/sessions/{x['id']}/trace", None, T)
        if s != 200: continue
        json.dump(tr, open(os.path.join(out, f"trace-{x['id']}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        steps = [st["tool"] for msg in tr["messages"] if msg["role"] == "assistant" for st in msg.get("steps", [])]
        w.writerow([x["id"], x["updatedAt"], x["turns"], x["toolCalls"], x["modes"], " → ".join(steps), "；".join(f"{a['status']}" for a in tr.get("actions", []))])
        n += 1
t = m["turns"]
print(f"已匯出到 {out}/：metrics.json、feedback.csv（{len(m['feedback'])} 筆）、sessions.csv 與 {n} 份操作軌跡")
print(f"回合 {t['turns']}（LLM {t['llmTurns']}、規則 {t['ruleTurns']}）　完成率 {t['successRate']}　平均延遲 {t['avgLatencyMs']} ms　最大 {t['maxLatencyMs']} ms　"
      f"工具成功率 {t['toolSuccessRate']}　讚 {t['feedbackUp']}／倒讚 {t['feedbackDown']}　估算成本 US$ {t['estimatedCostUsd']}")
