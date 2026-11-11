#!/usr/bin/env python3
"""
AI 助理評測：跑一組固定的測試案例，從系統紀錄算出決賽要求的指標，並輸出可查核的操作軌跡。

  python3 tools/agent_eval.py [--base http://localhost:8080] [--mode auto|rule] [--label 名稱] [--cases tools/eval/cases.json] [--only F1,A1]

  --mode auto  示範帳號已同意 AI 助理：後端有金鑰就走 Claude（LLM 模式），沒有就走規則模式
  --mode rule  先撤回同意，強制規則模式（基準線）；跑完會恢復同意
  每次執行前會重置示範資料（/admin/reset），所以結果可重現；請不要對正式資料庫執行。

輸出（tools/eval/out/）：
  results-<label>.json   每個案例的判定、回合指標、卡片摘要
  REPORT-<label>.md      指標總表（成功率、正確率、延遲、成本、工具調用成功率、重試、人工介入率、中止率、錯誤分類）＋逐案結果
  trace-<label>-<case>.json  指定案例（預設 F1）的完整操作軌跡

指標定義
  任務成功率     案例的 expect 條件全部成立，且最後一則回覆正常結束（END_TURN／RULE）
  正確率         所有回覆的「輸出檢核」通過（回覆中的分數、日期、學生代號都能對應到工具結果），且提到的首選競賽與競賽 Agent 的第一名一致
  工具調用成功率 成功的工具呼叫 ÷ 全部工具呼叫
  人工介入率     產生待確認動作的案例 ÷ 全部案例（所有會改資料的動作都要人按確認）
  中止率         因工具呼叫上限、拒答、回覆截斷而停止的回合 ÷ 全部回合
  降級率         Claude API 失敗後改用規則模式的回合 ÷ 全部回合
"""
import argparse, datetime, json, os, re, statistics, sys, time, urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("--base", default="http://localhost:8080"); ap.add_argument("--mode", default="auto", choices=["auto", "rule"])
ap.add_argument("--label", default=None); ap.add_argument("--cases", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "eval", "cases.json"))
ap.add_argument("--only", default=""); ap.add_argument("--trace", default="F1"); ap.add_argument("--no-reset", action="store_true")
A = ap.parse_args()
BASE, OUT = A.base + "/api/v1", os.path.join(os.path.dirname(os.path.abspath(__file__)), "eval", "out")
os.makedirs(OUT, exist_ok=True)


def call(method, path, body=None, token=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=60) as r: return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e: return e.code, json.loads(e.read() or b"null")


def login(account): return call("POST", "/auth/login", {"account": account, "password": "demo1234"})[1]["token"]


def ask(token, text, sid):
    s, r = call("POST", "/assistant/messages", {"sessionId": sid, "text": text}, token)
    if s != 200: return {"status": "ERROR", "stop": "ERROR", "content": str(r), "steps": [], "cards": [], "checks": None, "durationMs": 0, "llmCalls": 0, "toolCalls": 0, "toolErrors": 0, "inputTokens": 0, "outputTokens": 0, "mode": None}, sid
    for _ in range(1500):
        time.sleep(0.2)
        m = call("GET", f"/assistant/messages/{r['assistantMessageId']}", None, token)[1]
        if m["status"] != "RUNNING": return m, r["sessionId"]
    return {**m, "stop": "TIMEOUT"}, r["sessionId"]


ORDER_DEPENDS = {"recommend_teammates": {"recommend_competitions", "get_competition", "search_competitions"}, "recommend_teachers": {"recommend_competitions", "get_competition", "search_competitions"},
                 "draft_team_case": {"recommend_competitions", "get_competition", "search_competitions"}}


