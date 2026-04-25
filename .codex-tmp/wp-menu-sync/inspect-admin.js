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

async function saveArtifact(page, name) {
  const htmlPath = path.join(outDir, `${name}.html`);
  const pngPath = path.join(outDir, `${name}.png`);
  fs.writeFileSync(htmlPath, await page.content(), 'utf8');
  await page.screenshot({ path: pngPath, fullPage: true });
}

async function main() {
  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });

  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();

  await page.goto(`${baseUrl}/wp-login.php`, { waitUntil: 'domcontentloaded' });
  await page.fill('#user_login', username);
  await page.fill('#user_pass', password);
  await page.click('#wp-submit');
  await page.waitForLoadState('networkidle');

  if (page.url().includes('wp-login.php')) {
    await saveArtifact(page, 'login-failed');
    const error = await page.locator('#login_error, .message').allTextContents().catch(() => []);
    throw new Error(`Login failed at ${page.url()} ${error.join(' | ')}`.trim());
  }

  await saveArtifact(page, 'dashboard');

  await page.goto(
    `${baseUrl}/wp-admin/edit-tags.php?taxonomy=product_cat&post_type=product`,
    { waitUntil: 'domcontentloaded' }
  );
  await page.waitForLoadState('networkidle');
  await saveArtifact(page, 'product-categories');

  const categoryRows = await page.$$eval('#the-list tr', (rows) =>
    rows.map((row) => ({
      id: row.id || '',
      classes: row.className || '',
      name:
        row.querySelector('.row-title')?.textContent?.trim() ||
        row.querySelector('strong a')?.textContent?.trim() ||
        '',
    }))
  );

  await page.goto(`${baseUrl}/wp-admin/nav-menus.php`, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle');
  await saveArtifact(page, 'nav-menus');

  const menuOptions = await page.$$eval(
    'select[name="menu"] option, #menu option',
    (options) =>
      options
        .map((option) => ({
          value: option.value,
          label: option.textContent?.trim() || '',
          selected: option.selected,
        }))
        .filter((option) => option.value)
  );

  const menuName = process.env.WP_MENU_NAME || 'Categories Desktop';
  const targetMenu = menuOptions.find(
    (option) => option.label.toLowerCase() === menuName.toLowerCase()
  );

  if (targetMenu) {
    await page.goto(
      `${baseUrl}/wp-admin/nav-menus.php?action=edit&menu=${encodeURIComponent(targetMenu.value)}`,
      { waitUntil: 'domcontentloaded' }
    );
    await page.waitForLoadState('networkidle');
    await saveArtifact(page, 'menu-edit');
  }

  const report = {
    loginUrl: page.url(),
    categories: categoryRows.slice(0, 30),
    menuOptions,
    targetMenu,
  };

  fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2), 'utf8');
  console.log(JSON.stringify(report, null, 2));

  await browser.close();
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
