#!/usr/bin/env python3
"""
Fomo鬆 3.1 主線端到端測試：選比賽 → 開隊 → 推薦／找隊 → 申請／邀請 → 洽談 → 成隊 → 報名追蹤，加上即時通訊。

  java -jar target/campus-match-1.0.0.jar          # Demo 模式（APP_SEED_MODE=demo，可快轉時鐘）
  python3 tools/fomo_e2e.py [http://localhost:8080]

測試開始與結束都會重置示範資料（POST /admin/reset），只能對 Demo 模式的環境執行。
只用 Python 標準函式庫；WebSocket 用戶端是下面那個小類別（RFC 6455 的文字訊框）。
"""
import base64, datetime, json, os, queue, socket, struct, sys, threading, time, urllib.error, urllib.parse, urllib.request

ROOT = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080"
BASE = ROOT + "/api/v1"
PW = os.environ.get("APP_DEMO_PASSWORD", "demo1234")
PASSED = []
_opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))      # 本機測試不走代理


def call(method, path, body=None, token=None, expect=None):
    req = urllib.request.Request(BASE + path, method=method, data=None if body is None else json.dumps(body).encode())
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with _opener.open(req, timeout=120) as r: status, data = r.status, r.read()
    except urllib.error.HTTPError as e: status, data = e.code, e.read()
    out = json.loads(data) if data else None
    if expect is not None and status != expect:
        print(f"FAIL {method} {path} → {status}（預期 {expect}）: {out}"); sys.exit(1)
    return status, out


def login(n): return call("POST", "/auth/login", {"account": n if isinstance(n, str) else "student%03d@example.edu" % n, "password": PW}, expect=200)[1]["token"]
def ok(name, cond, detail=""):
    if not cond: print(f"FAIL {name} {detail}"); sys.exit(1)
    PASSED.append(name); print(f"  ✓ {name}" + (f"　{detail}" if detail else ""))
def step(n, msg): print(f"\n=== {n}：{msg}")
def code(out): return out.get("code") if isinstance(out, dict) else None