def judge(case, msgs, cases_before, cases_after):
    """回傳 (失敗原因清單, 正確性問題清單)"""
    e, fails, wrong = case.get("expect", {}), [], []
    all_tools = [s["tool"] for m in msgs for s in m.get("steps", [])]
    last_tools = [s["tool"] for s in msgs[-1].get("steps", [])]
    cards = [c["type"] for m in msgs for c in m.get("cards", [])]
    actions = [c for m in msgs for c in m.get("cards", []) if c["type"] == "action"]
    if msgs[-1].get("stop") not in ("END_TURN", "RULE"): fails.append("最後一則未正常結束：" + str(msgs[-1].get("stop")))
    for t in e.get("tools_all", []):
        if t not in all_tools: fails.append("沒有呼叫 " + t)
    if e.get("tools_any") and not set(e["tools_any"]) & set(all_tools): fails.append("沒有呼叫任一：" + "／".join(e["tools_any"]))
    for t in e.get("tools_last_turn", []):
        if t not in last_tools: fails.append("最後一回合沒有呼叫 " + t)
    for c in e.get("cards", []):
        if c not in cards: fails.append("沒有卡片 " + c)
    if e.get("cards_any") and not set(e["cards_any"]) & set(cards): fails.append("沒有任一卡片：" + "／".join(e["cards_any"]))
    if "min_tool_calls" in e and len(all_tools) < e["min_tool_calls"]: fails.append(f"工具呼叫 {len(all_tools)} 次，少於 {e['min_tool_calls']}")
    if "max_tool_calls" in e and len(all_tools) > e["max_tool_calls"]: fails.append(f"工具呼叫 {len(all_tools)} 次，多於 {e['max_tool_calls']}")
    if e.get("no_action") and actions: fails.append("不該產生待確認動作")
    if e.get("action_pending") and not any(a.get("status") == "PENDING" for a in actions): fails.append("沒有產生待確認動作")
    if e.get("no_case_created") and cases_after != cases_before: fails.append("未經確認就建立了案件")
    if e.get("dependency_order"):
        seen = set()
        for t in all_tools:
            if t in ORDER_DEPENDS and not ORDER_DEPENDS[t] & seen: fails.append(t + " 在取得競賽之前就被呼叫")
            seen.add(t)
    if e.get("no_other_student_ids") and re.search(r"[DMP]\d{7}", " ".join(m.get("content", "") for m in msgs)): fails.append("回覆中出現學號")
    # 正確性
    for i, m in enumerate(msgs):
        if m.get("checks") and not m["checks"].get("ok"): wrong.append(f"第 {i + 1} 回合輸出檢核未過：" + "、".join(m["checks"].get("unverified", []) + m["checks"].get("unknownTokens", [])))
        if "[[S" in m.get("content", ""): wrong.append(f"第 {i + 1} 回合有未還原的代號")
    if e.get("top_competition_mentioned"):
        top = next((c["recommended"][0] for m in msgs for c in m.get("cards", []) if c["type"] == "competitions" and c["recommended"]), None)
        if top and not any(top["name"] in m.get("content", "") or top["shortName"] in m.get("content", "") for m in msgs): wrong.append("回覆沒有提到競賽 Agent 的第一名：" + top["shortName"])
    return fails, wrong


