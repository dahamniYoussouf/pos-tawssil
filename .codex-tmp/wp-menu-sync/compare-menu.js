const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const baseUrl = process.env.WP_BASE_URL || 'https://gamaoutillage.net';
const username = process.env.WP_USER;
const password = process.env.WP_PASS;
const menuName = process.env.WP_MENU_NAME || 'Catégories Desktop';
const browserPath =
  process.env.BROWSER_PATH ||
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const outDir = path.join(__dirname, 'out');

if (!username || !password) {
  console.error('Missing WP_USER or WP_PASS.');
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

function buildPathMap(categoriesById) {
  const cache = new Map();

  const getPath = (id) => {
    if (cache.has(id)) return cache.get(id);
    const category = categoriesById.get(id);
    if (!category) return [];
    const pathParts = category.parentId ? [...getPath(category.parentId), category.name] : [category.name];
    cache.set(id, pathParts);
    return pathParts;
  };

  for (const id of categoriesById.keys()) {
    getPath(id);
  }

  return cache;
}

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
    const error = await page.locator('#login_error, .message').allTextContents().catch(() => []);
    throw new Error(`Login failed: ${error.join(' | ')}`.trim());
  }
}

async function extractCategories(page) {
  await page.goto(
    `${baseUrl}/wp-admin/edit-tags.php?taxonomy=product_cat&post_type=product`,
    { waitUntil: 'domcontentloaded' }
  );
  await page.waitForSelector('#the-list tr');

  return page.$$eval('#the-list tr', (rows) =>
    rows.map((row) => {
      const idMatch = row.id.match(/^tag-(\d+)$/);
      const levelMatch = row.className.match(/level-(\d+)/);
      const checkbox = row.querySelector('input[name="delete_tags[]"]');
      const rawName =
        row.querySelector('.row-title')?.textContent?.trim() ||
        row.querySelector('strong a')?.textContent?.trim() ||
        '';
      const cleanName = rawName.replace(/^[—-]\s*/, '').trim();
      const hiddenParent = row.querySelector(`#inline_${checkbox?.value} .parent`)?.textContent?.trim() || '0';
      const hiddenSlug = row.querySelector(`#inline_${checkbox?.value} .slug`)?.textContent?.trim() || '';

      return {
        id: idMatch ? Number(idMatch[1]) : Number(checkbox?.value || 0),
        name: cleanName,
        rawName,
        slug: hiddenSlug,
        level: levelMatch ? Number(levelMatch[1]) : 0,
        parentId: Number(hiddenParent || 0),
      };
    })
  );
}

async function extractMenu(page) {
  await page.goto(`${baseUrl}/wp-admin/nav-menus.php`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('select[name="menu"], #menu');

  const menuOptions = await page.$$eval('select[name="menu"] option, #menu option', (options) =>
    options
      .map((option) => ({
        value: option.value,
        label: option.textContent?.trim() || '',
        selected: option.selected,
      }))
      .filter((option) => option.value)
  );

  const targetMenu = menuOptions.find(
    (option) => option.label.toLowerCase() === menuName.toLowerCase()
  );

  if (!targetMenu) {
    throw new Error(`Menu not found: ${menuName}`);
  }

  await page.goto(
    `${baseUrl}/wp-admin/nav-menus.php?action=edit&menu=${encodeURIComponent(targetMenu.value)}`,
    { waitUntil: 'domcontentloaded' }
  );
  await page.waitForSelector('#menu-to-edit', { state: 'attached' });

  const items = await page.$$eval('#menu-to-edit > li.menu-item', (rows) =>
    rows.map((row) => {
      const dbIdMatch = row.id.match(/^menu-item-(\d+)$/);
      const depthMatch = row.className.match(/menu-item-depth-(\d+)/);
      const title =
        row.querySelector('.menu-item-bar .item-title')?.textContent?.trim() ||
        row.querySelector('.menu-item-title')?.textContent?.trim() ||
        '';
      const objectId = row.querySelector('.menu-item-data-object-id')?.getAttribute('value') || '';
      const parentMenuItemId =
        row.querySelector('.menu-item-data-parent-id')?.getAttribute('value') || '0';
      const itemType =
        row.querySelector('.menu-item-data-type')?.getAttribute('value') || '';
      const object =
        row.querySelector('.menu-item-data-object')?.getAttribute('value') || '';

      return {
        menuItemDbId: dbIdMatch ? Number(dbIdMatch[1]) : 0,
        depth: depthMatch ? Number(depthMatch[1]) : 0,
        title,
        objectId: Number(objectId || 0),
        parentMenuItemId: Number(parentMenuItemId || 0),
        itemType,
        object,
      };
    })
  );

  return { menuId: Number(targetMenu.value), menuLabel: targetMenu.label, items };
}

async function main() {
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });

  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  await login(page);

  const categories = await extractCategories(page);
  const menu = await extractMenu(page);

  const categoriesById = new Map(categories.map((category) => [category.id, category]));
  const pathMap = buildPathMap(categoriesById);
  const menuCategoryItems = menu.items.filter(
    (item) => item.itemType === 'taxonomy' && item.object === 'product_cat'
  );
  const menuByObjectId = new Map(menuCategoryItems.map((item) => [item.objectId, item]));

  const missingAll = categories
    .filter((category) => !menuByObjectId.has(category.id))
    .map((category) => {
      const pathParts = pathMap.get(category.id) || [category.name];
      const parentMenuItem =
        category.parentId && menuByObjectId.has(category.parentId)
          ? menuByObjectId.get(category.parentId)
          : null;

      return {
        id: category.id,
        name: category.name,
        slug: category.slug,
        level: category.level,
        parentId: category.parentId,
        path: pathParts.join(' > '),
        hasParentInMenu: Boolean(parentMenuItem),
        parentMenuItemDbId: parentMenuItem?.menuItemDbId || 0,
      };
    });

  const actionableMissing = missingAll.filter(
    (category) => category.parentId && menuByObjectId.has(category.parentId)
  );

  const report = {
    menu,
    counts: {
      productCategories: categories.length,
      menuProductCategoryItems: menuCategoryItems.length,
      missingCategories: missingAll.length,
      actionableMissing: actionableMissing.length,
    },
    missingAll,
    actionableMissing,
    menuCategoryItems,
    categories,
  };

  fs.writeFileSync(path.join(outDir, 'compare-report.json'), JSON.stringify(report, null, 2), 'utf8');
  console.log(JSON.stringify(report.counts, null, 2));
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
