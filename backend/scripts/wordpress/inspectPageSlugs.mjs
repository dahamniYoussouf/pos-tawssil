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

async function readPageInfo(page, postId) {
  await goto(page, `${page.context()._options.baseURL || ''}/wp-admin/post.php?post=${postId}&action=edit`.replace('undefined', ''));
  return page.evaluate(() => {
    const title = (document.querySelector('#title')?.value || '').trim();
    const slugInput = document.querySelector('#post_name');
    const slugText = document.querySelector('#editable-post-name')?.textContent || '';
    const permalink = document.querySelector('#sample-permalink a')?.getAttribute('href') || '';
    return {
      title,
      slug: (slugInput instanceof HTMLInputElement ? slugInput.value : slugText).trim(),
      permalink,
    };
  });
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    const pageIds = ['10', '11', '12'];
    const pages = {};

    for (const id of pageIds) {
      await goto(page, `${config.baseUrl}/wp-admin/post.php?post=${id}&action=edit`);
      pages[id] = await page.evaluate(() => {
        const title = (document.querySelector('#title')?.value || '').trim();
        const slugInput = document.querySelector('#post_name');
        const slugText = document.querySelector('#editable-post-name')?.textContent || '';
        const permalink = document.querySelector('#sample-permalink a')?.getAttribute('href') || '';
        return {
          title,
          slug: (slugInput instanceof HTMLInputElement ? slugInput.value : slugText).trim(),
          permalink,
        };
      });
    }

    const report = {
      updatedAt: new Date().toISOString(),
      pages,
    };

    writeReport('inspect-page-slugs.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
