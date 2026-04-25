import {
  launchWordPressBrowser,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const CF_EMAIL = process.env.CF_EMAIL || '';
const CF_PASS = process.env.CF_PASS || '';
const CF_ZONE = process.env.CF_ZONE || 'gamaoutillage.net';

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1000);
}

async function login(page) {
  await goto(page, 'https://dash.cloudflare.com/login');
  await page.fill('input[type="email"]', CF_EMAIL);
  await page.fill('input[type="password"]', CF_PASS);
  await page.click('button[type="submit"]');
  await page.waitForTimeout(2000);

  const hasCaptcha = await page
    .locator('iframe[src*="captcha"], iframe[src*="hcaptcha"], iframe[src*="turnstile"]')
    .count()
    .catch(() => 0);

  if (hasCaptcha > 0) {
    throw new Error('Cloudflare login blocked by CAPTCHA/Turnstile.');
  }

  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
}

async function openZone(page) {
  await goto(page, 'https://dash.cloudflare.com/');
  const zoneLink = page.locator(`a:has-text("${CF_ZONE}")`).first();
  if ((await zoneLink.count()) === 0) {
    await page.waitForTimeout(2000);
  }
  await zoneLink.click();
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
}

async function createCacheRule(page) {
  await goto(page, `https://dash.cloudflare.com/?to=/:account/${CF_ZONE}/rules/cache`);
  await page.waitForTimeout(1200);

  const createButton = page.locator('button:has-text("Create rule"), button:has-text("Create Cache Rule"), button:has-text("Create cache rule")').first();
  if ((await createButton.count()) > 0) {
    await createButton.click();
  }
  await page.waitForTimeout(1200);

  // Rule name
  const nameInput = page.locator('input[placeholder*="Rule name"], input[name="name"]').first();
  if ((await nameInput.count()) > 0) {
    await nameInput.fill('Cache HTML (Guests)');
  }

  // Expression editor (use simple textarea)
  const expression = `(http.request.method eq "GET" and http.request.uri.path !contains "/wp-admin" and http.request.uri.path !contains "/wp-login.php" and http.request.uri.path !contains "/panier" and http.request.uri.path !contains "/commande" and http.request.uri.path !contains "/checkout" and http.request.uri.path !contains "/cart" and http.request.uri.path !contains "/my-account")`;

  const exprBox = page.locator('textarea[placeholder*="Expression"], textarea[name="expression"], textarea').first();
  if ((await exprBox.count()) > 0) {
    await exprBox.fill(expression);
  }

  // Action: Cache -> Eligible
  const actionDropdown = page.locator('button:has-text("Select action"), button:has-text("Cache")').first();
  if ((await actionDropdown.count()) > 0) {
    await actionDropdown.click();
    await page.locator('span:has-text("Cache")').first().click().catch(() => null);
  }

  // Cache status: Eligible (Cache everything)
  const cacheStatus = page.locator('button:has-text("Cache status"), button:has-text("Eligible"), select').first();
  if ((await cacheStatus.count()) > 0) {
    await cacheStatus.click().catch(() => null);
    await page.locator('span:has-text("Eligible")').first().click().catch(() => null);
  }

  // Edge TTL: 1 day
  const edgeTtl = page.locator('button:has-text("Edge TTL"), select').first();
  if ((await edgeTtl.count()) > 0) {
    await edgeTtl.click().catch(() => null);
    await page.locator('span:has-text("1 day")').first().click().catch(() => null);
  }

  // Save
  const saveButton = page.locator('button:has-text("Deploy"), button:has-text("Save"), button:has-text("Create")').first();
  if ((await saveButton.count()) > 0) {
    await saveButton.click();
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  }
}

async function main() {
  if (!CF_EMAIL || !CF_PASS) {
    throw new Error('Missing CF_EMAIL/CF_PASS.');
  }
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await login(page);
    await openZone(page);
    await createCacheRule(page);

    writeReport('configure-cloudflare-cache.json', {
      updatedAt: new Date().toISOString(),
      zone: CF_ZONE,
      result: 'attempted',
    });
    console.log(JSON.stringify({ ok: true }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
