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
  await page.waitForLoadState('networkidle');

  if (page.url().includes('wp-login.php')) {
    const error = await page.locator('#login_error, .message').allTextContents().catch(() => []);
    throw new Error(`Login failed: ${error.join(' | ')}`.trim());
  }
}

async function extractPage(page, pageNumber) {
  const url =
    `${baseUrl}/wp-admin/nav-menus.php?action=edit` +
    `&menu=${encodeURIComponent(menuId)}` +
    `&product_cat-tab=all` +
    `&paged=${encodeURIComponent(pageNumber)}` +
    `&item-type=taxonomy` +
    `&item-object=product_cat`;

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('#product_catchecklist', { state: 'attached' });

  return page.evaluate(() => {
    function walkList(list, level, parentId, output) {
      const items = Array.from(list.children).filter((item) => item.matches('li'));

      for (const item of items) {
        const checkbox = item.querySelector(':scope > label input.menu-item-checkbox');
        if (!checkbox) continue;

        const label = item.querySelector(':scope > label');
        const name = label ? label.textContent.trim().replace(/\s+/g, ' ') : '';
        const id = Number(checkbox.value || 0);

        output.push({ id, name, level, parentId });

        const childList = item.querySelector(':scope > ul.children');
        if (childList) {
          walkList(childList, level + 1, id, output);
        }
      }
    }

    const output = [];
    const rootList = document.querySelector('#product_catchecklist');
    walkList(rootList, 0, 0, output);

    const pages = Array.from(document.querySelectorAll('.add-menu-item-pagelinks .page-numbers'))
      .map((node) => {
        const text = node.textContent.replace(/\s+/g, ' ').trim();
        const numeric = Number(text.replace(/\D+/g, ''));
        return Number.isFinite(numeric) && numeric > 0 ? numeric : null;
      })
      .filter(Boolean);

    return {
      items: output,
      totalPages: pages.length ? Math.max(...pages) : 1,
    };
  });
}

async function main() {
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  await login(page);

  const page1 = await extractPage(page, 1);
  const allItems = [...page1.items];

  for (let pageNumber = 2; pageNumber <= page1.totalPages; pageNumber += 1) {
    const nextPage = await extractPage(page, pageNumber);
    allItems.push(...nextPage.items);
  }

  const uniqueItems = [];
  const seen = new Set();
  for (const item of allItems) {
    if (seen.has(item.id)) continue;
    seen.add(item.id);
    uniqueItems.push(item);
  }

  const report = {
    totalPages: page1.totalPages,
    totalItems: uniqueItems.length,
    items: uniqueItems,
  };

  fs.writeFileSync(
    path.join(outDir, 'product-cat-all-pages.json'),
    JSON.stringify(report, null, 2),
    'utf8'
  );
  console.log(JSON.stringify({ totalPages: report.totalPages, totalItems: report.totalItems }, null, 2));

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
