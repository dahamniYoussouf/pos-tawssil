import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const TARGET_IDS = (process.env.HFCM_IDS || '')
  .split(',')
  .map((value) => Number(value.trim()))
  .filter(Boolean);

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForSelector('table tbody tr', { timeout: 15000 }).catch(() => null);
  await page.waitForTimeout(500);
}

async function collectRows(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const id = Number(row.querySelector('input[name="snippets[]"]')?.value || '0');
        const title = row.querySelector('td.name strong')?.textContent || row.querySelector('strong')?.textContent || '';
        const deleteHref =
          Array.from(row.querySelectorAll('a')).find((link) => /delete|supprimer/i.test((link.textContent || '').trim()))?.href || '';

        if (!id || !title) return null;

        return {
          id,
          title: title.trim(),
          deleteHref,
        };
      })
      .filter(Boolean)
  );
}

async function deleteSnippet(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(700);
}

async function purgeCaches(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/index.php`, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(500);

  const links = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href || '',
      }))
      .filter((item) => item.href)
  );

  const targets = links.filter((item) => {
    const text = `${item.text} ${item.href}`.toLowerCase();
    return (
      text.includes('tout purger - lscache') ||
      text.includes('purge all lscache') ||
      text.includes('cache css/js') ||
      text.includes('cloudflare')
    );
  });

  for (const target of targets) {
    await page.goto(target.href, { waitUntil: 'domcontentloaded', timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(800);
  }

  return targets;
}

async function main() {
  if (!TARGET_IDS.length) {
    throw new Error('Missing HFCM_IDS env value.');
  }

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const deleted = [];
    const seen = new Set();

    for (let pageNumber = 1; pageNumber <= 3; pageNumber += 1) {
      const url =
        pageNumber === 1
          ? `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`
          : `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list&paged=${pageNumber}`;
      await goto(page, url);

      const rows = await collectRows(page);
      const matches = rows.filter((row) => TARGET_IDS.includes(row.id));
      if (matches.length === 0 && pageNumber > 1) break;

      for (const row of matches) {
        if (seen.has(row.id) || !row.deleteHref) continue;
        seen.add(row.id);
        await deleteSnippet(page, row.deleteHref);
        deleted.push(row);
      }
    }

    const purge = await purgeCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      targetIds: TARGET_IDS,
      deleted,
      purge,
    };

    writeReport('remove-hfcm-snippets-by-ids.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
