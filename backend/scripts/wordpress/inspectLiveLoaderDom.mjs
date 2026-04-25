import { chromium } from 'playwright-core';
import { resolveBrowserPath, writeReport } from './productCategoryMenuSync.mjs';

async function snapshot(page, label) {
  const data = await page.evaluate((tag) => {
    const matches = Array.from(
      document.querySelectorAll(
        '[id*="loft"], [class*="loft"], [id*="loader"], [class*="loader"], [id*="preload"], [class*="preload"]'
      )
    )
      .map((node) => ({
        tag,
        tagName: node.tagName.toLowerCase(),
        id: node.id || '',
        className: node.className || '',
        text: (node.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 200),
        html: (node.outerHTML || '').slice(0, 1200),
      }))
      .filter((item) => /loft|loader|preload/i.test(`${item.id} ${item.className}`))
      .slice(0, 50);

    return {
      url: location.href,
      readyState: document.readyState,
      title: document.title,
      bodyClasses: document.body?.className || '',
      matches,
    };
  }, label);

  return data;
}

async function main() {
  const browserPath = resolveBrowserPath();
  if (!browserPath) {
    throw new Error('Could not resolve browser path.');
  }

  const browser = await chromium.launch({
    executablePath: browserPath,
    headless: true,
  });

  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1200 } });

    const snapshots = [];
    await page.goto('https://gamaoutillage.net/', {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });

    snapshots.push(await snapshot(page, 'after-domcontentloaded'));
    await page.waitForTimeout(250);
    snapshots.push(await snapshot(page, 'after-250ms'));
    await page.waitForTimeout(750);
    snapshots.push(await snapshot(page, 'after-1000ms'));
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    snapshots.push(await snapshot(page, 'after-networkidle'));

    const report = {
      updatedAt: new Date().toISOString(),
      snapshots,
    };

    writeReport('inspect-live-loader-dom.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
