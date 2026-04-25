import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { chromium } from 'playwright-core';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendDir = path.resolve(__dirname, '..', '..');
const outDir = path.join(__dirname, 'out');

const DEFAULT_BROWSER_PATHS = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
];

function toBoolean(value, defaultValue = false) {
  if (value === undefined || value === null || value === '') return defaultValue;
  return ['1', 'true', 'yes', 'on'].includes(String(value).trim().toLowerCase());
}

export function loadWordPressSyncEnv() {
  const envFiles = [
    path.join(backendDir, '.env'),
    path.join(backendDir, '.env.wp-menu-sync.local'),
  ];

  const explicitEnvFile = process.env.WP_MENU_SYNC_ENV_FILE;
  if (explicitEnvFile) {
    envFiles.push(path.isAbsolute(explicitEnvFile) ? explicitEnvFile : path.join(backendDir, explicitEnvFile));
  }

  for (const envFile of envFiles) {
    if (fs.existsSync(envFile)) {
      dotenv.config({ path: envFile, override: false });
    }
  }
}

export function resolveSyncConfig() {
  loadWordPressSyncEnv();

  const baseUrl = process.env.WP_BASE_URL?.trim();
  const username = process.env.WP_ADMIN_USER?.trim() || process.env.WP_USER?.trim();
  const password = process.env.WP_ADMIN_PASS || process.env.WP_PASS;
  const menuId = process.env.WP_MENU_ID?.trim() || '';
  const menuName = process.env.WP_MENU_NAME?.trim() || 'Catégories Desktop';
  const headless = toBoolean(process.env.WP_HEADLESS, true);
  const browserPath = resolveBrowserPath();

  if (!baseUrl) {
    throw new Error('Missing WP_BASE_URL.');
  }
  if (!username) {
    throw new Error('Missing WP_ADMIN_USER.');
  }
  if (!password) {
    throw new Error('Missing WP_ADMIN_PASS.');
  }
  if (!browserPath) {
    throw new Error('Could not resolve a browser executable. Set WP_BROWSER_PATH.');
  }

  return {
    baseUrl: baseUrl.replace(/\/+$/, ''),
    username,
    password,
    menuId,
    menuName,
    headless,
    browserPath,
    outDir,
  };
}

export function resolveBrowserPath() {
  const preferred = process.env.WP_BROWSER_PATH;
  if (preferred && fs.existsSync(preferred)) {
    return preferred;
  }

  for (const candidate of DEFAULT_BROWSER_PATHS) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return '';
}

export async function launchWordPressBrowser(config) {
  fs.mkdirSync(config.outDir, { recursive: true });

  const browser = await chromium.launch({
    executablePath: config.browserPath,
    headless: config.headless,
  });

  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  return { browser, context, page };
}

export async function loginToWordPress(page, config) {
  await page.goto(`${config.baseUrl}/wp-login.php`, { waitUntil: 'domcontentloaded' });
  await page.fill('#user_login', config.username);
  await page.fill('#user_pass', config.password);
  await page.click('#wp-submit');
  await page
    .waitForFunction(
      () => window.location.href.indexOf('wp-login.php') === -1 || !!document.querySelector('#wpadminbar'),
      null,
      { timeout: 30000 }
    )
    .catch(() => null);
  await page.waitForTimeout(1500);

  if (page.url().includes('wp-login.php') && !(await page.locator('#wpadminbar').count())) {
    const error = await page.locator('#login_error, .message').allTextContents().catch(() => []);
    throw new Error(`WordPress login failed: ${error.join(' | ')}`.trim());
  }
}

