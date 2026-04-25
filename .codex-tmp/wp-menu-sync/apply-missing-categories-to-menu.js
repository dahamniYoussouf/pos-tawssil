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

const compareReport = JSON.parse(
  fs.readFileSync(path.join(outDir, 'full-compare-report.json'), 'utf8')
);
const categoriesReport = JSON.parse(
  fs.readFileSync(path.join(outDir, 'product-category-pages.json'), 'utf8')
);
const desiredItems = compareReport.actionableMissing.filter((item) => item.id > 0);
const categoryById = new Map(categoriesReport.items.map((item) => [item.id, item]));

if (!username || !password) {
  console.error('Missing WP_USER or WP_PASS.');
  process.exit(1);
}

fs.mkdirSync(outDir, { recursive: true });

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

async function gotoMenuPage(page, productCatPage = 1) {
  const url =
    `${baseUrl}/wp-admin/nav-menus.php?action=edit` +
    `&menu=${encodeURIComponent(menuId)}` +
    `&product_cat-tab=all` +
    `&paged=${encodeURIComponent(productCatPage)}` +
    `&item-type=taxonomy` +
    `&item-object=product_cat`;

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('#menu-to-edit', { state: 'attached' });
}

async function getMenuState(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#menu-to-edit > li.menu-item')).map((row) => {
      const objectId = Number(
        row.querySelector('.menu-item-data-object-id')?.getAttribute('value') || '0'
      );
      const parentMenuItemId = Number(
        row.querySelector('.menu-item-data-parent-id')?.getAttribute('value') || '0'
      );
      const itemType = row.querySelector('.menu-item-data-type')?.getAttribute('value') || '';
      const object = row.querySelector('.menu-item-data-object')?.getAttribute('value') || '';
      const dbId = Number((row.id.match(/^menu-item-(\d+)$/) || [])[1] || '0');

      return { dbId, objectId, parentMenuItemId, itemType, object };
    })
  );
}

async function clickAddToMenu(page) {
  await page.locator('#submit-taxonomy-product_cat').evaluate((button) => button.click());
}

function buildCategoryUrl(id) {
  const segments = [];
  let current = categoryById.get(id);

  while (current) {
    segments.unshift(current.slug);
    current = current.parentId ? categoryById.get(current.parentId) : null;
  }

  return `${baseUrl}/categorie/${segments.join('/')}/`;
}

async function injectSyntheticProductCatEntries(page, items) {
  return page.evaluate((entries) => {
    const list = document.querySelector('#product_catchecklist');
    if (!list) return [];

    for (const input of Array.from(list.querySelectorAll('input.menu-item-checkbox'))) {
      input.checked = false;
    }

    for (const tempNode of Array.from(list.querySelectorAll('[data-codex-temp="1"]'))) {
      tempNode.remove();
    }

    const createdIds = [];

    for (const entry of entries) {
      const li = document.createElement('li');
      li.setAttribute('data-codex-temp', '1');

      const label = document.createElement('label');
      label.className = 'menu-item-title';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.className = 'menu-item-checkbox';
      checkbox.name = `menu-item[${entry.syntheticKey}][menu-item-object-id]`;
      checkbox.value = String(entry.id);
      checkbox.checked = true;
      label.appendChild(checkbox);
      label.appendChild(document.createTextNode(` ${entry.name}`));
      li.appendChild(label);

      const hiddenFields = [
        ['menu-item-db-id', '0', 'menu-item-db-id'],
        ['menu-item-object', 'product_cat', 'menu-item-object'],
        ['menu-item-parent-id', '0', 'menu-item-parent-id'],
        ['menu-item-type', 'taxonomy', 'menu-item-type'],
        ['menu-item-title', entry.name, 'menu-item-title'],
        ['menu-item-url', entry.url, 'menu-item-url'],
        ['menu-item-target', '', 'menu-item-target'],
        ['menu-item-attr-title', '', 'menu-item-attr-title'],
        ['menu-item-classes', '', 'menu-item-classes'],
        ['menu-item-xfn', '', 'menu-item-xfn'],
      ];

      for (const [fieldName, fieldValue, className] of hiddenFields) {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.className = className;
        input.name = `menu-item[${entry.syntheticKey}][${fieldName}]`;
        input.value = fieldValue;
        li.appendChild(input);
      }

      list.appendChild(li);
      createdIds.push(entry.id);
    }

    return createdIds;
  }, items);
}

