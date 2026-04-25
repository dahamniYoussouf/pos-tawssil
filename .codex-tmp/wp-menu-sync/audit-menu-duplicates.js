const { chromium } = require('playwright-core');

const baseUrl = process.env.WP_BASE_URL || 'https://gamaoutillage.net';
const username = process.env.WP_USER;
const password = process.env.WP_PASS;
const menuId = process.env.WP_MENU_ID || '529';
const browserPath =
  process.env.BROWSER_PATH ||
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

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

  const productMenuItems = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#menu-to-edit > li.menu-item'))
      .map((row, index) => ({
        dbId: Number((row.id.match(/^menu-item-(\d+)$/) || [])[1] || '0'),
        index,
        objectId: Number(row.querySelector('.menu-item-data-object-id')?.getAttribute('value') || '0'),
        parentMenuItemId: Number(
          row.querySelector('.menu-item-data-parent-id')?.getAttribute('value') || '0'
        ),
        itemType: row.querySelector('.menu-item-data-type')?.getAttribute('value') || '',
        object: row.querySelector('.menu-item-data-object')?.getAttribute('value') || '',
        title: row.querySelector('.item-title')?.textContent?.trim() || '',
      }))
      .filter((item) => item.itemType === 'taxonomy' && item.object === 'product_cat')
  );

  const grouped = new Map();
  for (const item of productMenuItems) {
    if (!grouped.has(item.objectId)) grouped.set(item.objectId, []);
    grouped.get(item.objectId).push(item);
  }

  const duplicates = Array.from(grouped.entries())
    .filter(([, items]) => items.length > 1)
    .map(([objectId, items]) => ({ objectId, items }));

  console.log(JSON.stringify({ duplicates }, null, 2));

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
