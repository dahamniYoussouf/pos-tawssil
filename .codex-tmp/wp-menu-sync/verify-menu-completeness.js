const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const baseUrl = process.env.WP_BASE_URL || 'https://gamaoutillage.net';
const username = process.env.WP_USER;
const password = process.env.WP_PASS;
const menuId = process.env.WP_MENU_ID || '529';
const browserPath =
  process.env.BROWSER_PATH ||
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const outDir = path.join(__dirname, 'out');

const categoriesReport = JSON.parse(
  fs.readFileSync(path.join(outDir, 'product-category-pages.json'), 'utf8')
);

async function login(page) {
  await page.goto(`${baseUrl}/wp-login.php`, { waitUntil: 'domcontentloaded' });
  await page.fill('#user_login', username);
  await page.fill('#user_pass', password);
  await page.click('#wp-submit');
  await page.waitForFunction(
    () => window.location.href.indexOf('wp-login.php') === -1 || !!document.querySelector('#wpadminbar'),
    null,
    { timeout: 30000 }
  ).catch(() => null);
  await page.waitForTimeout(1500);

  if (page.url().includes('wp-login.php') && !(await page.locator('#wpadminbar').count())) {
    throw new Error('Login failed.');
  }
}

async function main() {
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  await login(page);
  await page.goto(
    `${baseUrl}/wp-admin/nav-menus.php?action=edit&menu=${encodeURIComponent(menuId)}`,
    { waitUntil: 'domcontentloaded' }
  );
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('#menu-to-edit', { state: 'attached' });

  const menuObjectIds = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#menu-to-edit .menu-item-data-object-id'))
      .map((input) => Number(input.getAttribute('value') || '0'))
      .filter(Boolean)
  );

  const menuSet = new Set(menuObjectIds);
  const missing = categoriesReport.items.filter((item) => item.id > 0 && !menuSet.has(item.id));

  console.log(JSON.stringify({
    totalCategories: categoriesReport.items.filter((item) => item.id > 0).length,
    totalMenuObjectIds: menuSet.size,
    missing,
  }, null, 2));

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
