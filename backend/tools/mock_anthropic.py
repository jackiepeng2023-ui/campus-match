#!/usr/bin/env python3
"""
Claude Messages API 的測試替身（test double）— 只供開發與自動化測試使用，不是 AI，也不會出現在正式環境。

  python3 tools/mock_anthropic.py [port=8089]
  後端啟動時設定  APP_ANTHROPIC_BASE_URL=http://localhost:8089  APP_ANTHROPIC_API_KEY=test-key

用途
1. 沒有金鑰的環境（CI、沙箱）也能驗證「LLM 模式」的整條路徑：多輪工具呼叫、工具錯誤回報、輪數上限、拒答、429 重試、5xx 降級。
2. 檢查後端送出的請求符合 Messages API 的規定，違反就回 400／401（與正式 API 相同的錯誤型態）：
   - 必須有 x-api-key、anthropic-version、max_tokens、model、messages
   - 不可帶 temperature／top_p／top_k；tool_choice 只接受 auto
   - messages 必須以 user 結尾；assistant 的每個 tool_use 都要在下一則 user 訊息有對應的 tool_result
   - 上一輪 assistant 回覆裡的 thinking 區塊必須原封不動送回
3. 把收到的請求留在記憶體，測試可用 GET /__requests 取回，檢查有沒有學生姓名、學號、Email 外流；POST /__reset 清空。

「模型」的行為是寫死的劇本（依使用者訊息的關鍵字決定呼叫哪些工具），所以每次結果相同、可重現：
  規劃／參加比賽 → get_my_skill_profile + recommend_competitions（同一輪兩個工具）→ recommend_teammates → recommend_teachers → draft_team_case → 總結
  隊友 → recommend_teammates；老師 → recommend_teachers；邀請／建立 → draft_team_case
  error-test → 故意用不存在的 competition_id，收到 is_error 後改用 search_competitions（驗證錯誤修正）
  loop-test → 不停呼叫工具（驗證輪數上限）；refuse-test → stop_reason=refusal；429-test → 第一次回 429；500-test → 一律回 500
  bad-number-test → 回覆裡放一個工具結果沒有的分數（驗證輸出檢核）
結構化輸出（output_config.format）：依 schema 產生最小的合法 JSON，enum 欄位挑出現在輸入文字裡的值。
"""
import json, re, sys, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REQUESTS, LOCK, COUNTS = [], threading.Lock(), {}


def err(status, etype, message):
    return status, {"type": "error", "error": {"type": etype, "message": message}}


def validate(headers, body):
    if not headers.get("x-api-key"):
        return err(401, "authentication_error", "x-api-key header is required")
    if not headers.get("anthropic-version"):
        return err(400, "invalid_request_error", "anthropic-version header is required")
    for k in ("model", "max_tokens", "messages"):
        if k not in body:
            return err(400, "invalid_request_error", f"{k}: Field required")
    for k in ("temperature", "top_p", "top_k"):
        if k in body:
            return err(400, "invalid_request_error", f"{k} is not supported by this model")
    if "tool_choice" in body and body["tool_choice"].get("type") != "auto":
        return err(400, "invalid_request_error", "tool_choice: only 'auto' is supported by this model")
    msgs = body["messages"]
    if not msgs or msgs[-1]["role"] != "user":
        return err(400, "invalid_request_error", "messages: final message must have role 'user' (prefill is not supported)")
    if msgs[0]["role"] != "user":
        return err(400, "invalid_request_error", "messages: first message must use the user role")
    for i, m in enumerate(msgs):
        if m["role"] not in ("user", "assistant"):
            return err(400, "invalid_request_error", f"messages.{i}.role: unexpected value")
        if m["role"] == "assistant" and isinstance(m["content"], list):
            ids = [b["id"] for b in m["content"] if b.get("type") == "tool_use"]
            for b in m["content"]:
                if b.get("type") == "thinking" and b.get("signature") != "mock-signature":
                    return err(400, "invalid_request_error", f"messages.{i}: thinking blocks must be passed back unmodified")
            if ids:
                nxt = msgs[i + 1] if i + 1 < len(msgs) else None
                got = [b.get("tool_use_id") for b in (nxt or {}).get("content", []) if isinstance(b, dict) and b.get("type") == "tool_result"] if nxt and isinstance(nxt.get("content"), list) else []
                if not nxt or nxt["role"] != "user" or sorted(got) != sorted(ids):
                    return err(400, "invalid_request_error", f"messages.{i}: tool_use ids were found without tool_result blocks immediately after: {ids}")
    for t in body.get("tools") or []:
        if not {"name", "description", "input_schema"} <= set(t):
            return err(400, "invalid_request_error", "tools: each tool needs name, description, input_schema")
    return None