class WS:
    """最小的 WebSocket 用戶端：連線、送文字訊框、背景執行緒把收到的 JSON 放進佇列"""
    def __init__(self, root):
        u = urllib.parse.urlparse(root)
        self.sock = socket.create_connection((u.hostname, u.port or 80), timeout=10)
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.sendall((f"GET /ws HTTP/1.1\r\nHost: {u.netloc}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                           f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\nOrigin: {root}\r\n\r\n").encode())
        head = b""
        while b"\r\n\r\n" not in head: head += self.sock.recv(1)
        self.status = int(head.split(b" ")[1])
        self.frames, self.closed, self.sent_at = queue.Queue(), None, {}
        self.sock.settimeout(None)
        threading.Thread(target=self._read, daemon=True).start()

    def _exact(self, n):
        buf = b""
        while len(buf) < n:
            part = self.sock.recv(n - len(buf))
            if not part: raise ConnectionError
            buf += part
        return buf

    def _read(self):
        try:
            while True:
                b1, b2 = self._exact(2)
                n = b2 & 0x7F
                if n == 126: n = struct.unpack(">H", self._exact(2))[0]
                elif n == 127: n = struct.unpack(">Q", self._exact(8))[0]
                data = self._exact(n)
                op = b1 & 0x0F
                if op == 1: self.frames.put((time.time(), json.loads(data.decode())))
                elif op == 8:
                    self.closed = struct.unpack(">H", data[:2])[0] if len(data) >= 2 else 1005
                    return
        except Exception:
            if self.closed is None: self.closed = 1006

    def send(self, obj):
        data = json.dumps(obj).encode(); mask = os.urandom(4)
        head = bytes([0x81]) + (bytes([0x80 | len(data)]) if len(data) < 126 else bytes([0x80 | 126]) + struct.pack(">H", len(data)))
        self.sock.sendall(head + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

    def take(self, seconds=2.0):
        """收集接下來 seconds 秒內的訊框"""
        out, end = [], time.time() + seconds
        while time.time() < end:
            try: out.append(self.frames.get(timeout=max(0.01, end - time.time())))
            except queue.Empty: break
        return out

    def wait(self, pred, seconds=3.0):
        end = time.time() + seconds
        while time.time() < end:
            try: at, f = self.frames.get(timeout=max(0.01, end - time.time()))
            except queue.Empty: break
            if pred(f): return at, f
        return None, None

    def close(self):
        try: self.sock.close()
        except Exception: pass


def ws_login(token):
    w = WS(ROOT)
    w.send({"type": "auth", "token": token})
    _, f = w.wait(lambda f: f.get("type") == "ready")
    if not f: print("FAIL WebSocket 驗證沒有回 ready"); sys.exit(1)
    return w


def conv_of(token, engagement_id):
    for c in call("GET", "/conversations", None, token, 200)[1]:
        if c["kind"] == "TALK" and c["engagement"]["id"] == engagement_id: return c
    return None


def messages(token, conv, q=""): return call("GET", f"/conversations/{conv}/messages{q}", None, token, 200)[1]
def notices(token, type_): return [n for n in call("GET", "/me/notifications", None, token, 200)[1]["items"] if n["type"] == type_]


# ---------------------------------------------------------------------------------------------------------------
admin = login("admin@example.edu")
call("POST", "/admin/reset", {}, admin, 200)
skills = {s["name"]: s["id"] for s in call("GET", "/meta", None, None, 200)[1]["skills"]}

step(0, "示範資料：隊伍牆、適合我、等待回覆的邀請")
A = login(1); meA = call("GET", "/me", None, A, 200)[1]
wall = call("GET", "/cases/wall", None, A, 200)[1]
ok("隊伍牆只列招募中的比賽隊伍", len(wall) >= 6 and all(x["competition"]["id"] and x["status"] == "OPEN" for x in wall), f"{len(wall)} 支")
fits = [x for x in wall if x["fit"] and x["fit"]["passed"]]
ok("示範帳號有適合的隊伍，附白話理由", len(fits) >= 2 and all(x["fit"]["tags"] for x in fits), "、".join(f"{x['title']}（{'／'.join(x['fit']['tags'])}）" for x in fits))
blocked = [x for x in wall if x["fit"] and not x["fit"]["passed"]]
ok("不適合的隊伍說明原因，不出現內部代號", blocked and all(x["fit"]["blocked"] and not any(b.startswith("G") for b in x["fit"]["blocked"]) for x in blocked), blocked[0]["fit"]["blocked"][0])
ok("隊伍牆不回傳分數", '"score"' not in json.dumps(wall))
only_fit = call("GET", "/cases/wall?fit=true", None, A, 200)[1]
ok("「適合我」只留通過的", {x["id"] for x in only_fit} == {x["id"] for x in fits})
mine = call("GET", "/conversations", None, A, 200)[1]
ok("示範帳號有一筆等待回覆的邀請，洽談對話 2 則未讀", len(mine) == 1 and mine[0]["kind"] == "TALK" and mine[0]["unread"] == 2
   and mine[0]["engagement"]["direction"] == "INVITE" and mine[0]["engagement"]["role"] == "RESPONDER" and mine[0]["engagement"]["status"] == "PENDING",
   f"對方：{mine[0]['peer']['name']}（{mine[0]['team']['title']}）")
seed_invite = mine[0]

step(1, "選比賽、開隊")
comps = call("GET", "/competitions?status=open", None, A, 200)[1]
comp = next(c for c in comps if "FITI" in c["name"])
ok("比賽清單有報名截止日與剩餘天數", comp["applyDeadline"] and comp["daysLeft"] > 10, f"{comp['name']}：剩 {comp['daysLeft']} 天，每隊 {comp['teamMin']}–{comp['teamMax']} 人")
s, out = call("POST", "/cases", {"title": "舊表單專題", "type": "PROJECT", "description": "", "teamSize": 3, "applyDeadline": comp["applyDeadline"],
                                 "startDate": comp["applyDeadline"], "endDate": comp["applyDeadline"],
                                 "roles": [{"roleName": "前端", "headcount": 2, "skills": [{"skillId": skills["簡報設計"], "minLevel": 1}]}]}, A)
ok("專題、短期支援、研究協作已停用", s == 400, out["message"])
team_in = {"competitionId": comp["id"], "title": "創業一號", "need": 3, "intro": "想做校園二手教科書平台，缺會做簡報和介面的隊友。",
           "skills": [{"skillId": skills["簡報設計"], "required": False, "minLevel": 1}, {"skillId": skills["UI/UX 設計"], "required": False, "minLevel": 1}]}
s, out = call("POST", "/cases", dict(team_in, title=""), A); ok("隊名必填", s == 400, out["message"])
s, out = call("POST", "/cases", dict(team_in, need=9), A); ok("還缺幾人不能超過比賽的每隊人數上限", s == 400, out["message"])
s, out = call("POST", "/cases", dict(team_in, skills=[]), A); ok("至少選 1 項想找的技能", s == 400, out["message"])
team = call("POST", "/cases", team_in, A, 200)[1]
T, ROLE = team["id"], team["roles"][0]["id"]
ok("開隊後直接是招募中，截止日由比賽帶入", team["status"] == "OPEN" and team["need"] == 3 and team["daysLeft"] == comp["daysLeft"] and team["competitionId"] == comp["id"])
s, out = call("POST", "/cases", dict(team_in, title="創業一號B"), A)
ok("同一場比賽不能再開第二隊", s == 409 and code(out) == "ALREADY_IN_COMPETITION", out["message"])
GA = call("GET", f"/cases/{T}/conversation", None, A, 200)[1]["conversationId"]
g = messages(A, GA)
ok("開隊的同一筆交易建立隊伍群組與第一則系統訊息", len(g) == 1 and g[0]["kind"] == "SYSTEM" and g[0]["senderId"] is None, g[0]["body"])
ok("自己開隊產生的系統訊息不算未讀", next(c for c in call("GET", "/conversations", None, A, 200)[1] if c["id"] == GA)["unread"] == 0)

step(2, "找隊：其他同學在隊伍牆看到這支隊伍")
people = {}
for n in range(10, 51):
    tok = login(n)
    card = next((x for x in call("GET", f"/cases/wall?competitionId={comp['id']}", None, tok, 200)[1] if x["id"] == T), None)
    if card and card["fit"] and card["fit"]["passed"]:
        people[n] = (tok, call("GET", "/me", None, tok, 200)[1])
    if len(people) == 7: break
ok("找到 7 位通過條件的同學當測試角色", len(people) == 7, "、".join(v[1]["name"] for v in people.values()))
(B, meB), (C, meC), (D, meD), (E, meE), (F, meF), (G, meG), (H, meH) = people.values()
s, out = call("GET", f"/cases/{T}/conversation", None, B); ok("不是隊伍成員找不到隊伍群組", s == 404)

step(3, "申請、洽談、WebSocket 推送")
bad = WS(ROOT); bad.send({"type": "auth", "token": "not-a-token"})
_, f = bad.wait(lambda f: f.get("type") == "error"); time.sleep(0.5)
ok("WebSocket：憑證無效回錯誤並關閉連線", f and f["code"] == "UNAUTHORIZED" and bad.closed == 4401, f"關閉代碼 {bad.closed}")
silent = WS(ROOT); silent.send({"type": "ping"}); t0 = time.time()
ok("WebSocket：沒驗證前不回應 ping", silent.take(1.0) == [])
wsA, wsB = ws_login(A), ws_login(B)
wsA.send({"type": "ping"}); _, f = wsA.wait(lambda f: f.get("type") == "pong"); ok("WebSocket：驗證後 ping 會回 pong", f is not None)
note = "我做過兩次提案簡報，也會用 Figma，可以幫忙。"
t_post = time.time()
eng = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY", "message": note}, B, 200)[1]
got = wsA.take(2.0); types = [f["type"] for _, f in got]
ok("隊長即時收到：通知、兩則新訊息、申請狀態", types.count("message.new") == 2 and "notification.new" in types and "engagement.updated" in types, " → ".join(types))
first_text = next(f for _, f in got if f["type"] == "message.new" and f["message"]["kind"] == "TEXT")
ok("申請時附的那句話成為洽談對話的第一則訊息", first_text["message"]["body"] == note and first_text["message"]["senderName"] == meB["name"])
TALK = first_text["conversationId"]
ca, cb = conv_of(A, eng["id"]), conv_of(B, eng["id"])
ok("隊長看到 2 則未讀、可以回覆；申請人 0 則未讀、可以取消", ca["unread"] == 2 and ca["engagement"]["role"] == "RESPONDER" and cb["unread"] == 0 and cb["engagement"]["role"] == "INITIATOR"
   and ca["peer"]["name"] == meB["name"] and cb["peer"]["name"] == meA["name"])
for who, tok in (("其他同學", C), ("管理員", admin)):
    s1, _ = call("GET", f"/conversations/{TALK}/messages", None, tok); s2, _ = call("POST", f"/conversations/{TALK}/messages", {"body": "偷看"}, tok)
    ok(f"{who}讀不到也寫不進別人的洽談對話", s1 == 404 and s2 == 404)
t_send = time.time()
m1 = call("POST", f"/conversations/{TALK}/messages", {"body": "可以，你週末有空討論嗎？", "clientId": "e2e-1"}, A, 200)[1]
at, f = wsB.wait(lambda f: f.get("type") == "message.new" and f["message"]["id"] == m1["id"])
ok("對方 2 秒內收到新訊息", f is not None and at - t_send < 2.0, f"{(at - t_send) * 1000:.0f} 毫秒")
m1b = call("POST", f"/conversations/{TALK}/messages", {"body": "可以，你週末有空討論嗎？", "clientId": "e2e-1"}, A, 200)[1]
ok("同一則訊息重送不會變成兩則", m1b["id"] == m1["id"] and sum(1 for m in messages(A, TALK) if m["clientId"] == "e2e-1") == 1)
ok("申請人看到 1 則未讀", conv_of(B, eng["id"])["unread"] == 1)
r = call("POST", f"/conversations/{TALK}/read", {"messageId": m1["id"]}, B, 200)[1]
ok("標成已讀後未讀歸零", r["unreadTotal"] == 0 and conv_of(B, eng["id"])["unread"] == 0)
s, out = call("POST", f"/conversations/{TALK}/messages", {"body": "   "}, A); ok("空白訊息不收", s == 400, out["message"])
s, out = call("POST", f"/conversations/{TALK}/messages", {"body": "長" * 2001}, A); ok("超過 2,000 字不收", s == 400, out["message"])
wsB.close(); time.sleep(0.3)
sent = [call("POST", f"/conversations/{TALK}/messages", {"body": f"斷線期間的第 {i} 則"}, A, 200)[1]["id"] for i in (1, 2, 3)]
missed = messages(B, TALK, f"?after={m1['id']}")
ok("斷線重連後用最後一則的編號補漏，不漏不重複", [m["id"] for m in missed] == sent)
older = messages(B, TALK, f"?before={sent[0]}&limit=2")
ok("往上翻舊訊息：依編號由小到大", len(older) == 2 and older[-1]["id"] == m1["id"] and older[0]["id"] < older[1]["id"])
call("PUT", "/admin/params", {"params": {"message_rate_per_minute": 3}}, admin, 200)
s, out = call("POST", f"/conversations/{TALK}/messages", {"body": "太快了"}, A)
ok("超過每分鐘則數上限回 429", s == 429 and code(out) == "RATE_LIMITED", out["message"])
call("PUT", "/admin/params", {"params": {"message_rate_per_minute": 30}}, admin, 200)

step(4, "接受申請、隊伍群組")
call("POST", f"/conversations/{GA}/messages", {"body": "先記一下：這一隊缺會做簡報的人。"}, A, 200)
s, out = call("POST", f"/engagements/{eng['id']}/accept", {}, B); ok("申請只能由隊長接受", s == 403, out["message"])
wsA.take(0.3)
team = call("POST", f"/engagements/{eng['id']}/accept", {}, A, 200)[1]
ok("接受後成為隊友，名額減一", len(team["members"]) == 2 and team["need"] == 2 and team["status"] == "OPEN")
types = [f["type"] for _, f in wsA.take(1.5)]
ok("隊伍成員即時收到申請與隊伍的狀態更新", "engagement.updated" in types and "team.updated" in types, " → ".join(types))
GB = call("GET", f"/cases/{T}/conversation", None, B, 200)[1]["conversationId"]
gb, ga = messages(B, GB), messages(A, GA)
ok("新成員只看得到加入之後的訊息", GB == GA and len(ga) == 3 and len(gb) == 1 and meB["name"] in gb[0]["body"], f"隊長 {len(ga)} 則、新成員 {len(gb)} 則：{gb[0]['body']}")
ok("洽談對話留著、沒有變唯讀，多一則系統訊息", conv_of(A, eng["id"])["readOnly"] is False and messages(A, TALK)[-1]["kind"] == "SYSTEM")
s, out = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY"}, B)
ok("已經是隊友不能再申請，原因用白話", s == 422 and not any(x.startswith("G") for x in out["reasons"]), "；".join(out["reasons"]))

step(5, "邀請、婉拒、取消、可邀請名額")
s, out = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meC["id"]}, B); ok("只有隊長可以邀請", s == 403, out["message"])
inv = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meC["id"], "message": "想邀請你一起做提案。"}, A, 200)[1]
cc = conv_of(C, inv["id"])
ok("被邀請的人看到洽談對話與邀請時附的話", cc["unread"] == 2 and cc["engagement"]["role"] == "RESPONDER" and messages(C, cc["id"])[-1]["body"] == "想邀請你一起做提案。")
ok("被邀請的人收到站內通知，連到洽談對話", any(n["link"] == f"/messages?e={inv['id']}" for n in notices(C, "INVITE")))
call("POST", f"/engagements/{inv['id']}/decline", {}, C, 200)
cc = conv_of(C, inv["id"])
s, out = call("POST", f"/conversations/{cc['id']}/messages", {"body": "還是可以聊嗎"}, C)
ok("婉拒後洽談對話改唯讀", cc["readOnly"] and cc["engagement"]["status"] == "DECLINED" and s == 409 and code(out) == "READ_ONLY", out["message"])
inv2 = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meD["id"]}, A, 200)[1]
s, out = call("POST", f"/engagements/{inv2['id']}/withdraw", {}, D); ok("只有送出的人可以取消", s == 403, out["message"])
call("POST", f"/engagements/{inv2['id']}/withdraw", {}, A, 200)
ok("取消後對話唯讀，對方收到通知", conv_of(D, inv2["id"])["readOnly"] and len(notices(D, "WITHDRAWN")) == 1)
inv3 = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meD["id"]}, A, 200)[1]
team = call("POST", f"/engagements/{inv3['id']}/accept", {}, D, 200)[1]
ok("被邀請的人接受後加入隊伍", len(team["members"]) == 3 and team["need"] == 1)
inv4 = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meE["id"]}, A, 200)[1]
s, out = call("POST", f"/roles/{ROLE}/engagements", {"direction": "INVITE", "userId": meF["id"]}, A)
ok("等待回覆的邀請也算名額，不能超發", s == 409 and code(out) == "NO_SEAT", out["message"])
app_f = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY", "message": "我也想加入。"}, F, 200)[1]

