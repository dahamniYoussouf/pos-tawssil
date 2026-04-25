import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const IDS = (process.env.HFCM_IDS || '21,24').split(',').map((value) => Number(value.trim())).filter(Boolean);

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForSelector('textarea[name="data[snippet]"], .CodeMirror', { timeout: 15000 }).catch(() => null);
  await page.waitForTimeout(500);
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const results = [];

    for (const id of IDS) {
      await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-update&action=edit&id=${encodeURIComponent(id)}`);
      const data = await page.evaluate(() => {
        const textarea = document.querySelector('textarea[name="data[snippet]"]');
        const codeMirror = document.querySelector('.CodeMirror')?.CodeMirror;
        const snippet = textarea instanceof HTMLTextAreaElement ? textarea.value : '';
        return {
          title:
            (document.querySelector('input[name="data[name]"]') instanceof HTMLInputElement
              ? document.querySelector('input[name="data[name]"]').value
              : '') || '',
          snippet,
          snippetLength: snippet.length,
          snippetType:
            (document.querySelector('select[name="data[snippet_type]"]') instanceof HTMLSelectElement
              ? document.querySelector('select[name="data[snippet_type]"]').value
              : '') || '',
          displayOn:
            (document.querySelector('select[name="data[display_on]"]') instanceof HTMLSelectElement
              ? document.querySelector('select[name="data[display_on]"]').value
              : '') || '',
          location:
            (document.querySelector('select[name="data[location]"]') instanceof HTMLSelectElement
              ? document.querySelector('select[name="data[location]"]').value
              : '') || '',
          deviceType:
            (document.querySelector('select[name="data[device_type]"]') instanceof HTMLSelectElement
              ? document.querySelector('select[name="data[device_type]"]').value
              : '') || '',
          status:
            (document.querySelector('select[name="data[status]"]') instanceof HTMLSelectElement
              ? document.querySelector('select[name="data[status]"]').value
              : '') || '',
          codeMirrorLength: codeMirror?.getValue ? codeMirror.getValue().length : 0,
        };
      });
      results.push({ id, ...data });
    }

    const report = { updatedAt: new Date().toISOString(), results };
    writeReport('inspect-hfcm-snippet-by-ids.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
