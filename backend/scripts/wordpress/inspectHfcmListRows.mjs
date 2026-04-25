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
  await page.waitForTimeout(1500);
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    const pageNumber = Number(process.env.HFCM_PAGE || '1');
    const listUrl =
      pageNumber > 1
        ? `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list&paged=${pageNumber}`
        : `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`;
    await goto(page, listUrl);

    const rows = await page.evaluate(() =>
      Array.from(document.querySelectorAll('table tbody tr')).map((row, index) => ({
        index,
        text: (row.textContent || '').replace(/\s+/g, ' ').trim(),
        html: (row.innerHTML || '').slice(0, 4000),
        links: Array.from(row.querySelectorAll('a')).map((link) => ({
          text: (link.textContent || '').replace(/\s+/g, ' ').trim(),
          href: link.href || '',
        })),
      }))
    );

    const pagination = await page.evaluate(() => {
      const totalText = document.querySelector('.tablenav-pages .total-pages')?.textContent?.trim() || '';
      const currentText = document.querySelector('.tablenav-pages .current-page')?.value || '';
      const nextHref = document.querySelector('.tablenav-pages a.next-page')?.getAttribute('href') || '';
      return {
        totalPages: Number(totalText) || 1,
        currentPage: Number(currentText) || 1,
        nextHref,
      };
    });

    const report = {
      updatedAt: new Date().toISOString(),
      url: page.url(),
      title: await page.title(),
      pageNumber,
      rowCount: rows.length,
      pagination,
      rows,
    };

    writeReport('inspect-hfcm-list-rows.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