step(6, "同一場比賽一人一隊")
s, out = call("POST", "/cases", dict(team_in, title="B 的隊"), B); ok("已經在一隊的人不能在同一場比賽再開隊", s == 409 and code(out) == "ALREADY_IN_COMPETITION", out["message"])
team2 = call("POST", "/cases", dict(team_in, title="創業二號", need=2), C, 200)[1]
T2, ROLE2 = team2["id"], team2["roles"][0]["id"]
s, out = call("POST", f"/roles/{ROLE2}/engagements", {"direction": "APPLY"}, B)
ok("已經在一隊的人不能申請同一場比賽的另一隊", s == 422 and "只能參加一隊" in "".join(out["reasons"]), out["message"])
s, out = call("POST", f"/roles/{ROLE2}/engagements", {"direction": "INVITE", "userId": meD["id"]}, C)
ok("也不能被同一場比賽的另一隊邀請", s == 422, out["message"])

step(7, "提前成隊")
s, out = call("POST", f"/cases/{T}/form", {}, B); ok("只有隊長可以確認成隊", s == 403, out["message"])
team = call("POST", f"/cases/{T}/form", {}, A, 200)[1]
ce, cf = conv_of(E, inv4["id"]), conv_of(F, app_f["id"])
ok("提前成隊：狀態改成已成隊，還在等回覆的邀請與申請一併結束、對話唯讀", team["status"] == "FORMED" and ce["readOnly"] and cf["readOnly"]
   and ce["engagement"]["status"] == "FULL" and cf["engagement"]["status"] == "FULL", messages(F, cf["id"])[-1]["body"])
