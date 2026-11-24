// Fomo鬆 3.1 網頁測試（Playwright）：兩個瀏覽器分別當隊長與被邀請的同學，把主線走一遍：
// 找隊友 → 選比賽 → 開隊 → 推薦與邀請 → 洽談（即時收到對方訊息）→ 接受 → 隊伍群組 → 標記已報名；再看手機版、個人頁、AI 助理、管理頁。
// 檢查沒有 console／頁面／API 錯誤，畫面上沒有 undefined、NaN、[object Object]，圖片（橫幅與松鼠）都有載到；並輸出截圖。
// 一開始會重置示範資料，只能對 Demo 模式的環境執行。
//   node web/tools/fomo_ui.cjs [baseURL] [截圖資料夾]       密碼讀 APP_DEMO_PASSWORD；SHOT_SCALE=2 可輸出兩倍解析度
const { chromium } = require('playwright');
const fs = require('fs');
const BASE = process.argv[2] || 'http://localhost:8080';
const OUT = process.argv[3] || 'docs/screenshots';
const PW = process.env.APP_DEMO_PASSWORD || 'demo1234';
const SCALE = Number(process.env.SHOT_SCALE || 1);
fs.mkdirSync(OUT, { recursive: true });
const errors = [], passed = [];
const BAD = [/undefined/, /\bNaN\b/, /\[object Object\]/, /Invalid Date/, /\b20\d\d,\d{1,2},\d{1,2}\b/, /\bnull\b/];
const ok = (name, cond, detail = '') => { if (!cond) { console.log(`FAIL ${name} ${detail}`); process.exitCode = 1; throw new Error(name); } passed.push(name); console.log(`  ✓ ${name}${detail ? '　' + detail : ''}`); };
const account = (id) => `student${String(id).padStart(3, '0')}@example.edu`;

async function api(method, path, token, body) {
  const r = await fetch(BASE + '/api/v1' + path, { method, headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) }, body: body ? JSON.stringify(body) : undefined });
  return r.json();
}

