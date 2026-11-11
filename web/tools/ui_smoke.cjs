// 網頁冒煙測試（Playwright）：用示範帳號把主要畫面走一遍，檢查沒有 console／頁面／API 錯誤，畫面上沒有 undefined、NaN、[object Object]、
// 被寫成 2026,11,20 的日期；並輸出截圖。會寫入資料（建立案件、送出邀請、下架後恢復一位教師），請對可重置的示範環境執行。
//   node web/tools/ui_smoke.cjs [baseURL] [截圖資料夾]        需要：npm i -D playwright && npx playwright install chromium
const { chromium } = require('playwright');
const fs = require('fs');
const BASE = process.argv[2] || 'http://localhost:8080';
const OUT = process.argv[3] || 'docs/screenshots';
const SCALE = Number(process.env.SHOT_SCALE || 1);          // 截圖倍率；文件用 1 倍即可，需要高解析度時設 SHOT_SCALE=2
fs.mkdirSync(OUT, { recursive: true });
const errors = [];
const BAD = [/undefined/, /\bNaN\b/, /\[object Object\]/, /Invalid Date/, /\b20\d\d,\d{1,2},\d{1,2}\b/, /\bnull\b/];
(async () => {
  const browser = await chromium.launch();
  async function session(email, fn, viewport = { width: 1280, height: 900 }) {
    const ctx = await browser.newContext({ viewport, deviceScaleFactor: SCALE, locale: 'zh-TW' });
    const page = await ctx.newPage();
    page.on('console', m => { if (m.type() === 'error') errors.push(email + ' console: ' + m.text()); });
    page.on('pageerror', e => errors.push(email + ' pageerror: ' + e.message));
    page.on('response', r => { if (r.status() >= 400 && r.url().includes('/api/')) errors.push(email + ' http ' + r.status() + ' ' + r.url()); });
    await page.goto(BASE + '/#/login');
    await page.fill('input[placeholder="student001@example.edu"]', email);
    await page.fill('input[type="password"]', 'demo1234');
    await page.click('button.btn');
    await page.waitForURL('**/#/');
    await fn(page);
    await ctx.close();
  }
  // 截圖前檢查畫面文字；full = 整頁
  async function shot(page, name, full = true) {
    await page.waitForFunction(() => !document.querySelector('.toast'), null, { timeout: 8000 }).catch(() => {});   // 等提示訊息消失再截圖
    const text = await page.evaluate(() => document.body.innerText);
    for (const re of BAD) { const m = text.match(re); if (m) errors.push(`${name}: 畫面出現「${m[0]}」：…${text.slice(Math.max(0, m.index - 40), m.index + 40).replace(/\n/g, ' ')}…`); }
    await page.screenshot({ path: `${OUT}/${name}.png`, fullPage: full });
    return text;
  }
  const need = (cond, msg) => { if (!cond) errors.push(msg); };
  // 單頁應用換頁不會重新載入，也不會觸發新的載入事件：換頁時等指定的 API 回應回來，再等「只有目標頁才有」的元素；
  // 並確認畫面上沒有「載入中」，避免截到上一頁殘留或資料還沒回來的畫面
  async function go(page, hash, ready, apis = []) {
    const waits = apis.map(a => page.waitForResponse(r => r.url().includes('/api/v1' + a) && r.status() === 200, { timeout: 20000 }));
    await page.goto(BASE + '/#' + hash);
    await Promise.all(waits);
    await page.waitForSelector(ready, { timeout: 20000 });
    await page.waitForFunction(() => !/載入中…|計算中…/.test(document.body.innerText), null, { timeout: 20000 });
  }
  await session('student002@example.edu', async (page) => {
    await go(page, '/assistant', '.suggest button', ['/assistant/status']);
    await shot(page, '01-assistant-empty', false);
    await page.click('.suggest button:has-text("我想參加比賽，幫我規劃")');
    await page.waitForSelector('.confirm', { timeout: 60000 });
    await page.waitForFunction(() => !document.querySelector('.spin'), null, { timeout: 60000 });
    await page.waitForTimeout(600);
    const plan = await shot(page, '02-assistant-plan');
    need(/報名截止 20\d\d-\d\d-\d\d（剩 \d+ 天）/.test(plan), '助理的競賽卡片應顯示 ISO 日期與剩餘天數');
    need(/執行軌跡|能力盤點/.test(plan) && /待你確認|確認/.test(plan), '助理頁應顯示執行軌跡與待確認動作');
    await page.click('.confirm button:has-text("確認")');
    await page.waitForSelector('.confirm.done', { timeout: 15000 });
    await page.waitForTimeout(400);
    await page.locator('.confirm').scrollIntoViewIfNeeded();
    await shot(page, '03-assistant-confirmed', false);
    await go(page, '/competitions', 'text=競賽 Agent 依你的', ['/agents/competitions']);
    const comps = await shot(page, '04-competitions');
    need(/可報名 \d+ 筆/.test(comps) && /全部競賽 28/.test(comps) && (await page.locator('.item-row').count()) >= 3, '競賽頁應列出推薦與全部 28 筆競賽');
    await page.click('.segment button:has-text("全部競賽")'); await page.waitForTimeout(300);
    await shot(page, '05-competitions-all', false);
    await go(page, '/profile', 'text=Skill Profile', ['/me']);
    await page.locator('a:has-text("筆：")').first().click(); await page.waitForTimeout(200);
    const profile = await shot(page, '06-profile');
    need(/已驗證|修課成績|自述/.test(profile) && /初階|中階|進階/.test(profile), '個人頁應顯示三階等級與可信狀態');
    await go(page, '/growth', 'canvas', ['/me/growth/graph']); await page.waitForTimeout(2500);
    await shot(page, '07-growth');
    await go(page, '/users/7', '.stat-grid', ['/users/7']);
    const pub = await shot(page, '08-public-profile', false);
    need(!/\d+ 分/.test(pub.split('技能')[1] || ''), '公開檔案不應顯示技能分數');
    await go(page, '/', 'text=推薦給我的案件', ['/me/recommended-cases', '/cases?member=true']);
    const home = await shot(page, '09-home', false);
    need(/【組隊】/.test(home), '首頁「我的案件」應列出剛建立的組隊案件');
    await go(page, '/cases', 'input[placeholder*="搜尋"]', ['/cases?']); await shot(page, '10-cases', false);
  });
  await session('student005@example.edu', async (page) => {
    await go(page, '/competitions', 'text=競賽 Agent 依你的', ['/agents/competitions']);
    await Promise.all([page.waitForResponse(r => /\/api\/v1\/competitions\/\d+$/.test(r.url())), page.locator('.item-row a').first().click()]);
    await page.waitForSelector('button:has-text("找隊友")');
    await page.click('button:has-text("找隊友")'); await page.waitForSelector('.item-row input[type=checkbox]', { timeout: 15000 });
    await page.click('button:has-text("找老師")'); await page.waitForSelector('.item-row input[type=radio]', { timeout: 15000 });
    await page.locator('button:has-text("起草")').click(); await page.waitForSelector('.confirm', { timeout: 15000 });
    await page.waitForTimeout(300);
    await shot(page, '11-competition-detail');
    await go(page, '/cases/new', 'select'); await shot(page, '12-case-form', false);
  });
  await session('admin@example.edu', async (page) => {
    await go(page, '/admin', 'text=教師下架', ['/admin/assistant/metrics']); await page.waitForTimeout(2500);
    // 教師下架：搜尋 → 下架 → 恢復
    await page.fill('input[placeholder="輸入教師姓名或系所"]', '資訊工程');
    await page.press('input[placeholder="輸入教師姓名或系所"]', 'Enter'); await page.waitForSelector('button:has-text("下架")');
    await page.locator('button:has-text("下架")').first().click(); await page.waitForSelector('.pill:has-text("已下架")');
    await page.locator('button:has-text("恢復")').first().click(); await page.waitForFunction(() => !document.body.innerText.includes('已下架'));
    await shot(page, '13-admin');
  });
  await session('student002@example.edu', async (page) => {
    await go(page, '/assistant', '.sess', ['/assistant/sessions']);
    await page.locator('.sess').first().click(); await page.waitForSelector('.answer'); await page.waitForTimeout(500);
    await shot(page, '14-assistant-mobile');
  }, { width: 390, height: 844 });
  await browser.close();
  if (errors.length) { console.log('ERRORS:\n' + errors.join('\n')); process.exit(1); }
  console.log(`ui smoke ok：14 張截圖 → ${OUT}，沒有 console／頁面／API 錯誤，畫面文字檢查通過`);
})().catch(e => { console.error(e); process.exit(1); });