ok("隊伍群組有成隊的系統訊息，提醒下一步是報名", "報名" in messages(B, GB)[-1]["body"], messages(B, GB)[-1]["body"])
s, out = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY"}, G); ok("成隊後不再收申請", s == 409, out["message"])
ok("成隊後不再出現在隊伍牆", all(x["id"] != T for x in call("GET", "/cases/wall", None, G, 200)[1]))
ok("我的隊伍仍然列得出來", any(x["id"] == T for x in call("GET", "/cases/wall?mine=true", None, B, 200)[1]))

step(8, "退出與請離")
s, out = call("POST", f"/cases/{T}/leave", {}, A); ok("隊長不能退出，只能解散", s == 409 and code(out) == "OWNER_CANNOT_LEAVE", out["message"])
s, out = call("POST", f"/cases/{T}/leave", {}, G); ok("不是隊友不能退出", s == 404, out["message"])
call("POST", f"/cases/{T}/leave", {}, D, 200)
team = call("GET", f"/cases/{T}", None, A, 200)[1]
ok("隊友退出：名額釋出，隊伍回到招募中", team["status"] == "OPEN" and len(team["members"]) == 2 and team["need"] == 2, messages(A, GA)[-1]["body"])
s, _ = call("GET", f"/cases/{T}/conversation", None, D); s2, _ = call("GET", f"/conversations/{GA}/messages", None, D)
ok("退出的人看不到隊伍群組", s == 404 and s2 == 404 and all(c["id"] != GA for c in call("GET", "/conversations", None, D, 200)[1]))
ok("隊長收到有人退出的通知", len(notices(A, "MEMBER_LEFT")) == 1)
app_d = call("POST", f"/roles/{ROLE2}/engagements", {"direction": "APPLY"}, D, 200)[1]
ok("退出之後可以申請同一場比賽的另一隊", app_d["status"] == "PENDING")
app_f2 = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY"}, F, 200)[1]
call("POST", f"/engagements/{app_f2['id']}/accept", {}, A, 200)
s, out = call("DELETE", f"/cases/{T}/members/{meF['id']}", None, B); ok("只有隊長可以調整名單", s == 403, out["message"])
s, out = call("DELETE", f"/cases/{T}/members/{meA['id']}", None, A); ok("隊長不能把自己移出", s == 400, out["message"])
team = call("DELETE", f"/cases/{T}/members/{meF['id']}", None, A, 200)[1]
s, _ = call("GET", f"/conversations/{GA}/messages", None, F)
ok("請離：對方離開隊伍與群組，並收到通知", len(team["members"]) == 2 and s == 404 and len(notices(F, "MEMBER_REMOVED")) == 1, messages(A, GA)[-1]["body"])