async function setParents(page, targetItems) {
  return page.evaluate((items) => {
    const updated = [];

    for (const item of items) {
      const objectIdInput = Array.from(
        document.querySelectorAll('#menu-to-edit .menu-item-data-object-id')
      ).find((input) => Number(input.getAttribute('value') || '0') === item.id);

      if (!objectIdInput) continue;

      const row = objectIdInput.closest('li.menu-item');
      const parentInput = row.querySelector('.menu-item-data-parent-id');
      if (parentInput) {
        parentInput.value = String(item.parentMenuItemDbId);
        updated.push(item.id);
      }

      row.className = row.className.replace(/menu-item-depth-\d+/, 'menu-item-depth-1');
    }

    return updated;
  }, targetItems);
}

async function saveMenu(page) {
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 60000 }),
    page.locator('#save_menu_footer').click(),
  ]);

  await page.waitForLoadState('networkidle');
}

async function main() {
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  await login(page);
  await gotoMenuPage(page, 1);

  const initialMenuState = await getMenuState(page);
  const initialProductCatItems = initialMenuState.filter(
    (item) => item.itemType === 'taxonomy' && item.object === 'product_cat'
  );
  const existingIds = new Set(initialProductCatItems.map((item) => item.objectId));
  const pending = desiredItems.filter((item) => !existingIds.has(item.id));

  const pendingWithUrls = pending.map((item, index) => ({
    ...item,
    syntheticKey: String(-100000 - index),
    url: buildCategoryUrl(item.id),
  }));

  const addedIds = [];

  if (pendingWithUrls.length) {
    const injectedIds = await injectSyntheticProductCatEntries(page, pendingWithUrls);
    if (injectedIds.length !== pendingWithUrls.length) {
      throw new Error(`Failed to inject all missing categories into the product category metabox. Injected ${injectedIds.length} of ${pendingWithUrls.length}.`);
    }

    await clickAddToMenu(page);

    const pendingIds = pendingWithUrls.map((item) => item.id);
    await page.waitForFunction(
      (targetIds) =>
        targetIds.every((id) =>
          Array.from(document.querySelectorAll('#menu-to-edit .menu-item-data-object-id')).some(
            (input) => Number(input.getAttribute('value') || '0') === id
          )
        ),
      pendingIds,
      { timeout: 60000 }
    );

    addedIds.push(...pendingIds);
  }

  const updatedParents = await setParents(page, desiredItems);

  if (updatedParents.length !== desiredItems.length) {
    throw new Error(`Parent assignment incomplete. Updated ${updatedParents.length} of ${desiredItems.length}.`);
  }

  await saveMenu(page);

  const finalMenuState = await getMenuState(page);
  const finalMenuByObjectId = new Map(
    finalMenuState
      .filter((item) => item.itemType === 'taxonomy' && item.object === 'product_cat')
      .map((item) => [item.objectId, item])
  );

  const verification = desiredItems.map((item) => ({
    id: item.id,
    expectedParentMenuItemDbId: item.parentMenuItemDbId,
    actualParentMenuItemDbId: finalMenuByObjectId.get(item.id)?.parentMenuItemId || 0,
    exists: finalMenuByObjectId.has(item.id),
  }));

  const failedVerification = verification.filter(
    (item) => !item.exists || item.actualParentMenuItemDbId !== item.expectedParentMenuItemDbId
  );

  await page.screenshot({ path: path.join(outDir, 'menu-after-save.png'), fullPage: true });

  const report = {
    menuId: Number(menuId),
    addedIds,
    verification,
    failedVerification,
    finalCount: finalMenuByObjectId.size,
  };

  fs.writeFileSync(path.join(outDir, 'apply-report.json'), JSON.stringify(report, null, 2), 'utf8');
  console.log(JSON.stringify(report, null, 2));

  if (failedVerification.length) {
    throw new Error(`Verification failed for: ${failedVerification.map((item) => item.id).join(', ')}`);
  }

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
