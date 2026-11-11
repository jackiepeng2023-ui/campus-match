const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const errors = [];
  page.on('pageerror', e => errors.push('pageerror: ' + e.message));
  page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
  const base = (process.env.BASE || 'http://127.0.0.1:8080') + '/#';
  async function login(account) {
    await page.goto(base + '/login'); await page.evaluate(() => localStorage.clear());
    await page.goto(base + '/login');
    await page.fill('input[placeholder="student001@example.edu"]', account);
    await page.fill('input[type=password]', 'demo1234');
    await page.click('form button.btn'); await page.waitForTimeout(1500);
  }
  await login('student001@example.edu');
  await page.screenshot({ path: 'shots/01-home.png', fullPage: true });
  await page.goto(base + '/cases'); await page.waitForTimeout(1000);
  await page.screenshot({ path: 'shots/02-cases.png', fullPage: true });
  // 找到自己發起的 OPEN 案件 → 詳情 → 推薦
  const ids = await page.evaluate(async () => { const r = await fetch('/api/v1/cases?mine=true', { headers: { Authorization: 'Bearer ' + localStorage.getItem('token') } }); return (await r.json()).filter(c => c.status === 'OPEN').map(c => c.id); });
  await page.goto(base + '/cases/' + ids[0]); await page.waitForTimeout(1000);
  const btn = page.locator('button:has-text("查看推薦人選")').first();
  if (await btn.count()) { await btn.click(); await page.waitForTimeout(1200); }
  await page.screenshot({ path: 'shots/03-case-detail.png', fullPage: true });
  await page.goto(base + '/cases/new'); await page.waitForTimeout(800);
  await page.screenshot({ path: 'shots/04-case-form.png', fullPage: true });
  await login('student007@example.edu');
  await page.goto(base + '/profile'); await page.waitForTimeout(1000);
  await page.screenshot({ path: 'shots/05-profile.png', fullPage: true });
  await page.goto(base + '/growth'); await page.waitForTimeout(1000);
  await page.fill("input[placeholder*=\"前端工程師\"]", "成為前端工程師");
  await page.fill("input[placeholder*=\"該補什麼\"]", "下學期該補什麼？");
  await page.click('button:has-text("產生 Prompt")'); await page.waitForTimeout(800);
  await page.screenshot({ path: 'shots/06-growth.png', fullPage: true });
  await login('admin@example.edu');
  await page.goto(base + '/admin'); await page.waitForTimeout(1500);
  await page.screenshot({ path: 'shots/07-admin.png', fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  await login('student005@example.edu');
  await page.screenshot({ path: 'shots/08-mobile-home.png', fullPage: true });
  console.log(errors.length ? errors.join('\n') : 'NO JS ERRORS');
  await browser.close();
})();
