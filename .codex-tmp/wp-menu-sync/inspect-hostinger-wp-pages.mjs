import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
} from '../../backend/scripts/wordpress/productCategoryMenuSync.mjs';

const outDir = path.resolve('.codex-tmp/wp-menu-sync/out');

async function findHostingerLinks(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#adminmenu a, #wp-admin-bar-hostinger_admin_bar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href,
        rawHref: link.getAttribute('href') || '',
      }))
      .filter((link) => /hostinger/i.test(`${link.text} ${link.href} ${link.rawHref}`))
  );
}

async function capturePage(page, target) {
  await page.goto(target.href, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(() => null);

  return page.evaluate((meta) => {
    const links = Array.from(document.querySelectorAll('a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href,
        rawHref: link.getAttribute('href') || '',
      }))
      .filter((link) => link.text || link.rawHref)
      .slice(0, 300);

    return {
      target: meta,
      url: location.href,
      title: document.title,
      bodyText: (document.body?.innerText || '').slice(0, 12000),
      links,
    };
  }, target);
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle');

    const hostingerLinks = await findHostingerLinks(page);
    const pages = [];
    const seen = new Set();

    for (const link of hostingerLinks) {
      if (!link.href || seen.has(link.href)) continue;
      seen.add(link.href);
      pages.push(await capturePage(page, link));
    }

    const report = {
      checkedAt: new Date().toISOString(),
      hostingerLinks,
      pages,
    };

    fs.writeFileSync(path.join(outDir, 'hostinger-wp-pages.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
