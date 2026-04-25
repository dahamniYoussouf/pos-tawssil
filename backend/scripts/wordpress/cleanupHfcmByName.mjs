import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const targetName = (process.env.HFCM_NAME || '').trim().toLowerCase();

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectHfcmSnippets(page) {
  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const links = Array.from(row.querySelectorAll('a')).map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href || '',
        }));
        const title = row.querySelector('td.name strong')?.textContent || row.querySelector('strong')?.textContent || '';
        const deleteHref = links.find((item) => /delete|supprimer/i.test(item.text))?.href || '';
        const id = Number(row.querySelector('input[name="snippets[]"]')?.value || '0');
        return { id, title: title.trim(), deleteHref };
      })
      .filter((item) => item.id && item.title)
  );
}

async function deleteSnippet(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function main() {
  if (!targetName) {
    throw new Error('Missing HFCM_NAME env value.');
  }
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    const deleted = [];
    const remaining = [];

    for (let p = 1; p <= 3; p += 1) {
      const url =
        p === 1
          ? `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`
          : `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list&paged=${p}`;
      await goto(page, url);
      const rows = await collectHfcmSnippets(page);
      const matches = rows.filter((item) => item.title.toLowerCase() === targetName);
      if (matches.length === 0 && p > 1) break;
      if (matches.length > 0) {
        const keep = matches.sort((a, b) => b.id - a.id)[0];
        remaining.push(keep);
        for (const item of matches) {
          if (item.id !== keep.id && item.deleteHref) {
            await deleteSnippet(page, item.deleteHref);
            deleted.push(item);
          }
        }
      }
    }

    writeReport('cleanup-hfcm-by-name.json', {
      updatedAt: new Date().toISOString(),
      targetName,
      deleted,
      remaining,
    });

    console.log(JSON.stringify({ ok: true, deleted, remaining }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