def main():
    admin = login("admin@example.edu")
    if not A.no_reset: call("POST", "/admin/reset", {}, admin)
    call("PUT", "/admin/params", {"params": {"assistant_daily_limit": 0}}, admin)          # 評測期間不設每日上限
    spec = json.load(open(A.cases, encoding="utf-8"))
    cases = [c for c in spec["cases"] if not A.only or c["id"] in A.only.split(",")]
    tokens, results, turns = {}, [], []
    status0 = None
    for case in cases:
        p = case["persona"]
        if p not in tokens:
            tokens[p] = login(p + "@example.edu")
            call("POST", "/me/consents/ai", {"agree": A.mode != "rule"}, tokens[p])
        tok = tokens[p]
        status0 = status0 or call("GET", "/assistant/status", None, tok)[1]
        before = len(call("GET", "/cases?mine=true", None, tok)[1])
        sid, msgs = None, []
        for text in case["turns"]:
            m, sid = ask(tok, text, sid)
            msgs.append(m); turns.append(m)
        after = len(call("GET", "/cases?mine=true", None, tok)[1])
        fails, wrong = judge(case, msgs, before, after)
        actions = [c for m in msgs for c in m.get("cards", []) if c["type"] == "action"]
        results.append({"id": case["id"], "group": case["group"], "persona": p, "turns": case["turns"], "success": not fails, "correct": not wrong, "failures": fails, "correctness_issues": wrong,
                        "human_check": case.get("human_check"), "action_proposed": bool(actions), "session_id": sid,
                        "messages": [{"mode": m.get("mode"), "stop": m.get("stop"), "durationMs": m.get("durationMs"), "llmCalls": m.get("llmCalls"), "toolCalls": m.get("toolCalls"), "toolErrors": m.get("toolErrors"),
                                      "inputTokens": m.get("inputTokens"), "outputTokens": m.get("outputTokens"), "checks": m.get("checks"), "notice": m.get("notice"),
                                      "tools": [s["tool"] + ("" if s["ok"] else "✗") for s in m.get("steps", [])], "cards": [c["type"] for c in m.get("cards", [])], "content": m.get("content")} for m in msgs]})
        print(("✓" if not fails and not wrong else "✗"), case["id"], case["group"], "｜", "；".join(fails + wrong) or "通過", "｜工具", [t for m in results[-1]["messages"] for t in m["tools"]])
        if case["id"] == A.trace and sid:
            tr = call("GET", f"/assistant/sessions/{sid}/trace", None, tok)[1]
            label0 = A.label or (A.mode if A.mode == "rule" else ("llm" if status0["mode"] == "LLM" else "rule"))
            json.dump(tr, open(os.path.join(OUT, f"trace-{label0}-{case['id']}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    metrics = call("GET", "/admin/assistant/metrics?days=1", None, admin)[1]
    if A.mode == "rule":
        for tok in tokens.values(): call("POST", "/me/consents/ai", {"agree": True}, tok)
    call("PUT", "/admin/params", {"params": {"assistant_daily_limit": 60}}, admin)

    label = A.label or (A.mode if A.mode == "rule" else ("llm" if status0["mode"] == "LLM" else "rule"))
    n, nt = len(results), len(turns)
    lat = [m.get("durationMs", 0) for m in turns]
    tool_calls, tool_err = sum(m.get("toolCalls", 0) for m in turns), sum(m.get("toolErrors", 0) for m in turns)
    stops = {}
    for m in turns: stops[m.get("stop")] = stops.get(m.get("stop"), 0) + 1
    t = metrics["turns"]
    summary = {
        "label": label, "generated_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"), "base": A.base, "requested_mode": A.mode,
        "assistant_mode": status0["mode"], "model": status0.get("model"), "cases": n, "turns": nt,
        "task_success_rate": round(sum(r["success"] for r in results) / n, 3), "correctness_rate": round(sum(r["correct"] for r in results) / n, 3),
        "latency_ms": {"avg": round(statistics.mean(lat)), "p50": round(statistics.median(lat)), "max": max(lat)},
        "tool_calls": tool_calls, "tool_success_rate": round((tool_calls - tool_err) / tool_calls, 3) if tool_calls else None,
        "llm_calls": sum(m.get("llmCalls", 0) for m in turns), "llm_retries": t["llmRetries"], "tokens": {"input": sum(m.get("inputTokens", 0) for m in turns), "output": sum(m.get("outputTokens", 0) for m in turns)},
        "estimated_cost_usd": t["estimatedCostUsd"], "cost_per_turn_usd": t["costPerTurnUsd"], "price_note": t["priceNote"],
        "human_intervention_rate": round(sum(r["action_proposed"] for r in results) / n, 3),
        "abort_rate": round(sum(v for k, v in stops.items() if k in ("MAX_STEPS", "MAX_TOKENS", "REFUSAL", "TIMEOUT")) / nt, 3),
        "fallback_rate": round(stops.get("FALLBACK", 0) / nt, 3), "error_rate": round(stops.get("ERROR", 0) / nt, 3),
        "stop_reasons": stops, "llm_errors": metrics["errors"], "tools": metrics["tools"],
    }
    json.dump({"summary": summary, "results": results}, open(os.path.join(OUT, f"results-{label}.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    L = [f"# AI 助理評測報告（{label}）", "",
         f"- 產生時間：{summary['generated_at']}　系統：{A.base}　助理模式：{summary['assistant_mode']}" + (f"（{summary['model']}）" if summary["model"] else "（規則模式：關鍵字判斷意圖＋固定流程，不呼叫語言模型）"),
         f"- 案例 {n} 個、回合 {nt} 個；資料為 50 位虛構示範學生＋逢甲公開資料（科目表、教師專長）＋ 28 個競賽；每次執行前重置，結果可重現。", "",
         "## 指標", "", "| 指標 | 數值 | 說明 |", "|---|---|---|",
         f"| 任務成功率 | {summary['task_success_rate']:.1%} | expect 條件全部成立且正常結束（{sum(r['success'] for r in results)}／{n}） |",
         f"| 正確率 | {summary['correctness_rate']:.1%} | 輸出檢核通過、代號全部還原、首選競賽與競賽 Agent 一致（{sum(r['correct'] for r in results)}／{n}） |",
         f"| 平均／中位／最大延遲 | {summary['latency_ms']['avg']}／{summary['latency_ms']['p50']}／{summary['latency_ms']['max']} ms | 每回合從送出到完成 |",
         f"| 工具調用成功率 | {summary['tool_success_rate'] if summary['tool_success_rate'] is None else format(summary['tool_success_rate'], '.1%')} | {tool_calls} 次呼叫，失敗 {tool_err} 次 |",
         f"| 模型呼叫／重試 | {summary['llm_calls']}／{summary['llm_retries']} | 429／5xx 自動重試一次 |",
         f"| Token（輸入／輸出） | {summary['tokens']['input']}／{summary['tokens']['output']} | |",
         f"| 估算成本 | US$ {summary['estimated_cost_usd']}（每回合 {summary['cost_per_turn_usd']}） | {summary['price_note']} |",
         f"| 人工介入率 | {summary['human_intervention_rate']:.1%} | 產生待確認動作的案例比例；所有會改資料的動作都需人確認 |",
         f"| 中止率 | {summary['abort_rate']:.1%} | 工具呼叫上限、拒答、截斷 |",
         f"| 降級率／錯誤率 | {summary['fallback_rate']:.1%}／{summary['error_rate']:.1%} | API 失敗改規則模式／系統錯誤 |", "",
         "### 停止原因（錯誤分類）", "", "| 原因 | 回合數 |", "|---|---|"] + [f"| {k} | {v} |" for k, v in sorted(stops.items(), key=lambda x: -x[1])] + ["",
         "### 各工具", "", "| 工具 | Agent | 呼叫 | 失敗 | 平均 ms | 最大 ms |", "|---|---|---|---|---|---|"] + [f"| {x['tool']} | {x['agent']} | {x['calls']} | {x['errors']} | {x['avgMs']} | {x['maxMs']} |" for x in metrics["tools"]] + ["",
         "## 逐案結果", "", "| 案例 | 類別 | 成功 | 正確 | 工具（依序） | 未通過的條件 | 人工檢查重點 |", "|---|---|---|---|---|---|---|"]
    for r in results:
        L.append(f"| {r['id']} | {r['group']} | {'✓' if r['success'] else '✗'} | {'✓' if r['correct'] else '✗'} | {' → '.join(t for m in r['messages'] for t in m['tools']) or '（無）'} | {'；'.join(r['failures'] + r['correctness_issues']) or '—'} | {r['human_check']} |")
    L += ["", "「人工檢查重點」需要人閱讀回覆內容判定（results 檔內有每一則回覆全文）；自動判定只涵蓋可由系統紀錄驗證的條件。"]
    open(os.path.join(OUT, f"REPORT-{label}.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
    print(f"\n{label}：成功率 {summary['task_success_rate']:.1%}　正確率 {summary['correctness_rate']:.1%}　平均延遲 {summary['latency_ms']['avg']} ms　工具成功率 {summary['tool_success_rate']}　人工介入率 {summary['human_intervention_rate']:.1%}")
    print("輸出：", os.path.join(OUT, f"REPORT-{label}.md"))


if __name__ == "__main__":
    main()
