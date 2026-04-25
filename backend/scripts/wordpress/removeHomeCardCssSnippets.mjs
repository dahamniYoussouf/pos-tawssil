import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const TARGET_IDS = new Set([41, 42, 43, 44, 45, 46, 47, 48, 49]);

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForSelector('table tbody tr', { timeout: 15000 }).catch(() => null);
  await page.waitForTimeout(500);
}

async function collectRows(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const deleteHref =
          Array.from(row.querySelectorAll('a')).find((link) => /delete|supprimer/i.test((link.textContent || '').trim()))?.href || '';
        const id = Number(row.querySelector('input[name="snippets[]"]')?.value || '0');

        if (!id) return null;

        const title = row.querySelector('td.name strong')?.textContent || row.querySelector('strong')?.textContent || '';
        return { id, title: title.trim(), deleteHref };
      })
      .filter(Boolean)
  );
}

async function deleteSnippet(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(600);
}

async function purgeCaches(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/index.php`);

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
      text.includes('tout purger - cloudflare') ||
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
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);
  page.setDefaultTimeout(20000);

  try {
    await loginToWordPress(page, config);

    const deleted = [];

    for (let pageNumber = 1; pageNumber <= 2; pageNumber += 1) {
      const url =
        pageNumber === 1
          ? `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`
          : `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list&paged=${pageNumber}`;
      await goto(page, url);

      const rows = await collectRows(page);
      for (const row of rows) {
        if (!TARGET_IDS.has(row.id)) continue;
        if (row.deleteHref) {
          await deleteSnippet(page, row.deleteHref);
          deleted.push(row);
        }
      }
    }

    const purge = await purgeCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      deleted,
      purge,
    };

    writeReport('remove-home-card-css-snippets.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