step(9, "報名追蹤")
solo = call("POST", "/cases", {"competitionId": next(c for c in comps if (c.get("teamMin") or 0) >= 3 and c["daysLeft"] > comp["daysLeft"])["id"], "title": "一人小隊", "need": 2,
                               "skills": [{"skillId": skills["簡報設計"], "required": False}], "intro": ""}, G, 200)[1]
T3 = solo["id"]
s, out = call("POST", f"/cases/{T3}/form", {}, G); ok("人數不到比賽的每隊下限不能成隊", s == 409 and code(out) == "TEAM_TOO_SMALL", out["message"])
s, out = call("POST", f"/cases/{T3}/registration", {}, G); ok("人數不到下限也不能標記已報名", s == 409 and code(out) == "TEAM_TOO_SMALL")
s, out = call("POST", f"/cases/{T}/registration", {}, B); ok("只有隊長可以標記已報名", s == 403, out["message"])
app_h = call("POST", f"/roles/{ROLE}/engagements", {"direction": "APPLY"}, H, 200)[1]
team = call("POST", f"/cases/{T}/registration", {}, A, 200)[1]
ok("標記已報名：名單鎖定，還在等回覆的申請一併結束", team["status"] == "IN_PROGRESS" and team["rosterLocked"] and team["registeredAt"] and conv_of(H, app_h["id"])["engagement"]["status"] == "FULL",
   messages(A, GA)[-1]["body"])
