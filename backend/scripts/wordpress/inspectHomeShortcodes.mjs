import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const HOME_POST_ID = '2124';

function extractShortcodes(content) {
  const matches = [];
  const re = /\[(products|woodmart_products)\b([^\]]*)\]/gi;
  let match;

  while ((match = re.exec(content))) {
    const shortcode = match[1];
    const attrs = match[2] || '';
    const idsMatch = attrs.match(/\b(ids|include)="([^"]+)"/i);
    const perPageMatch = attrs.match(/\b(per_page|items_per_page)="([^"]+)"/i);
    const columnsMatch = attrs.match(/\b(columns)="([^"]+)"/i);

    matches.push({
      shortcode,
      raw: match[0],
      idsAttr: idsMatch ? idsMatch[1] : '',
      idsCount: idsMatch ? idsMatch[2].split(',').map((v) => v.trim()).filter(Boolean).length : 0,
      perPage: perPageMatch ? perPageMatch[2] : '',
      columns: columnsMatch ? columnsMatch[2] : '',
    });
  }

  return matches;
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/post.php?post=${HOME_POST_ID}&action=edit`, {
      waitUntil: 'domcontentloaded',
      timeout: 60000,
    });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForSelector('#content', { state: 'attached', timeout: 30000 });

    const content = await page.$eval('#content', (node) => node.value || '');
    const shortcodes = extractShortcodes(content);

    const report = {
      updatedAt: new Date().toISOString(),
      postId: HOME_POST_ID,
      total: shortcodes.length,
      shortcodes,
    };

    writeReport('inspect-home-shortcodes.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
