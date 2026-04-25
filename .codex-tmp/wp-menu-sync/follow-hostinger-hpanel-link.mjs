import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
} from '../../backend/scripts/wordpress/productCategoryMenuSync.mjs';

const outDir = path.resolve('.codex-tmp/wp-menu-sync/out');

async function captureSummary(page) {
  return page.evaluate(() => ({
    url: location.href,
    title: document.title,
    bodyText: (document.body?.innerText || '').slice(0, 5000),
  }));
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, context, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/admin.php?page=hostinger`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle').catch(() => null);

    const target = page.getByText('Aller dans le hPanel', { exact: true });
    await target.waitFor({ state: 'visible', timeout: 30000 });

    const trigger = await target.evaluate((node) => ({
      tag: node.tagName,
      text: (node.textContent || '').trim(),
      id: node.id || '',
      className: node.className || '',
      href: node.getAttribute('href') || '',
      outerHTML: node.outerHTML,
    }));

    const popupPromise = context.waitForEvent('page', { timeout: 15000 }).catch(() => null);
    await target.click({ timeout: 15000 });
    const popup = await popupPromise;

    let result;
    if (popup) {
      await popup.waitForLoadState('domcontentloaded', { timeout: 60000 }).catch(() => null);
      await popup.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => null);
      result = { mode: 'popup', page: await captureSummary(popup) };
      await popup.screenshot({ path: path.join(outDir, 'hostinger-hpanel-popup.png'), fullPage: true }).catch(() => null);
    } else {
      await page.waitForLoadState('domcontentloaded', { timeout: 60000 }).catch(() => null);
      await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => null);
      result = { mode: 'same-page', page: await captureSummary(page) };
      await page.screenshot({ path: path.join(outDir, 'hostinger-hpanel-page.png'), fullPage: true }).catch(() => null);
    }

    const report = {
      checkedAt: new Date().toISOString(),
      trigger,
      result,
    };

    fs.writeFileSync(path.join(outDir, 'hostinger-hpanel-follow.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