(async () => {
  const admin = (await api('POST', '/auth/login', null, { account: 'admin@example.edu', password: PW })).token;
  await api('POST', '/admin/reset', admin, {});
  const browser = await chromium.launch();

  async function open(who, viewport = { width: 1280, height: 900 }, mobile = false) {
    const ctx = await browser.newContext({ viewport, deviceScaleFactor: SCALE, locale: 'zh-TW', timezoneId: 'Asia/Taipei', isMobile: mobile, hasTouch: mobile });
    const page = await ctx.newPage();
    page.on('console', m => { if (m.type() === 'error') errors.push(who + ' console: ' + m.text()); });
    page.on('pageerror', e => errors.push(who + ' pageerror: ' + e.message));
    page.on('response', r => { if (r.status() >= 400 && r.url().includes('/api/')) errors.push(who + ' http ' + r.status() + ' ' + r.url()); });
    await page.goto(BASE + '/#/login');
    await page.fill('#acc', who); await page.fill('#pw', PW);
    await page.click('form button.btn');
    await page.waitForSelector('.top .logo');
    return page;
  }
  async function shot(page, name, full = true) {
    await page.waitForFunction(() => !document.querySelector('.toast'), null, { timeout: 8000 }).catch(() => {});      // 等提示訊息消失再截圖
    if (full) await page.evaluate(() => window.scrollTo(0, 0));
    const broken = await page.evaluate(async () => {
      const imgs = [...document.images];
      await Promise.all(imgs.map(i => i.complete ? 0 : new Promise(r => { i.onload = i.onerror = r; })));
      return imgs.filter(i => !i.naturalWidth).map(i => i.src.split('/').pop());
    });
    if (broken.length) errors.push(`${name} 有圖片沒載到：${broken.join('、')}`);
    const text = await page.evaluate(() => document.body.innerText);
    for (const re of BAD) if (re.test(text)) errors.push(`${name} 畫面出現 ${re}：…${text.slice(Math.max(0, text.search(re) - 30), text.search(re) + 30).replace(/\n/g, ' ')}…`);
    await page.screenshot({ path: `${OUT}/${name}.png`, fullPage: full });
  }
  const nav = (page, label) => page.click(`.mainnav a:has-text("${label}")`);
  // 指定的圖片有幾張、是不是都載到了（沒載到回傳 -1）
  const pics = (page, sel) => page.evaluate(async (sel) => {
    const imgs = [...document.querySelectorAll(sel)];
    await Promise.all(imgs.map(i => i.complete ? 0 : new Promise(r => { i.onload = i.onerror = r; })));
    return imgs.every(i => i.naturalWidth > 0) ? imgs.length : -1;
  }, sel);

  console.log('\n=== 登入頁');
  const L = await (await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: SCALE, locale: 'zh-TW' })).newPage();
  await L.goto(BASE + '/#/login'); await L.waitForSelector('.login-brand .mascot');
  ok('登入頁有松鼠', await pics(L, '.login-brand img') === 1);
  await shot(L, '00-登入', false);
  await L.context().close();

  console.log('\n=== 隊長（示範帳號）：找隊友、訊息、比賽');
  const A = await open(account(1));
  await A.waitForSelector('.tcard');
  ok('找隊友列出招募中的隊伍', await A.locator('.tcard').count() >= 6, `${await A.locator('.tcard').count()} 支`);
  ok('訊息分頁有未讀紅點', (await A.locator('.mainnav a:has-text("訊息") .badge').innerText()) === '2');
  ok('找隊友頂端有橫幅，頁首標誌與 AI 助理按鈕有松鼠', await pics(A, '.banner img') === 1 && await pics(A, '.top .logo img') === 1 && await pics(A, 'a.fab img') === 1);
  await shot(A, '01-找隊友');
  await A.fill('input[type=search]', '找不到的關鍵字'); await A.press('input[type=search]', 'Enter'); await A.waitForSelector('.card.soft.empty .mascot');
  ok('找不到隊伍時有松鼠和下一步', await pics(A, '.empty img') === 1 && await A.locator('.empty .btn').count() === 2);
  await A.click('.empty button:has-text("看全部隊伍")'); await A.waitForSelector('.tcard');
  await A.click('.fpill:has-text("適合我")'); await A.waitForFunction(() => document.querySelectorAll('.tcard').length === 2);
  ok('「適合我」只留適合的隊伍，卡片上有白話理由', await A.locator('.tcard .tag.green').count() >= 2, (await A.locator('.tcard .tag.green').allInnerTexts()).join('、'));
  await nav(A, '訊息'); await A.waitForSelector('.im-head');
  ok('寬螢幕直接打開有未讀的對話，可以接受或婉拒邀請', await A.locator('.im-head button:has-text("接受")').count() === 1 && await A.locator('.im-msg .bubble').count() === 1);
  await A.waitForFunction(() => !document.querySelector('.mainnav .badge'));
  ok('打開對話後未讀歸零', true);
  await shot(A, '02-訊息-收到邀請', false);
  await nav(A, '比賽'); await A.waitForSelector('.tcard');
  ok('比賽頁的標題旁有松鼠', await pics(A, '.head.art img') === 1);
  await shot(A, '03-比賽');

  console.log('\n=== 開隊、推薦、邀請');
  await A.click('.tcard h3 a:has-text("FITI")'); await A.waitForSelector('#tname');
  await A.fill('#tname', '創業一號'); await A.fill('#tneed', '2');
  const picks = A.locator('form label.pick'); await picks.nth(0).click(); await picks.nth(1).click();
  await A.fill('#tintro', '想做校園二手教科書平台，缺會做簡報和介面的隊友。');
  await shot(A, '04-比賽詳情-開隊');
  await A.click('form button:has-text("開隊")'); await A.waitForURL('**/#/teams/*');
  await A.waitForSelector('text=推薦的隊友'); await A.waitForSelector('button:has-text("邀請")');
  const teamUrl = A.url();
  ok('開隊後到隊伍頁，直接看到推薦的隊友', await A.locator('button:has-text("邀請")').count() >= 3);
  ok('推薦名單不顯示分數', !/\d+\.\d 分|契合度|S_weighted/.test(await A.locator('main').innerText()));
  await shot(A, '05-隊伍頁-隊長');
  const invitee = await A.locator('section:has-text("推薦的隊友") a[href*="/users/"]').first();
  const inviteeName = await invitee.innerText(), inviteeId = +(await invitee.getAttribute('href')).split('/').pop();
  await A.locator('section:has-text("推薦的隊友") button:has-text("邀請")').first().click();
  await A.fill('section:has-text("推薦的隊友") textarea', '看到你的專長很適合，想邀請你一起打這場比賽。');
  await A.click('button:has-text("送出邀請")'); await A.waitForSelector('text=邀請中，等對方回覆');
  ok('送出邀請後列在「邀請中」', true, inviteeName);

  console.log('\n=== 被邀請的同學：洽談、即時訊息、接受');
  const B = await open(account(inviteeId));
  ok('被邀請的同學看到通知與訊息的紅點', await B.locator('.round .badge').count() === 1 && await B.locator('.mainnav a:has-text("訊息") .badge').count() === 1);
  await nav(B, '訊息'); await B.waitForSelector('.im-head button:has-text("接受")');
  await A.click('a:has-text("聊聊")'); await A.waitForSelector('.im-foot textarea');
  const t0 = Date.now();
  await B.fill('.im-foot textarea', '好啊，可以先說一下題目方向嗎？'); await B.press('.im-foot textarea', 'Enter');
  await A.waitForSelector('.im-msg:not(.mine) .bubble:has-text("題目方向")', { timeout: 3000 });
  ok('對方送出的訊息即時出現，不用重新整理', true, `${Date.now() - t0} 毫秒（含輸入）`);
  await A.fill('.im-foot textarea', '做校園二手教科書平台，想請你負責簡報和訪談。'); await A.click('.im-foot button:has-text("傳送")');
  await B.waitForSelector('.im-msg:not(.mine) .bubble:has-text("二手教科書")', { timeout: 3000 });
  await shot(B, '06-洽談-被邀請的同學', false);
  await B.click('.im-head button:has-text("接受")'); await B.waitForSelector('.im-sys:has-text("已經是隊友了")');
  await B.waitForSelector('.im-item:has-text("創業一號") .s:has-text("人")');
  ok('接受後成為隊友，隊伍群組出現在「我的隊伍」', true);
  await A.waitForSelector('.im-sys:has-text("已經是隊友了")', { timeout: 3000 });
  ok('隊長那邊即時看到對方已接受', await A.locator('.im-head button:has-text("取消邀請")').count() === 0);

  console.log('\n=== 隊伍群組、報名追蹤');
  await A.goto(teamUrl); await A.click('button:has-text("進入隊伍群組")'); await A.waitForSelector('.track');
  await A.fill('.im-foot textarea', '歡迎加入！我今天晚上去官網報名。'); await A.press('.im-foot textarea', 'Enter');
  await B.click('.im-item:has-text("創業一號") >> nth=0'); await B.waitForSelector('.track');
  await B.waitForSelector('.im-msg:not(.mine) .bubble:has-text("歡迎加入")', { timeout: 3000 });
  ok('新成員只看到加入之後的訊息', await B.locator('.im-sys:has-text("隊伍群組開好了")').count() === 0 && await B.locator(`.im-sys:has-text("加入了隊伍")`).count() === 1);
  await shot(A, '07-隊伍群組-報名追蹤', false);
  ok('隊友看得到報名追蹤，但沒有標記按鈕', await B.locator('.track button:has-text("標記已報名")').count() === 0);
  await A.click('.track button:has-text("標記已報名")'); await A.click('.track button:has-text("標記已報名")');
  await A.waitForSelector('.track .big:has-text("已報名")');
  await B.waitForSelector('.track .big:has-text("已報名")', { timeout: 3000 });
  ok('隊長標記已報名，隊友的畫面即時更新、名單鎖定', await A.locator('.im-sys:has-text("名單鎖定")').count() === 1);
  ok('已報名後，報名追蹤出現歡呼的松鼠', await pics(A, '.track .sticker') === 1 && await pics(B, '.track .sticker') === 1);
  await shot(A, '08-隊伍群組-已報名', false);
  await B.click('a:has-text("成員與邀請")'); await B.waitForSelector('text=隊伍成員');
  ok('名單鎖定後隊友沒有退出按鈕', await B.locator('button:has-text("退出隊伍")').count() === 0);
  await shot(B, '09-隊伍頁-隊友');

  console.log('\n=== 個人頁、AI 助理、管理頁');
  await nav(A, '個人頁'); await A.waitForSelector('text=AI 成長建議 Prompt');
  ok('兩格都填之前不能產生 Prompt', await A.locator('button:has-text("產生 Prompt")').isDisabled());
  await A.fill('#gp-goal', '畢業後做產品企劃'); await A.fill('#gp-q', '下學期該補什麼能力、適合參加哪種比賽？');
  await A.click('button:has-text("產生 Prompt")'); await A.waitForSelector('#gp-text');
  ok('個人頁可以產生 AI 成長建議 Prompt', (await A.inputValue('#gp-text')).length > 100);
  await shot(A, '10-個人頁');
  await A.click('a.fab'); await A.waitForSelector('text=說出你的目標');
  ok('AI 助理頁有松鼠，這一頁不顯示浮動按鈕', await pics(A, '.with-art.intro img') === 1 && await A.locator('a.fab').count() === 0);
  await shot(A, '11-AI助理', false);
  const M = await open('admin@example.edu'); await M.waitForSelector('.mainnav a:has-text("管理")');
  await M.goto(BASE + '/#/admin'); await M.waitForSelector('.card');
  await M.waitForFunction(() => document.querySelectorAll('canvas[style*="display"]').length >= 2);      // 兩張圖表畫好
  await M.waitForSelector('text=最近的對話');                                                            // 最後一批資料回來
  await shot(M, '12-管理頁', false);
  await M.goto(BASE + '/#/messages'); await M.waitForSelector('text=還沒有對話');
  ok('管理員的訊息頁是空的，空白處有松鼠', await pics(M, '.im-main .sticker') === 1);

  console.log('\n=== 手機版');
  const P = await open(account(inviteeId), { width: 390, height: 844 }, true);
  await P.waitForSelector('.tcard');
  ok('手機版用底部分頁，頁首的選單收起來', await P.locator('.tabbar').isVisible() && !(await P.locator('.mainnav').isVisible()));
  ok('手機版沒有水平捲動', await P.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth));
  ok('手機版的 AI 助理入口在頁首，右下角不放浮動按鈕', await P.locator('.round.ai').isVisible() && !(await P.locator('a.fab').isVisible()) && await pics(P, '.round.ai img') === 1);
  await shot(P, '13-手機-找隊友', false);
  await P.click('.tabbar a:has-text("訊息")'); await P.waitForSelector('.im-item');
  ok('手機版訊息先看列表', await P.locator('.im-list').isVisible() && !(await P.locator('.im-main').isVisible()));
  await shot(P, '14-手機-訊息列表', false);
  await P.click('.im-item:has-text("創業一號") >> nth=0'); await P.waitForSelector('.track');
  ok('點進對話後只顯示對話，有返回鈕', await P.locator('.im-back').isVisible() && !(await P.locator('.im-list').isVisible()));
  ok('手機版的報名追蹤先收成一行，訊息區看得到', await P.locator('.track.folded').count() === 1 && await P.locator('.im-sys').first().isVisible());
  const box = await P.locator('.im-foot').boundingBox(), bar = await P.locator('.tabbar').boundingBox();
  ok('輸入列在底部分頁上方，沒有被蓋住', box.y + box.height <= bar.y + 1, `輸入列底 ${Math.round(box.y + box.height)}、分頁頂 ${Math.round(bar.y)}`);
  await P.screenshot({ path: `${OUT}/15-手機-隊伍群組.png` });
  await P.click('.track .toggle'); await P.waitForSelector('.track .checks');
  ok('手機版對話沒有水平捲動', await P.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth));
  await shot(P, '16-手機-報名追蹤展開', false);

  await browser.close();
  await api('POST', '/admin/reset', admin, {});
  if (errors.length) { console.log('\n發現問題：\n' + errors.join('\n')); process.exit(1); }
  console.log(`\n全部通過：${passed.length} 項；截圖在 ${OUT}`);
})().catch(e => { console.error(e.message.split('\n')[0]); if (errors.length) console.log(errors.join('\n')); process.exit(1); });
