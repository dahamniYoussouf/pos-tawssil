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
const categories = categoriesReport.items.filter((item) => item.id > 0);
const categoryById = new Map(categories.map((item) => [item.id, item]));

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

function expectedDepth(category) {
  let depth = 0;
  let current = category;
  while (current && current.parentId) {
    depth += 1;
    current = categoryById.get(current.parentId);
  }
  return depth;
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

  const menuItems = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#menu-to-edit > li.menu-item')).map((row, index) => {
      const depthMatch = row.className.match(/menu-item-depth-(\d+)/);
      return {
        dbId: Number((row.id.match(/^menu-item-(\d+)$/) || [])[1] || '0'),
        index,
        depth: depthMatch ? Number(depthMatch[1]) : 0,
        objectId: Number(row.querySelector('.menu-item-data-object-id')?.getAttribute('value') || '0'),
        parentMenuItemId: Number(
          row.querySelector('.menu-item-data-parent-id')?.getAttribute('value') || '0'
        ),
        itemType: row.querySelector('.menu-item-data-type')?.getAttribute('value') || '',
        object: row.querySelector('.menu-item-data-object')?.getAttribute('value') || '',
        title: row.querySelector('.item-title')?.textContent?.trim() || '',
      };
    })
  );

  const productMenuItems = menuItems.filter(
    (item) => item.itemType === 'taxonomy' && item.object === 'product_cat'
  );
  const menuByObjectId = new Map(productMenuItems.map((item) => [item.objectId, item]));

  const mismatches = [];
  for (const category of categories) {
    const menuItem = menuByObjectId.get(category.id);
    if (!menuItem) continue;

    const expectedParentMenuId =
      category.parentId && menuByObjectId.has(category.parentId)
        ? menuByObjectId.get(category.parentId).dbId
        : 0;
    const expectedMenuDepth = expectedDepth(category);

    if (
      menuItem.parentMenuItemId !== expectedParentMenuId ||
      menuItem.depth !== expectedMenuDepth
    ) {
      mismatches.push({
        id: category.id,
        name: category.name,
        expectedParentMenuId,
        actualParentMenuId: menuItem.parentMenuItemId,
        expectedDepth: expectedMenuDepth,
        actualDepth: menuItem.depth,
        title: menuItem.title,
      });
    }
  }

  console.log(JSON.stringify({
    totalCategories: categories.length,
    totalProductMenuItems: productMenuItems.length,
    mismatches,
  }, null, 2));

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
