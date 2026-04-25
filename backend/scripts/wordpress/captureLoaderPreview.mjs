import { chromium } from 'playwright-core';
import { resolveBrowserPath, writeReport } from './productCategoryMenuSync.mjs';

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
    const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
    const page = await context.newPage();

    await page.route('**/*', async (route) => {
      const url = route.request().url();
      if (/\.(png|jpe?g|webp|gif|svg|css|js)(\?|$)/i.test(url)) {
        await new Promise((resolve) => setTimeout(resolve, 400));
      }
      await route.continue();
    });

    await page.goto('https://gamaoutillage.net/', {
      waitUntil: 'commit',
      timeout: 60000,
    });

    await page.waitForTimeout(220);

    const state = await page.evaluate(() => ({
      readyState: document.readyState,
      htmlClasses: document.documentElement.className,
      hasPending: document.documentElement.classList.contains('gama-loader-pending'),
      hasReady: document.documentElement.classList.contains('gama-loader-ready'),
    }));

    const screenshotPath = 'backend/scripts/wordpress/out/gama-loader-preview.png';
    await page.screenshot({ path: screenshotPath, fullPage: false });

    const report = {
      updatedAt: new Date().toISOString(),
      screenshotPath,
      state,
    };

    writeReport('capture-loader-preview.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