def text_of(content):
    if isinstance(content, str): return content
    return "".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")


def current_turn(msgs):
    """本回合 = 最後一則純文字的 user 訊息之後的所有訊息；回傳 (使用者文字, 已呼叫的工具名稱, 工具結果 dict by 工具名稱, 最後一批結果是否有錯)"""
    start = max(i for i, m in enumerate(msgs) if m["role"] == "user" and (isinstance(m["content"], str) or not any(b.get("type") == "tool_result" for b in m["content"])))
    user, called, results, names, last_error = text_of(msgs[start]["content"]), [], {}, {}, False
    for m in msgs[start + 1:]:
        if m["role"] == "assistant":
            for b in m["content"]:
                if b.get("type") == "tool_use": called.append(b["name"]); names[b["id"]] = b["name"]
        else:
            last_error = False
            for b in m["content"]:
                if b.get("type") == "tool_result":
                    try: results[names.get(b["tool_use_id"])] = json.loads(b["content"])
                    except Exception: results[names.get(b["tool_use_id"])] = {}
                    last_error = last_error or bool(b.get("is_error"))
    return user, called, results, last_error


def earlier_results(msgs):
    """整段對話裡每個工具最後一次的結果（跨回合：例如上一回合推薦過的競賽）"""
    names, out = {}, {}
    for m in msgs:
        if not isinstance(m["content"], list): continue
        for b in m["content"]:
            if b.get("type") == "tool_use": names[b["id"]] = b["name"]
            if b.get("type") == "tool_result":
                try: out[names.get(b["tool_use_id"])] = json.loads(b["content"])
                except Exception: pass
    return out


