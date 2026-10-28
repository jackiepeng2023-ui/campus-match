// 依 SwiftUI 程式碼與真實 API 資料，渲染 iPhone 畫面（Linux 無 Xcode，故以 HTML 重現 iOS 17 視覺語言）
const { chromium } = require('playwright');
const fs = require('fs');
const BASE = 'http://localhost:8080/api/v1';
const PW = 'demo1234';
const OUT = __dirname + '/out'; fs.mkdirSync(OUT, { recursive: true });

async function api(method, path, body, token) {
  const r = await fetch(BASE + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: body === undefined ? undefined : JSON.stringify(body) });
  const d = await r.json().catch(() => null);
  if (!r.ok) throw new Error(method + ' ' + path + ' → ' + r.status + ' ' + JSON.stringify(d));
  return d;
}
const login = async (email) => (await api('POST', '/auth/login', { account: email, password: PW })).token;
const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;');
const L = {
  type: { PROJECT: '專題', COMPETITION: '競賽', SHORT_TERM: '短期支援', RESEARCH: '研究協作' },
  status: { DRAFT: '草稿', OPEN: '招募中', FORMED: '已成案', IN_PROGRESS: '執行中', CLOSING: '結案確認中', CLOSED: '已結案', CANCELLED: '已取消', EXPIRED: '截止未成案' },
  eng: { PENDING: '待回覆', ACCEPTED: '已成立', DECLINED: '已拒絕', WITHDRAWN: '已撤回', EXPIRED: '逾時放棄', FULL: '額滿' },
  degree: { BACHELOR: '學士', MASTER: '碩士', PHD: '博士' }, factor: { S: '技能', T: '時間', R: '評價', P: '回應', C: '跨系' },
  attribution: { AUTHORSHIP: '論文掛名', ACK: '致謝', NONE: '無' },
};
const color = (s) => ({ OPEN: '#007AFF', FORMED: '#34C759', IN_PROGRESS: '#34C759', ACCEPTED: '#34C759', CLOSING: '#FF9500', PENDING: '#FF9500', CLOSED: '#AF52DE', CANCELLED: '#FF3B30', EXPIRED: '#FF3B30', DECLINED: '#FF3B30', FULL: '#FF3B30' }[s] || '#8A8A8E');
const day = (s) => String(s || '').slice(0, 10);
const time = (s) => { if (!s) return ''; const d = new Date(s); return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`; };
const hoursLeft = (s) => Math.max(0, Math.round((new Date(s) - Date.now()) / 36e5));
const opt = (v) => v == null ? '—' : Number(v).toFixed(1);
const pct = (v) => Math.round(v * 100) + '%';

// ---------- iOS 元件 ----------
const CSS = `
*{box-sizing:border-box;-webkit-font-smoothing:antialiased}
body{margin:0;background:#fff;font-family:-apple-system,"SF Pro TC","PingFang TC","Noto Sans CJK TC","Noto Sans TC",system-ui,sans-serif;color:#000;font-size:17px;line-height:1.3}
.phone{width:390px;height:844px;background:#F2F2F7;position:relative;overflow:hidden}
.status{height:54px;display:flex;align-items:flex-end;justify-content:space-between;padding:0 28px 8px;font-size:15px;font-weight:600}
.island{position:absolute;left:50%;top:11px;transform:translateX(-50%);width:120px;height:35px;background:#000;border-radius:20px}
.nav{padding:4px 16px 8px;background:#F2F2F7}
.nav .large{font-size:34px;font-weight:700;letter-spacing:-.4px;margin:0}
.nav .inline{font-size:17px;font-weight:600;text-align:center;position:relative}
.nav .back{position:absolute;left:0;top:0;color:#007AFF;font-weight:400;display:flex;align-items:center;gap:4px}
.nav .trailing{position:absolute;right:0;top:0;color:#007AFF}
.content{position:absolute;top:0;left:0;right:0;bottom:0;overflow:hidden}.content.tabbed{bottom:83px}
.scroll{padding:0 16px 100px}
.hdr{font-size:13px;color:#6D6D72;padding:18px 16px 7px;text-transform:none}
.ftr{font-size:13px;color:#6D6D72;padding:6px 16px 0}
.group{background:#fff;border-radius:10px;overflow:hidden}
.row{padding:11px 16px;display:flex;align-items:center;gap:10px;position:relative;min-height:44px}
.row+.row::before{content:"";position:absolute;left:16px;right:0;top:0;height:.5px;background:#C6C6C8}
.row .main{flex:1;min-width:0}
.row .chev{color:#C4C4C6;font-size:17px}
.h{font-size:17px;font-weight:600}
.sub{font-size:12px;color:#8A8A8E;margin-top:2px}
.cap{font-size:12px;color:#8A8A8E}
.pill{display:inline-block;font-size:12px;font-weight:600;padding:3px 9px;border-radius:999px;white-space:nowrap}
.btn{display:inline-block;font-size:15px;font-weight:600;padding:7px 14px;border-radius:8px;background:#007AFF;color:#fff;white-space:nowrap}
.btn.sm{font-size:13px;padding:4px 10px;border-radius:7px}
.btn.bordered{background:rgba(0,122,255,.15);color:#007AFF}
.btn.full{display:block;text-align:center;padding:12px;font-size:17px;border-radius:12px}
.btn.plain{background:transparent;color:#007AFF;padding:0}
.tiles{display:flex;gap:10px;overflow:hidden;padding:6px 0}
.tile{min-width:0;flex:1;background:#fff;border-radius:12px;padding:10px 9px}
.tile .k{font-size:11px;color:#8A8A8E;white-space:nowrap}.tile .v{font-size:19px;font-weight:700;letter-spacing:-.3px;margin-top:2px}
.card{background:#fff;border-radius:14px;padding:14px;margin:6px 0}
.card .top{display:flex;align-items:flex-start;gap:8px}
.score{font-size:22px;font-weight:700;letter-spacing:-.5px;margin-left:auto}
.bd{display:flex;gap:8px;margin-top:8px}
.bd div{flex:1}.bd .f{font-size:11px;color:#8A8A8E}.bd .v{font-size:12px;font-weight:600;margin:1px 0 3px}
.bar{height:5px;border-radius:3px;background:#E5E5EA}.bar i{display:block;height:100%;border-radius:3px;background:#007AFF}
.reason{font-size:12px;color:#8A8A8E;margin-top:4px}
.chips{display:flex;flex-wrap:wrap;gap:6px;margin-top:8px}
.chip{font-size:12px;background:#E9E9EB;border-radius:8px;padding:4px 8px}.chip b{color:#007AFF}.chip s{text-decoration:none;font-size:11px;color:#FF3B30;margin-left:3px}.chip s.opt{color:#8A8A8E}
.tabbar{position:absolute;left:0;right:0;bottom:0;height:83px;background:#F9F9F9;border-top:.5px solid #C6C6C8;display:flex;justify-content:space-around;padding:8px 10px 0}
.tab{display:flex;flex-direction:column;align-items:center;gap:3px;font-size:10px;color:#999;width:70px}
.tab.on{color:#007AFF}.tab svg{width:26px;height:26px}
.home{position:absolute;left:50%;bottom:8px;transform:translateX(-50%);width:134px;height:5px;border-radius:3px;background:#000}
.stars{display:flex;gap:6px;margin:6px 0 2px}.stars span{width:36px;height:36px;border-radius:8px;background:#E9E9EB;display:flex;align-items:center;justify-content:center;font-size:15px;font-weight:600}.stars span.on{background:#007AFF;color:#fff}
.sheet{position:absolute;left:0;right:0;top:40px;bottom:0;background:#F2F2F7;border-radius:12px 12px 0 0;box-shadow:0 -4px 30px rgba(0,0,0,.25)}
.dim{position:absolute;inset:0;background:rgba(0,0,0,.35)}
.tl{display:flex;gap:10px;align-items:flex-start;padding:10px 16px;position:relative}.tl+.tl::before{content:"";position:absolute;left:16px;right:0;top:0;height:.5px;background:#C6C6C8}
.tl .t{width:72px;font-size:12px;color:#8A8A8E;padding-top:3px}
.mono{font-family:ui-monospace,Menlo,monospace;font-size:11.5px;line-height:1.45;white-space:pre-wrap;color:#000}
input.f{width:100%;font:inherit;font-size:17px;padding:10px 12px;border:1px solid #D1D1D6;border-radius:8px;background:#fff}
.banner{position:absolute;left:8px;right:8px;top:62px;background:rgba(255,255,255,.92);border-radius:22px;padding:12px 14px;display:flex;gap:12px;align-items:center;box-shadow:0 6px 30px rgba(0,0,0,.25)}
.appicon{width:38px;height:38px;border-radius:9px;background:linear-gradient(135deg,#0A84FF,#5E5CE6);flex-shrink:0;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:16px}
.seg{display:flex;background:#E9E9EB;border-radius:9px;padding:2px;margin:6px 0}.seg span{flex:1;text-align:center;font-size:13px;font-weight:600;padding:6px;border-radius:7px;color:#000}.seg span.on{background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.12)}
.search{background:#E3E3E8;border-radius:10px;padding:8px 10px;color:#8A8A8E;font-size:17px;display:flex;gap:6px;align-items:center;margin:6px 0 4px}
`;
const icons = {
  house: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 3 2.5 11h2.8v9h5.2v-6h3v6h5.2v-9h2.8z"/></svg>',
  list: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="16" rx="3"/><path d="M7 9h10M7 13h10M7 17h6"/></svg>',
  chart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M3 20h18M4 16l5-6 4 3 7-8"/></svg>',
  person: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9.5"/><circle cx="12" cy="10" r="3.2"/><path d="M5.5 19c1.6-3 4-4.2 6.5-4.2s4.9 1.2 6.5 4.2"/></svg>',
  bell: '<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 17V11a6 6 0 0 1 12 0v6l2 2H4zM10 21h4"/></svg>',
};
const statusBar = () => `<div class="island"></div><div class="status"><span>9:41</span><span>▮▮▮ ᯤ ▭</span></div>`;
const tabbar = (on) => `<div class="tabbar">${[['house', '首頁'], ['list', '案件'], ['chart', '成長'], ['person', '我的檔案']].map(([i, t]) => `<div class="tab ${on === t ? 'on' : ''}">${icons[i]}<span>${t}</span></div>`).join('')}</div><div class="home"></div>`;
const phone = (inner, tab) => `<!doctype html><html><head><meta charset="utf-8"><style>${CSS}</style></head><body><div class="phone">${statusBar()}<div class="content ${tab ? 'tabbed' : ''}" style="top:54px">${inner}</div>${tab ? tabbar(tab) : '<div class="home"></div>'}</div></body></html>`;
const pill = (t, c = '#8A8A8E') => `<span class="pill" style="background:${c}22;color:${c}">${esc(t)}</span>`;
const group = (rows) => `<div class="group">${rows.join('')}</div>`;
const tiles = (st) => `<div class="tiles"><div class="tile"><div class="k">隊友評價</div><div class="v">${opt(st.avgRating)}</div></div><div class="tile"><div class="k">相符度</div><div class="v">${opt(st.avgMatch)}</div></div><div class="tile"><div class="k">可信度</div><div class="v">${Number(st.credibility).toFixed(1)}</div></div><div class="tile"><div class="k">回應率</div><div class="v">${pct(st.responseRate)}</div></div></div>`;
const breakdown = (b) => `<div class="bd">${['S', 'T', 'R', 'P', 'C'].map(k => `<div><div class="f">${L.factor[k]}</div><div class="v">${Number(b[k]).toFixed(2)}</div><div class="bar"><i style="width:${Math.round(b[k] * 100)}%"></i></div></div>`).join('')}</div>`;
const scoreCard = (title, sub, score, b, reasons, action = '', blocked = []) => `<div class="card"><div class="top"><div><div class="h">${esc(title)}</div><div class="cap">${esc(sub)}</div></div><div class="score" style="${blocked.length ? 'color:#8A8A8E' : ''}">${Number(score).toFixed(1)}</div>${action}</div>${breakdown(b)}${blocked.map(x => `<div class="reason" style="color:#FF3B30">⊗ ${esc(x)}</div>`).join('')}${reasons.slice(0, 4).map(r => `<div class="reason">• ${esc(r)}</div>`).join('')}</div>`;
const chips = (skills) => `<div class="chips">${skills.map(s => `<span class="chip">${esc(s.name)} <b>≥${s.minLevel}</b><s class="${(s.isRequired ?? s.required) ? '' : 'opt'}">${(s.isRequired ?? s.required) ? '必要' : '加分'}</s></span>`).join('')}</div>`;

// ---------- 畫面 ----------
const screens = {};
screens.login = () => phone(`<div class="scroll" style="padding-top:70px;text-align:center">
  <div style="font-size:54px;color:#007AFF;margin-bottom:10px">👥</div>
  <div style="font-size:28px;font-weight:700">跨系資源媒合平台</div>
  <div class="cap" style="font-size:15px;margin:6px 0 24px">把分散的人才與合作需求，變成校園內可流動的資源</div>
  <input class="f" value="student002@example.edu" style="margin-bottom:12px"><input class="f" value="••••••••" style="margin-bottom:16px">
  <div class="btn full">登入</div>
  <div class="cap" style="margin-top:14px">示範帳號密碼皆為 demo1234：student002（資工，前端）、student005（創設，UI/UX）、student007（資工，自評上調）</div>
  <div style="position:absolute;bottom:40px;left:0;right:0;color:#007AFF;font-size:13px">API 伺服器設定</div></div>`);

screens.home = (me, pending, recs, mine) => phone(`<div class="nav"><div class="inline">　<span class="trailing">${icons.bell.replace('currentColor', '#FF3B30')}</span></div><h1 class="large">你好，${esc(me.name)}</h1></div><div class="scroll" style="height:790px;overflow:hidden">
  <div class="hdr" style="padding-top:4px">${esc(me.college)}／${esc(me.department)} · ${L.degree[me.degree]}${me.year}年級</div>${tiles(me.stats)}
  <div class="hdr">待我回覆</div>${group(pending.length ? pending.map(e => `<div class="row"><div class="main"><div class="h">${esc(e.caseTitle)}</div><div class="sub">${e.direction === 'INVITE' ? '邀請你擔任' : '你申請'} ${esc(e.roleName)} · 發案方 ${esc(e.ownerName)}</div><div class="sub" style="color:#FF9500">${hoursLeft(e.dueAt)} 小時內回覆，逾時自動視為放棄</div><div style="margin-top:8px;display:flex;gap:8px"><span class="btn sm">接受</span><span class="btn sm bordered">拒絕</span></div></div><span class="chev">›</span></div>`) : [`<div class="row cap">目前沒有待回覆的申請或邀請</div>`])}
  <div class="hdr">推薦給我的案件</div>${recs.slice(0, 2).map(r => scoreCard(r.caseTitle, `${L.type[r.caseType]} · ${r.roleName} · 名額 ${r.filled}/${r.headcount}`, r.score, r.breakdown, r.reasons, '<span class="chev" style="margin-left:6px">›</span>')).join('')}
  <div class="ftr">與發案方看到的推薦用同一組閘門與公式，只是方向相反。</div>
  <div class="hdr">我的案件</div>${group(mine.slice(0, 2).map(c => `<div class="row"><div class="main"><div class="h">${esc(c.title)}</div><div class="sub">${c.ownerId === me.id ? '我發起' : '我是成員'} · ${L.type[c.type]} · 名額 ${c.filled}/${c.headcount}</div></div>${pill(L.status[c.status], color(c.status))}<span class="chev">›</span></div>`))}
</div>`, '首頁');

screens.cases = (items) => phone(`<div class="nav"><h1 class="large">案件</h1><div class="search">🔍 搜尋標題或描述</div></div><div class="scroll" style="height:720px;overflow:hidden">
  <div class="group" style="padding:6px 16px"><div class="seg"><span class="on">全部</span><span>我發起</span><span>我參與</span></div><div class="row" style="padding:8px 0"><div class="main">類型</div><span class="cap">所有類型 ⌃⌄</span></div></div>
  <div class="hdr"></div>${group(items.slice(0, 7).map(c => `<div class="row"><div class="main"><div style="display:flex;align-items:center;gap:8px"><div class="h" style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(c.title)}</div>${pill(L.status[c.status], color(c.status))}</div><div class="sub">${L.type[c.type]} · ${esc(c.ownerName)}（${esc(c.ownerCollege)}） · 名額 ${c.filled}/${c.headcount} · 截止 ${day(c.applyDeadline)}</div>${c.skillNames ? `<div class="sub">需要：${esc(c.skillNames)}</div>` : ''}</div><span class="chev">›</span></div>`))}
</div>`, '案件');

const caseHeader = (c) => `<div class="group" style="padding:12px 16px"><div style="display:flex;gap:6px;flex-wrap:wrap">${pill(L.status[c.status], color(c.status))}${pill(L.type[c.type])}${c.attribution ? pill('成果歸屬：' + L.attribution[c.attribution], '#AF52DE') : ''}</div><div style="font-size:22px;font-weight:700;margin-top:8px;letter-spacing:-.3px">${esc(c.title)}</div><div class="cap" style="margin-top:4px">發案方 ${esc(c.ownerName)}（${esc(c.ownerCollege)}／${esc(c.ownerDepartment)}） · 每隊 ${c.teamSize} 人</div><div class="cap">申請截止 ${time(c.applyDeadline)} · 期間 ${c.startDate} ～ ${c.endDate}</div>${c.description ? `<div style="font-size:15px;margin-top:8px">${esc(c.description)}</div>` : ''}</div>`;
const members = (c) => `<div class="hdr">成員（${c.members.length}/${c.teamSize}）</div>${group(c.members.map(m => `<div class="row"><div class="main"><div>${esc(m.name)}</div><div class="sub">${esc(m.college)}／${esc(m.department)}</div></div>${pill(m.isOwner ? '發案方' : (m.roleName || '成員'), m.isOwner ? '#007AFF' : '#8A8A8E')}</div>`))}`;

screens.caseStudent = (c, myEng) => phone(`<div class="nav"><div class="inline"><span class="back">‹ 案件</span>${esc(c.title)}</div></div><div class="scroll" style="height:740px;overflow:hidden">
  ${caseHeader(c)}
  ${c.roles.map(r => { const e = myEng(r.id); return `<div class="hdr">角色：${esc(r.roleName)}</div><div class="group" style="padding:12px 16px"><div style="display:flex;align-items:center"><div style="flex:1"><div class="h">${esc(r.roleName)}</div><div class="sub">名額 ${r.filledCount}/${r.headcount} · 每週 ${r.hoursPerWeek} 小時</div></div>${e ? pill((e.direction === 'INVITE' ? '邀請' : '申請') + '：' + L.eng[e.status], color(e.status)) : `<span class="btn sm">申請</span>`}</div>${chips(r.skills)}${e && e.status === 'PENDING' ? `<div style="display:flex;align-items:center;gap:8px;margin-top:10px"><span class="cap" style="color:#FF9500;flex:1">${hoursLeft(e.dueAt)} 小時內需回覆</span>${e.direction === 'INVITE' ? '<span class="btn sm">接受邀請</span><span class="btn sm bordered">拒絕</span>' : '<span class="btn sm bordered">撤回申請</span>'}</div>` : ''}</div>`; }).join('')}
  ${members(c)}
</div>`, '案件');

screens.caseOwner = (c, rec) => phone(`<div class="nav"><div class="inline"><span class="back">‹ 案件</span>${esc(c.title)}</div></div><div class="scroll" style="height:740px;overflow:hidden">
  <div class="hdr">角色：${esc(c.roles[0].roleName)}</div><div class="group" style="padding:12px 16px"><div style="display:flex;align-items:center"><div style="flex:1"><div class="h">${esc(c.roles[0].roleName)}</div><div class="sub">名額 ${c.roles[0].filledCount}/${c.roles[0].headcount} · 每週 ${c.roles[0].hoursPerWeek} 小時 · 可邀請 ${rec.role.invitable}</div></div><span class="btn sm bordered">重新整理推薦</span></div>${chips(c.roles[0].skills)}</div>
  ${rec.recommended.slice(0, 3).map(p => scoreCard(p.name, `${p.college} ${p.dept} · ${L.degree[p.degree]}${p.year}年級`, p.score, p.breakdown, p.reasons, `<span class="btn sm" style="margin-left:8px">邀請</span>`)).join('')}
  <div class="group" style="margin-top:6px"><div class="row"><div class="main">技能符合但被閘門擋下的 ${rec.blocked.length} 人</div><span class="chev">⌄</span></div></div>
  ${rec.blocked.slice(0, 1).map(p => scoreCard(p.name, `${p.college} ${p.dept}`, p.score, p.breakdown, p.reasons, '', p.blockedBy)).join('')}
</div>`, '案件');

screens.closing = (c) => phone(`<div class="nav"><div class="inline"><span class="back">‹ 案件</span>${esc(c.title)}</div></div><div class="scroll" style="height:740px;overflow:hidden">
  ${caseHeader(c)}
  <div class="hdr">結案確認中</div><div class="group" style="padding:12px 16px"><div style="font-size:15px">發案方提出「${c.closeRequest.result === 'COMPLETED' ? '完成' : '未完成'}」結案，期限 ${time(c.closeRequest.dueAt)}；已投票 ${c.closeRequest.votes.length} 人</div><div style="display:flex;gap:8px;margin-top:10px"><span class="btn">同意結案</span><span class="btn bordered">不同意</span></div><div class="cap" style="margin-top:8px">72 小時內過半成員同意即成立；未回應視為同意。完成與未完成都會開放互評。</div></div>
  ${members(c)}
</div>`, '案件');

screens.review = (p) => phone(`<div class="nav"><div class="inline"><span class="back">‹ 返回</span>互評</div></div><div class="scroll" style="height:740px;overflow:hidden">
  <div class="group" style="padding:10px 16px"><div class="cap">四題各 1–5 分。「能力與檔案相符」會影響對方自填資料在推薦中的權重。評價匿名，雙方都送出才同時公開。</div></div>
  ${p.items.filter(i => !i.submittedAt).map(it => `<div class="hdr">${esc(it.name)}${it.isOwner ? '（發案方）' : ''} · ${esc(it.department)}</div><div class="group">${[['整體合作滿意度', 5], ['實際能力與檔案相符嗎', 5], ['是否準時完成分內工作', 4], ['溝通與回應是否及時', 5]].map(([q, v]) => `<div class="row" style="display:block"><div style="font-size:15px">${q}</div><div class="stars">${[1, 2, 3, 4, 5].map(n => `<span class="${v >= n ? 'on' : ''}">${n}</span>`).join('')}</div></div>`).join('')}${p.askAttribution && it.isOwner ? `<div class="row"><div class="main" style="font-size:15px">承諾的成果歸屬是否兌現</div><span class="cap" style="color:#000">是 ⌃⌄</span></div>` : ''}<div class="row"><span class="cap" style="font-size:15px;color:#C4C4C6">評語（選填，只有對方看得到）</span></div></div>`).join('')}
  <div class="hdr"></div><div class="group"><div class="row" style="justify-content:center;color:#007AFF;font-weight:600">送出評價</div></div>
</div>`, '案件');

const radarSVG = (radar) => { const n = radar.length, cx = 170, cy = 125, R = 92; const pt = (r, i) => { const a = -Math.PI / 2 + i * 2 * Math.PI / n; return [cx + r * Math.cos(a), cy + r * Math.sin(a)]; }; let s = `<svg width="340" height="250" viewBox="0 0 340 250">`; for (let ring = 1; ring <= 5; ring++) s += `<polygon points="${radar.map((_, i) => pt(R * ring / 5, i).join(',')).join(' ')}" fill="none" stroke="#D1D1D6" stroke-width=".8"/>`; radar.forEach((_, i) => { const [x, y] = pt(R, i); s += `<line x1="${cx}" y1="${cy}" x2="${x}" y2="${y}" stroke="#D1D1D6" stroke-width=".8"/>`; }); s += `<polygon points="${radar.map((r, i) => pt(R * r.avgLevel / 5, i).join(',')).join(' ')}" fill="rgba(0,122,255,.18)" stroke="#007AFF" stroke-width="2"/>`; radar.forEach((r, i) => { const [x, y] = pt(R + 20, i); s += `<text x="${x}" y="${y + 4}" text-anchor="middle" font-size="12" fill="#000">${esc(r.category)}</text>`; }); return s + '</svg>'; };
screens.growth = (g, prompt) => phone(`<div class="nav"><h1 class="large">成長</h1></div><div class="scroll" style="height:740px;overflow:hidden">
  <div class="hdr">技能雷達（各類別平均等級）</div><div class="group" style="padding:6px;text-align:center">${radarSVG(g.radar)}</div>
  ${tiles(g.stats)}
  <div class="hdr">AI 成長建議</div><div class="group"><div class="row" style="font-size:15px">成長目標：成為前端工程師</div><div class="row" style="font-size:15px">想問的問題：下學期該補什麼？</div><div class="row" style="color:#007AFF;font-weight:600">產生 Prompt</div><div class="row" style="display:block"><div class="cap" style="color:#FF9500;margin-bottom:6px">${esc(prompt.notice).slice(0, 60)}…</div><div class="mono">${esc(prompt.prompt).slice(0, 230)}…</div></div><div class="row" style="color:#007AFF;font-weight:600">複製到剪貼簿</div></div>
  <div class="hdr">成長時間軸</div><div class="group">${g.timeline.slice(0, 3).map(t => `<div class="tl"><span class="t">${time(t.ts)}</span>${pill({ SKILL: '技能', CASE_JOINED: '加入', CASE_OWNED: '發起', CASE_CLOSED: '結案', AWARD: '得獎', REVIEW: '評價' }[t.kind] || t.kind, { SKILL: '#007AFF', CASE_CLOSED: '#AF52DE', AWARD: '#FF9500', REVIEW: '#34C759' }[t.kind] || '#8A8A8E')}<span style="font-size:14px;flex:1">${esc(t.text)}</span></div>`).join('')}</div>
</div>`, '成長');

screens.profile = (me) => phone(`<div class="nav"><h1 class="large">我的檔案</h1></div><div class="scroll" style="height:740px;overflow:hidden">
  <div class="hdr"></div>${group([`<div class="row"><div class="main">學號</div><span class="cap" style="font-size:17px">${esc(me.studentNo)}</span></div>`, `<div class="row"><div class="main">系所</div><span class="cap" style="font-size:15px">${esc(me.college)}／${esc(me.department)}</span></div>`, `<div class="row"><div class="main">學制</div><span class="cap" style="font-size:17px">${L.degree[me.degree]} ${me.year} 年級</span></div>`, `<div class="row"><div class="main">別人看到的我</div><span class="chev">›</span></div>`])}
  <div class="hdr">可投入時間（時間閘門）</div>${group([`<div class="row"><div class="main">每週可投入 ${me.availability.hoursPerWeek} 小時</div><span style="background:#E9E9EB;border-radius:8px;padding:4px 10px;font-size:15px">−　|　+</span></div>`])}
  <div class="hdr">技能檔</div>${group(me.skills.slice(0, 4).map(s => `<div class="row"><div class="main"><div>${esc(s.name)}</div><div class="sub">${esc(s.category)} · 預設 ${s.defaultLevel ?? '—'} · ${s.source === 'GRADE' ? (s.level !== s.defaultLevel ? '自評上調' : '成績換算') : '自填'}</div></div><span class="cap" style="font-size:17px;color:#000">${s.level} 級 ⌃⌄</span></div>`))}
  <div class="ftr">預設等級來自成績；你可以調整，幅度會被記錄，由結案互評的「相符度」檢驗。對外只顯示等級。</div>
  <div class="hdr">修課成績（只有你看得到）</div>${group(me.grades.slice(0, 3).map(g => `<div class="row"><div class="main"><div>${esc(g.course)}</div><div class="sub">${esc(g.semester)}${g.skills ? ' → ' + esc(g.skills) : ''}</div></div><span class="h">${g.score}</span></div>`))}
</div>`, '我的檔案');

screens.notifications = (n) => phone(`<div class="dim"></div><div class="sheet"><div class="nav" style="padding-top:14px;border-radius:12px 12px 0 0"><div class="inline"><span class="back" style="padding-left:0">關閉</span>通知<span class="trailing">全部已讀</span></div></div><div class="scroll">${group(n.items.slice(0, 6).map(x => `<div class="row" style="${x.readAt ? '' : 'background:rgba(0,122,255,.08)'}"><div class="main"><div style="display:flex;gap:8px"><div class="h" style="flex:1">${esc(x.title)}</div><span class="cap">${time(x.createdAt)}</span></div><div class="sub" style="font-size:14px;color:#6D6D72">${esc(x.body)}</div></div></div>`))}</div></div>`, '首頁');

screens.push = (n) => `<!doctype html><html><head><meta charset="utf-8"><style>${CSS}.phone{background:linear-gradient(160deg,#1c2b4a,#4a2e6b 60%,#0b3a5c)}.status{color:#fff}</style></head><body><div class="phone">${statusBar()}<div style="position:absolute;top:120px;left:0;right:0;text-align:center;color:#fff"><div style="font-size:22px;font-weight:500">10月27日 星期二</div><div style="font-size:84px;font-weight:600;letter-spacing:-2px;line-height:1">9:41</div></div><div class="banner" style="top:300px"><div class="appicon">媒</div><div style="flex:1"><div style="display:flex"><div class="h" style="flex:1;font-size:15px">跨系媒合</div><span class="cap">現在</span></div><div style="font-size:15px;font-weight:600">${esc(n.title)}</div><div style="font-size:15px;color:#333">${esc(n.body)}</div></div></div><div class="home" style="background:#fff"></div></div></body></html>`;

(async () => {
  // ---- 資料與劇本 ----
  const T = {}; for (const i of [1, 2, 3, 4, 5, 7, 8]) T[i] = await login(`student${String(i).padStart(3, '0')}@example.edu`);
  const allCases = await api('GET', '/cases', undefined, T[2]);
  const feCase = allCases.find(c => c.title === '校園活動報名網站');          // student004 發起，前端 Vue≥3
  const rsCase = allCases.find(c => c.status === 'OPEN' && c.type === 'RESEARCH' && c.ownerName === '蕭婉婷'); // 博士生研究協作
  const fe = await api('GET', `/cases/${feCase.id}`, undefined, T[4]);
  // 發案方看推薦 → 邀請王雅婷（首頁「待我回覆」與案件詳情用）
  const rec = await api('GET', `/roles/${fe.roles[0].id}/recommendations`, undefined, T[4]);
  await api('POST', `/roles/${fe.roles[0].id}/engagements`, { direction: 'INVITE', userId: 2, message: '' }, T[4]);
  // 研究協作：邀請郭昱辰 → 接受 → 開始 → 提出結案（CLOSING 畫面）→ 同意 → CLOSED → 互評畫面
  const rs = await api('GET', `/cases/${rsCase.id}`, undefined, T[8]);
  const inv = await api('POST', `/roles/${rs.roles[0].id}/engagements`, { direction: 'INVITE', userId: 4, message: '' }, T[8]);
  await api('POST', `/engagements/${inv.id}/accept`, {}, T[4]);
  await api('POST', `/cases/${rs.id}/start`, {}, T[8]);
  const closing = await api('POST', `/cases/${rs.id}/close-requests`, { result: 'COMPLETED' }, T[8]);
  const closingView = await api('GET', `/cases/${rs.id}`, undefined, T[4]);
  await api('POST', `/close-requests/${closing.closeRequest.id}/votes`, { agree: true }, T[4]);
  const pendingReviews = await api('GET', `/cases/${rs.id}/reviews/pending`, undefined, T[4]);

  const me2 = await api('GET', '/me', undefined, T[2]);
  const eng2 = await api('GET', '/me/engagements', undefined, T[2]);
  const recs2 = await api('GET', '/me/recommended-cases', undefined, T[2]);
  const mine2 = await api('GET', '/cases?member=true', undefined, T[2]);
  const feView2 = await api('GET', `/cases/${fe.id}`, undefined, T[2]);
  const me7 = await api('GET', '/me', undefined, T[7]);
  const g7 = await api('GET', '/me/growth', undefined, T[7]);
  const prompt7 = await api('POST', '/me/growth-prompt', { goal: '成為前端工程師', question: '下學期該補什麼？' }, T[7]);
  const notif7 = await api('GET', '/me/notifications', undefined, T[7]);
  const notif2 = await api('GET', '/me/notifications', undefined, T[2]);

  const pages = {
    '01-login': screens.login(),
    '02-home': screens.home(me2, eng2.filter(e => e.status === 'PENDING'), recs2, mine2),
    '03-cases': screens.cases(allCases),
    '04-case-student': screens.caseStudent(feView2, (rid) => feView2.myEngagements.find(e => e.roleId === rid)),
    '05-case-owner-rec': screens.caseOwner(fe, rec),
    '06-closing': screens.closing(closingView),
    '07-review': screens.review(pendingReviews),
    '08-growth': screens.growth(g7, prompt7),
    '09-profile': screens.profile(me7),
    '10-notifications': screens.notifications(notif7),
    '11-push': screens.push(notif2.items[0]),
  };
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  for (const [name, html] of Object.entries(pages)) {
    fs.writeFileSync(`${OUT}/${name}.html`, html);
    await page.setContent(html, { waitUntil: 'load' });
    await page.screenshot({ path: `${OUT}/${name}.png` });
    console.log('rendered', name);
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