export async function fetchAllProductCategories(page, config) {
  const allCategories = [];
  let pageNumber = 1;
  let totalPages = 1;

  while (pageNumber <= totalPages) {
    const url =
      `${config.baseUrl}/wp-admin/edit-tags.php?taxonomy=product_cat&post_type=product` +
      `&paged=${encodeURIComponent(pageNumber)}`;

    await page.goto(url, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle');
    await page.waitForSelector('#the-list tr', { state: 'attached' });

    const result = await page.evaluate((currentPageNumber) => {
      const rows = Array.from(document.querySelectorAll('#the-list tr'));
      const items = rows
        .map((row, index) => {
          const checkbox = row.querySelector('input[name="delete_tags[]"]');
          const id = Number(checkbox?.value || 0);
          if (!id) return null;

          const levelMatch = row.className.match(/level-(\d+)/);
          const inlineRow = document.querySelector(`#inline_${id}`);
          const name =
            inlineRow?.querySelector('.name')?.textContent?.trim() ||
            row.querySelector('.row-title')?.textContent?.trim() ||
            '';
          const slug = inlineRow?.querySelector('.slug')?.textContent?.trim() || '';
          const parentId = Number(inlineRow?.querySelector('.parent')?.textContent?.trim() || '0');

          return {
            id,
            name,
            slug,
            parentId,
            level: levelMatch ? Number(levelMatch[1]) : 0,
            sourceIndex: (currentPageNumber - 1) * rows.length + index,
          };
        })
        .filter(Boolean);

      const totalPagesText =
        document.querySelector('.tablenav-pages .total-pages')?.textContent?.trim() || '1';

      return {
        items,
        totalPages: Number(totalPagesText) || 1,
      };
    }, pageNumber);

    allCategories.push(...result.items);
    totalPages = result.totalPages;
    pageNumber += 1;
  }

  return allCategories.filter((item) => item.id > 0);
}

export async function resolveMenuId(page, config) {
  if (config.menuId) {
    return config.menuId;
  }

  await page.goto(`${config.baseUrl}/wp-admin/nav-menus.php`, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('select[name="menu"], #menu', { state: 'attached' });

  const menuId = await page.evaluate((menuName) => {
    const options = Array.from(document.querySelectorAll('select[name="menu"] option, #menu option'));
    const target = options.find(
      (option) => (option.textContent || '').trim().toLowerCase() === menuName.toLowerCase()
    );
    return target?.value || '';
  }, config.menuName);

  if (!menuId) {
    throw new Error(`Could not resolve menu "${config.menuName}".`);
  }

  return menuId;
}

export async function gotoMenuEditor(page, config, menuId) {
  await page.goto(
    `${config.baseUrl}/wp-admin/nav-menus.php?action=edit&menu=${encodeURIComponent(menuId)}`,
    { waitUntil: 'domcontentloaded' }
  );
  await page.waitForSelector('#menu-to-edit', { state: 'attached', timeout: 60000 });
}

export async function fetchMenuItems(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#menu-to-edit > li.menu-item')).map((row, index) => {
      const depthMatch = row.className.match(/menu-item-depth-(\d+)/);

      return {
        dbId: Number((row.id.match(/^menu-item-(\d+)$/) || [])[1] || '0'),
        index,
        depth: depthMatch ? Number(depthMatch[1]) : 0,
        position: Number(
          row.querySelector('.menu-item-data-position')?.getAttribute('value') || String(index + 1)
        ),
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
}

export function indexCategories(categories) {
  return new Map(categories.map((category) => [category.id, category]));
}

export function buildCategoryUrl(categoryId, categoryById, baseUrl) {
  const segments = [];
  let current = categoryById.get(categoryId);

  while (current) {
    segments.unshift(current.slug);
    current = current.parentId ? categoryById.get(current.parentId) : null;
  }

  return `${baseUrl}/categorie/${segments.join('/')}/`;
}

export function groupProductMenuItems(menuItems) {
  const productMenuItems = menuItems.filter(
    (item) => item.itemType === 'taxonomy' && item.object === 'product_cat' && item.objectId > 0
  );

  const byObjectId = new Map();
  for (const item of productMenuItems) {
    if (!byObjectId.has(item.objectId)) {
      byObjectId.set(item.objectId, []);
    }
    byObjectId.get(item.objectId).push(item);
  }

  for (const items of byObjectId.values()) {
    items.sort((left, right) => left.index - right.index);
  }

  return { productMenuItems, byObjectId };
}

export function selectPrimaryMenuItems(categories, groupedMenuItems) {
  const primaryByCategoryId = new Map();

  for (const category of [...categories].sort((left, right) => left.sourceIndex - right.sourceIndex)) {
    const candidates = groupedMenuItems.byObjectId.get(category.id) || [];
    if (!candidates.length) {
      primaryByCategoryId.set(category.id, null);
      continue;
    }

    let primary = null;
    if (category.parentId === 0) {
      primary = candidates.find((candidate) => candidate.parentMenuItemId === 0) || candidates[0];
    } else {
      const parentPrimary = primaryByCategoryId.get(category.parentId);
      primary =
        candidates.find((candidate) => parentPrimary && candidate.parentMenuItemId === parentPrimary.dbId) ||
        candidates[0];
    }

    primaryByCategoryId.set(category.id, primary);
  }

  return primaryByCategoryId;
}

export function buildHierarchyMismatches(categories, primaryByCategoryId) {
  const mismatches = [];

  for (const category of categories) {
    const primary = primaryByCategoryId.get(category.id);
    if (!primary) continue;

    const parentPrimary = category.parentId ? primaryByCategoryId.get(category.parentId) : null;
    const expectedParentMenuId = parentPrimary?.dbId || 0;
    const expectedDepth = category.level;

    if (primary.parentMenuItemId !== expectedParentMenuId || primary.depth !== expectedDepth) {
      mismatches.push({
        id: category.id,
        name: category.name,
        level: category.level,
        primaryDbId: primary.dbId,
        expectedParentMenuId,
        actualParentMenuId: primary.parentMenuItemId,
        expectedDepth,
        actualDepth: primary.depth,
      });
    }
  }

  return mismatches;
}

export function buildDuplicateSummary(groupedMenuItems) {
  return Array.from(groupedMenuItems.byObjectId.entries())
    .filter(([, items]) => items.length > 1)
    .map(([objectId, items]) => ({ objectId, items }));
}

export async function injectMissingCategories(page, categoriesToAdd, categoryById, config) {
  const entries = categoriesToAdd.map((category, index) => ({
    id: category.id,
    name: category.name,
    url: buildCategoryUrl(category.id, categoryById, config.baseUrl),
    syntheticKey: String(-100000 - index),
  }));

  const injectedIds = await page.evaluate((items) => {
    const list = document.querySelector('#product_catchecklist');
    if (!list) return [];

    for (const input of Array.from(list.querySelectorAll('input.menu-item-checkbox'))) {
      input.checked = false;
    }

    for (const tempNode of Array.from(list.querySelectorAll('[data-codex-temp="1"]'))) {
      tempNode.remove();
    }

    const createdIds = [];
    for (const item of items) {
      const li = document.createElement('li');
      li.setAttribute('data-codex-temp', '1');

      const label = document.createElement('label');
      label.className = 'menu-item-title';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.className = 'menu-item-checkbox';
      checkbox.name = `menu-item[${item.syntheticKey}][menu-item-object-id]`;
      checkbox.value = String(item.id);
      checkbox.checked = true;

      label.appendChild(checkbox);
      label.appendChild(document.createTextNode(` ${item.name}`));
      li.appendChild(label);

      const hiddenFields = [
        ['menu-item-db-id', '0', 'menu-item-db-id'],
        ['menu-item-object', 'product_cat', 'menu-item-object'],
        ['menu-item-parent-id', '0', 'menu-item-parent-id'],
        ['menu-item-type', 'taxonomy', 'menu-item-type'],
        ['menu-item-title', item.name, 'menu-item-title'],
        ['menu-item-url', item.url, 'menu-item-url'],
        ['menu-item-target', '', 'menu-item-target'],
        ['menu-item-attr-title', '', 'menu-item-attr-title'],
        ['menu-item-classes', '', 'menu-item-classes'],
        ['menu-item-xfn', '', 'menu-item-xfn'],
      ];

      for (const [fieldName, fieldValue, className] of hiddenFields) {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.className = className;
        input.name = `menu-item[${item.syntheticKey}][${fieldName}]`;
        input.value = fieldValue;
        li.appendChild(input);
      }

      list.appendChild(li);
      createdIds.push(item.id);
    }

    return createdIds;
  }, entries);

  if (injectedIds.length !== categoriesToAdd.length) {
    throw new Error(`Injected ${injectedIds.length} of ${categoriesToAdd.length} missing categories.`);
  }

  await page.locator('#submit-taxonomy-product_cat').evaluate((button) => button.click());
  await page.waitForFunction(
    (targetIds) =>
      targetIds.every((id) =>
        Array.from(document.querySelectorAll('#menu-to-edit .menu-item-data-object-id')).some(
          (input) => Number(input.getAttribute('value') || '0') === id
        )
      ),
    injectedIds,
    { timeout: 60000 }
  );

  return injectedIds;
}

export async function applyHierarchyUpdates(page, mismatches) {
  return page.evaluate((items) => {
    const updated = [];

    for (const item of items) {
      const row = document.querySelector(`#menu-item-${item.primaryDbId}`);
      if (!row) continue;

      const parentInput = row.querySelector('.menu-item-data-parent-id');
      if (parentInput) {
        parentInput.value = String(item.expectedParentMenuId);
      }

      row.className = row.className.replace(/menu-item-depth-\d+/, `menu-item-depth-${item.expectedDepth}`);
      updated.push(item.id);
    }

    return updated;
  }, mismatches);
}

export async function saveMenu(page) {
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 60000 }),
    page.locator('#save_menu_footer').click(),
  ]);
  await page.waitForSelector('#menu-to-edit', { state: 'attached', timeout: 60000 });
}

export function writeReport(reportName, payload) {
  fs.mkdirSync(outDir, { recursive: true });
  const reportPath = path.join(outDir, reportName);
  fs.writeFileSync(reportPath, JSON.stringify(payload, null, 2), 'utf8');
  return reportPath;
}
