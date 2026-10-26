const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  page.on('pageerror', e => console.log('pageerror:', e.message));
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') console.log(m.type() + ':', m.text().slice(0, 300)); });
  const base = 'http://127.0.0.1:5173/#';
  await page.goto(base + '/login');
  await page.fill('input[placeholder="student001@example.edu"]', 'student007@example.edu');
  await page.fill('input[type=password]', 'demo1234');
  await page.click('button.btn'); await page.waitForTimeout(1500);
  await page.goto(base + '/growth'); await page.waitForTimeout(2000);
  console.log('url', page.url());
  await page.screenshot({ path: 'shots/06-growth.png', fullPage: true });
  await browser.close();
})();
