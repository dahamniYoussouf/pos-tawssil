import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/plugins.php?plugin_status=active`, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(1200);

    const plugins = await page.evaluate(() =>
      Array.from(document.querySelectorAll('tr[data-slug]')).map((row) => ({
        slug: row.getAttribute('data-slug') || '',
        plugin: row.getAttribute('data-plugin') || '',
        title:
          row.querySelector('.plugin-title strong')?.textContent?.trim() ||
          row.querySelector('strong')?.textContent?.trim() ||
          '',
        description:
          row.querySelector('.plugin-description')?.textContent?.replace(/\s+/g, ' ').trim() || '',
        deactivateHref: row.querySelector('.deactivate a')?.href || '',
        activateHref: row.querySelector('.activate a')?.href || '',
      }))
    );

    const report = {
      updatedAt: new Date().toISOString(),
      plugins,
    };

    writeReport('active-plugins.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
