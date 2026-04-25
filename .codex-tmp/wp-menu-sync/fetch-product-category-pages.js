const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

const baseUrl = process.env.WP_BASE_URL || 'https://gamaoutillage.net';
const username = process.env.WP_USER;
const password = process.env.WP_PASS;
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

async function extractPage(page, pageNumber) {
  const url =
    `${baseUrl}/wp-admin/edit-tags.php?taxonomy=product_cat&post_type=product` +
    `&paged=${encodeURIComponent(pageNumber)}`;

  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('#the-list tr', { state: 'attached' });

  return page.evaluate(() => {
    const rows = Array.from(document.querySelectorAll('#the-list tr'));
    const items = rows.map((row) => {
      const checkbox = row.querySelector('input[name="delete_tags[]"]');
      const id = Number(checkbox?.value || 0);
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
      };
    });

    const totalPagesText =
      document.querySelector('.tablenav-pages .total-pages')?.textContent?.trim() || '1';

    return {
      items,
      totalPages: Number(totalPagesText) || 1,
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

  const firstPage = await extractPage(page, 1);
  const allItems = [...firstPage.items];

  for (let pageNumber = 2; pageNumber <= firstPage.totalPages; pageNumber += 1) {
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
    totalPages: firstPage.totalPages,
    totalItems: uniqueItems.length,
    items: uniqueItems,
  };

  fs.writeFileSync(
    path.join(outDir, 'product-category-pages.json'),
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