ok("隊友收到已報名的通知", len(notices(B, "REGISTERED")) == 1)
s1, o1 = call("POST", f"/cases/{T}/leave", {}, B); s2, o2 = call("DELETE", f"/cases/{T}/members/{meB['id']}", None, A); s3, o3 = call("POST", f"/cases/{T}/cancel", {}, A)
ok("名單鎖定後不能退出、請離、解散", s1 == 409 and code(o1) == "ROSTER_LOCKED" and s2 == 409 and s3 == 409, o1["message"])
team = call("DELETE", f"/cases/{T}/registration", None, A, 200)[1]
ok("按錯可以取消標記，名單解鎖", team["status"] == "FORMED" and not team["rosterLocked"] and team["registeredAt"] is None)
team = call("POST", f"/cases/{T}/registration", {}, A, 200)[1]
ok("再標記一次", team["status"] == "IN_PROGRESS" and team["rosterLocked"])

step(10, "兩個請求同時進來")
def together(*jobs):
    """同時送出，回傳每一個的 (狀態碼, 內容)"""
    out, gate = [None] * len(jobs), threading.Barrier(len(jobs))
    def run(i, job): gate.wait(); out[i] = job()
    ts = [threading.Thread(target=run, args=(i, j)) for i, j in enumerate(jobs)]
    [t.start() for t in ts]; [t.join() for t in ts]
    return out
