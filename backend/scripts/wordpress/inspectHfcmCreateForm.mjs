import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`);

    const listData = await page.evaluate(() => ({
      links: Array.from(document.querySelectorAll('a'))
        .map((link) => ({
          text: (link.textContent || '').replace(/\s+/g, ' ').trim(),
          href: link.href || '',
        }))
        .filter((item) => /add|ajouter|new/i.test(item.text))
        .slice(0, 30),
      bodyPreview: (document.body?.innerText || '').slice(0, 4000),
    }));

    const addUrl =
      listData.links.find((item) => /hfcm/i.test(item.href))?.href ||
      `${config.baseUrl}/wp-admin/admin.php?page=hfcm-create`;

    await goto(page, addUrl);

    const formData = await page.evaluate(() => ({
      url: location.href,
      title: document.title,
      bodyPreview: (document.body?.innerText || '').slice(0, 6000),
      fields: Array.from(document.querySelectorAll('input, select, textarea, button'))
        .map((node) => ({
          tag: node.tagName.toLowerCase(),
          type: node.getAttribute('type') || '',
          name: node.getAttribute('name') || '',
          id: node.id || '',
          value: node.getAttribute('value') || '',
          text: (node.textContent || '').replace(/\s+/g, ' ').trim(),
        }))
        .slice(0, 300),
    }));

    const report = {
      updatedAt: new Date().toISOString(),
      listData,
      formData,
    };

    writeReport('inspect-hfcm-create-form.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