def plan(body):
    msgs = body["messages"]
    user, called, results, last_error = current_turn(msgs)
    past = earlier_results(msgs)
    n = len(called)
    use = lambda name, **inp: {"type": "tool_use", "id": f"toolu_mock_{len(msgs)}_{name}", "name": name, "input": inp}
    say = lambda t, stop="end_turn": ([{"type": "text", "text": t}], stop)
    think = {"type": "thinking", "thinking": "（測試替身：依劇本決定下一步）", "signature": "mock-signature"}
    comp_id = lambda: (results.get("recommend_competitions") or past.get("recommend_competitions") or {}).get("recommended", [{}])[0].get("competition_id") \
        or (past.get("get_competition") or {}).get("competition_id")
    picks = lambda: [p["student"] for p in (results.get("recommend_teammates") or past.get("recommend_teammates") or {}).get("suggested_team", {}).get("picks", [])]

    if "refuse-test" in user: return [], "refusal"
    if "loop-test" in user: return [think, use("get_my_skill_profile")], "tool_use"
    if "error-test" in user:
        if n == 0: return [use("get_competition", competition_id=999999)], "tool_use"
        if n == 1 and last_error: return [{"type": "text", "text": "找不到這個編號，改用關鍵字搜尋。"}, use("search_competitions", keyword="AI")], "tool_use"
        hits = results.get("search_competitions", {}).get("competitions", [])
        return say(f"編號 999999 不存在，我改用關鍵字找到 {len(hits)} 個競賽" + (f"，第一個是「{hits[0]['name']}」。" if hits else "。"))
    if "bad-number-test" in user:
        if n == 0: return [use("recommend_competitions", limit=3)], "tool_use"
        return say("最適合你的競賽契合度 99.9，報名截止 2031-01-01。")
    if re.search("規劃|參加比賽|參加競賽", user):
        if n == 0: return [think, {"type": "text", "text": "先盤點你的能力，並同時找出可報名的競賽。"}, use("get_my_skill_profile"), use("recommend_competitions", limit=3)], "tool_use"
        cid = comp_id()
        if cid is None: return say("目前沒有符合資格、還能報名的競賽。")
        if "recommend_teammates" not in called: return [think, use("recommend_teammates", competition_id=cid)], "tool_use"
        if "recommend_teachers" not in called: return [use("recommend_teachers", competition_id=cid, limit=3)], "tool_use"
        if "draft_team_case" not in called: return [use("draft_team_case", competition_id=cid, invite_tokens=picks())], "tool_use"
        c = results["recommend_competitions"]["recommended"][0]
        t = results["recommend_teachers"]["teachers"]
        team = results["recommend_teammates"]["suggested_team"]
        lines = [f"結論：建議報名「{c['name']}」（契合度 {c['fit']}，報名截止 {c.get('apply_deadline', '未公告')}，以官方公告為準）。",
                 "- 優點：" + "、".join(c["strengths"]) if c["strengths"] else "- 優點：無",
                 "- 能力缺口：" + ("、".join(c["gaps"]) or "無"),
                 "- 建議隊友：" + ("、".join(f"{p['student']}（補 {'、'.join(p['fills'])}）" for p in team["picks"]) or "目前沒有合適人選") + f"，補完後涵蓋 {team['covered_after']} 項。",
                 "- 指導老師：" + (f"{t[0]['name']}（契合度 {t[0]['fit']}），請自行聯絡並確認：{t[0]['to_confirm'][0]}" if t else "沒有專長相符的老師"),
                 f"我已擬好組隊草稿（動作 #{results['draft_team_case'].get('action_id')}），請檢查下方卡片並按「確認」；確認前不會建立案件，也不會送出邀請。"]
        return say("\n".join(lines))
    if re.search("邀請|建立|開案", user):
        if n == 0:
            cid = comp_id()
            if cid is None: return say("請先告訴我要參加哪個競賽。")
            return [use("draft_team_case", competition_id=cid, invite_tokens=picks())], "tool_use"
        d = results.get("draft_team_case", {})
        return say(f"草稿已準備好（動作 #{d.get('action_id')}），請在下方卡片按「確認」後才會建立案件並送出邀請。" if "action_id" in d else "草稿沒有成功：" + d.get("error", ""))
    if re.search("隊友|組隊|互補", user):
        if n == 0:
            cid = comp_id()
            return [use("recommend_teammates", **({"competition_id": cid} if cid else {"skills": [{"skill": "Python", "min_tier": 2}]}))], "tool_use"
        r = results.get("recommend_teammates", {})
        if "error" in r: return say("找隊友沒有成功：" + r["error"])
        return say("團隊缺口：" + ("、".join(c["skill"] for c in r["team_coverage"] if c["status"] != "MET") or "無") + "。建議："
                   + ("、".join(f"{c['student']}（{c['score']} 分）" for c in r["candidates"][:3]) or "沒有合適人選") + "。")
    if re.search("老師|教授|指導", user):
        if n == 0:
            cid = comp_id()
            return [use("recommend_teachers", **({"competition_id": cid} if cid else {"topic": "人工智慧"}))], "tool_use"
        r = results.get("recommend_teachers", {})
        return say("推薦：" + ("、".join(f"{t['name']}（契合度 {t['fit']}）" for t in r.get("teachers", [])) or "沒有專長相符的老師") + "。平台不會替你聯絡老師。")
    if re.search("技能|能力|強項", user):
        if n == 0: return [use("get_my_skill_profile")], "tool_use"
        s = results["get_my_skill_profile"]["skills"]
        return say(f"你有 {len(s)} 項技能，最強的是 " + "、".join(f"{x['skill']}（{x['tier']}・{x['trust']}）" for x in s[:3]) + "。")
    return say("我可以幫你盤點技能、推薦競賽、找互補的隊友與指導老師。")