one_skill = [{"skillId": skills["簡報設計"], "required": False}]
c1 = next(c for c in comps if "Coding101" in c["name"]); c2 = next(c for c in comps if "金矽" in c["name"])
last = call("POST", "/cases", {"competitionId": c1["id"], "title": "最後一席", "need": 1, "skills": one_skill, "intro": ""}, E, 200)[1]
e1 = call("POST", f"/roles/{last['roles'][0]['id']}/engagements", {"direction": "APPLY"}, G, 200)[1]
e2 = call("POST", f"/roles/{last['roles'][0]['id']}/engagements", {"direction": "APPLY"}, H, 200)[1]
res = together(lambda: call("POST", f"/engagements/{e1['id']}/accept", {}, E), lambda: call("POST", f"/engagements/{e2['id']}/accept", {}, E))
after = call("GET", f"/cases/{last['id']}", None, E, 200)[1]
ok("最後一個名額同時接受兩個人：只有一個成立，不會超收", sorted(r[0] for r in res) == [200, 409] and len(after["members"]) == 2 and after["status"] == "FORMED",
   next(r[1]["message"] for r in res if r[0] == 409))
ta = call("POST", "/cases", {"competitionId": c2["id"], "title": "金矽甲隊", "need": 2, "skills": one_skill, "intro": ""}, F, 200)[1]
tb = call("POST", "/cases", {"competitionId": c2["id"], "title": "金矽乙隊", "need": 2, "skills": one_skill, "intro": ""}, D, 200)[1]
i1 = call("POST", f"/roles/{ta['roles'][0]['id']}/engagements", {"direction": "INVITE", "userId": meB["id"]}, F, 200)[1]
i2 = call("POST", f"/roles/{tb['roles'][0]['id']}/engagements", {"direction": "INVITE", "userId": meB["id"]}, D, 200)[1]
res = together(lambda: call("POST", f"/engagements/{i1['id']}/accept", {}, B), lambda: call("POST", f"/engagements/{i2['id']}/accept", {}, B))
joined = [t for t in (ta, tb) if any(m["userId"] == meB["id"] for m in call("GET", f"/cases/{t['id']}", None, B, 200)[1]["members"])]
ok("同一個人同時接受同一場比賽的兩個邀請：只會加入一隊", sorted(r[0] for r in res) == [200, 409] and len(joined) == 1,
   next(r[1]["message"] for r in res if r[0] == 409))
wsA.take(0.5); before = {m["id"] for m in messages(A, GA, "?limit=200")}
res = together(*[(lambda i=i, tok=tok: call("POST", f"/conversations/{GA}/messages", {"body": f"同時送出的第 {i} 則", "clientId": f"burst-{i}"}, tok)) for i, tok in enumerate([A, B] * 8)])
new_ids = sorted(r[1]["id"] for r in res)
pushed = [f["message"]["id"] for _, f in wsA.take(2.0) if f["type"] == "message.new" and f["conversationId"] == GA]
listed = [m["id"] for m in messages(A, GA, "?limit=200") if m["id"] not in before]
ok("16 則訊息同時送出：全部存下來、依編號排序、全部推送到，沒有漏也沒有重複", all(r[0] == 200 for r in res) and listed == new_ids and sorted(pushed) == new_ids and len(set(new_ids)) == 16,
   f"推送順序與編號順序{'一致' if pushed == new_ids else '不完全一致（用戶端依編號排序）'}")

step(11, "排程：報名提醒、截止、比賽結束（快轉時鐘）")
call("POST", f"/engagements/{app_d['id']}/accept", {}, C, 200)
G2 = call("GET", f"/cases/{T2}/conversation", None, C, 200)[1]["conversationId"]
def clock(hours):
    jobs = call("POST", "/admin/clock", {"hours": hours}, admin, 200)[1]
    failed = {k: v for k, v in jobs.items() if isinstance(v, str) and v.startswith("error")}
    if failed: print(f"FAIL 排程工作失敗 {failed}"); sys.exit(1)
    return jobs
def advance_to(days_left):
    now = call("GET", f"/cases/{T2}", None, C, 200)[1]["daysLeft"]
    return clock((now - days_left) * 24)
def reminders(): return [m for m in messages(C, G2) if m["kind"] == "SYSTEM" and "報名截止還有" in m["body"]]
advance_to(8); ok("截止前 8 天還不提醒", len(reminders()) == 0)
jobs = advance_to(7); ok("截止前 7 天提醒還沒標記報名的隊伍", len(reminders()) == 1 and len(notices(C, "REG_REMINDER")) == 1, reminders()[-1]["body"])
call("POST", "/admin/run-jobs", {}, admin, 200); advance_to(5)
ok("同一個門檻只提醒一次", len(reminders()) == 1)
advance_to(3); advance_to(1)
ok("截止前 3 天、1 天各提醒一次", len(reminders()) == 3, reminders()[-1]["body"])
ok("已經標記報名的隊伍不提醒", not any("報名截止還有" in m["body"] for m in messages(A, GA)))
advance_to(-1)
t2 = call("GET", f"/cases/{T2}", None, C, 200)[1]
ok("報名截止時人數夠的隊伍，以目前名單成隊", t2["status"] == "FORMED" and len(t2["members"]) == 2, messages(C, G2)[-1]["body"])
end = datetime.date.fromisoformat(call("GET", f"/cases/{T3}", None, G, 200)[1]["competitionDeadline"])
today = datetime.date.fromisoformat(comp["applyDeadline"]) + datetime.timedelta(days=1)
clock(((end - today).days + 1) * 24)
t3 = call("GET", f"/cases/{T3}", None, G, 200)[1]
G3 = next(c for c in call("GET", "/conversations", None, G, 200)[1] if c["kind"] == "TEAM" and c["team"]["id"] == T3)
ok("截止時只有隊長一個人的隊伍結束，群組唯讀", t3["status"] == "EXPIRED" and G3["readOnly"], G3["lastMessage"]["body"])
t1 = call("GET", f"/cases/{T}", None, A, 200)[1]
last = datetime.date.fromisoformat(t1["endDate"])
now = end + datetime.timedelta(days=1)
clock(max(0, (last - now).days + 2) * 24)
t1, t2 = call("GET", f"/cases/{T}", None, A, 200)[1], call("GET", f"/cases/{T2}", None, C, 200)[1]
ok("比賽結束後隊伍自動結束：已報名的算完成，沒標記報名的算未完成", t1["status"] == "CLOSED" and t1["closeResult"] == "COMPLETED" and t2["status"] == "CLOSED" and t2["closeResult"] == "INCOMPLETE")
s, out = call("POST", f"/conversations/{GA}/messages", {"body": "辛苦了"}, A)
ok("隊伍結束後群組唯讀", s == 409 and code(out) == "READ_ONLY", messages(A, GA)[-1]["body"])
ok("結束後開始互評（D72 保留）", t1["pendingReviews"] == 1 and len(notices(B, "REVIEW")) == 1)

step(12, "管理員看得到流程紀錄，看不到對話內容")
actions = {l["action"] for l in call("GET", "/admin/event-logs?limit=5000", None, admin, 200)[1]}
ok("開隊、提前成隊、退出、請離、標記報名都有操作紀錄", {"OPEN_TEAM", "FORM_EARLY", "MEMBER_LEFT", "MEMBER_REMOVED", "REGISTERED"} <= actions, "、".join(sorted(actions & {"OPEN_TEAM", "FORM_EARLY", "MEMBER_LEFT", "MEMBER_REMOVED", "REGISTERED", "UNREGISTERED", "FORMED_AT_DEADLINE", "EXPIRE"})))
ok("管理員的對話列表是空的", call("GET", "/conversations", None, admin, 200)[1] == [])

for w in (wsA, bad, silent): w.close()
call("POST", "/admin/reset", {}, admin, 200)
print(f"\n全部通過：{len(PASSED)} 項")