def from_schema(schema, source):
    """依 JSON Schema 產生最小的合法值；enum 優先挑出現在輸入文字裡的值"""
    t = schema.get("type")
    if "enum" in schema:
        hit = [e for e in schema["enum"] if isinstance(e, str) and e.lower() in source.lower()]
        return (hit or schema["enum"])[0]
    if t == "object":
        return {k: from_schema(v, source) for k, v in schema.get("properties", {}).items() if k in schema.get("required", schema.get("properties", {}))}
    if t == "array":
        item = schema.get("items", {})
        names = item.get("properties", {}).get("skill", {}).get("enum")
        if names:      # 技能清單：挑名稱出現在文字裡的技能，最多 maxItems 個
            hits = [e for e in names if e.lower() in source.lower()][: schema.get("maxItems", 5)]      # 文字裡沒有出現任何技能名稱 → 空清單
            out = []
            for i, h in enumerate(hits):
                o = from_schema(item, source); o["skill"] = h
                if "confidence" in o: o["confidence"] = round(0.9 - 0.15 * i, 2)
                out.append(o)
            return out
        return [from_schema(item, source)] if schema.get("minItems", 0) > 0 else []
    if t == "integer": return schema.get("minimum", 1)
    if t == "number": return 0.9
    if t == "boolean": return False
    if isinstance(t, list): return None if "null" in t else from_schema({**schema, "type": t[0]}, source)
    return source.strip().split("\n")[0][:40] if t == "string" else None


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def send(self, status, obj):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(status); self.send_header("content-type", "application/json"); self.send_header("content-length", str(len(data))); self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/__requests":
            with LOCK: return self.send(200, REQUESTS)
        self.send(404, {"error": "not found"})

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("content-length", 0)) or 0).decode("utf-8")
        if self.path == "/__reset":
            with LOCK: REQUESTS.clear(); COUNTS.clear()
            return self.send(200, {"ok": True})
        if self.path != "/v1/messages": return self.send(404, {"type": "error", "error": {"type": "not_found_error", "message": self.path}})
        try: body = json.loads(raw)
        except Exception: return self.send(400, {"type": "error", "error": {"type": "invalid_request_error", "message": "invalid JSON"}})
        with LOCK: REQUESTS.append({"headers": {k.lower(): ("***" if k.lower() == "x-api-key" else v) for k, v in self.headers.items()}, "body": body})
        bad = validate({k.lower(): v for k, v in self.headers.items()}, body)
        if bad: return self.send(*bad)
        last_user = text_of(next(m["content"] for m in reversed(body["messages"]) if m["role"] == "user" and (isinstance(m["content"], str) or any(b.get("type") == "text" for b in m["content"]))))
        if "500-test" in last_user: return self.send(*err(500, "api_error", "Internal server error"))
        if "429-test" in last_user:
            with LOCK: COUNTS["429"] = COUNTS.get("429", 0) + 1; first = COUNTS["429"] == 1
            if first: return self.send(*err(429, "rate_limit_error", "Rate limited"))
        fmt = (body.get("output_config") or {}).get("format")
        if fmt:
            if fmt.get("type") != "json_schema" or "schema" not in fmt: return self.send(*err(400, "invalid_request_error", "output_config.format: expected json_schema with schema"))
            source = re.split(r"\n\n(?:Skill 資料庫|可用技能)", last_user)[0]        # 只看課綱／簡章本文，不看後面附的技能清單
            content, stop = [{"type": "text", "text": json.dumps(from_schema(fmt["schema"], source), ensure_ascii=False)}], "end_turn"
        else:
            content, stop = plan(body)
        size = len(json.dumps(body, ensure_ascii=False))
        self.send(200, {"id": "msg_mock", "type": "message", "role": "assistant", "model": body["model"], "content": content, "stop_reason": stop, "stop_sequence": None,
                        "usage": {"input_tokens": size // 3, "output_tokens": len(json.dumps(content, ensure_ascii=False)) // 3}})


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8089
    print(f"mock Anthropic Messages API on http://localhost:{port}  （測試替身，非 AI）", flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
