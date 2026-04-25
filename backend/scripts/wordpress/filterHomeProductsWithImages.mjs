import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const HOME_POST_ID = '2124';

function extractShortcodeIds(content) {
  const matches = [];
  const re = /\[(products|woodmart_products)\b([^\]]*)\]/gi;
  let match;

  while ((match = re.exec(content))) {
    const shortcode = match[1];
    const attrs = match[2] || '';
    const keyMatch = attrs.match(/\b(ids|include)="([^"]+)"/i);
    if (!keyMatch) continue;

    const ids = keyMatch[2]
      .split(',')
      .map((value) => value.trim())
      .filter(Boolean);

    matches.push({
      shortcode,
      start: match.index,
      end: match.index + match[0].length,
      attrName: keyMatch[1],
      ids,
      raw: match[0],
    });
  }

  return matches;
}

async function fetchProductsWithImages(page, ids) {
  return page.evaluate(async (inputIds) => {
    const result = {};

    await Promise.all(
      inputIds.map(async (id) => {
        try {
          const response = await fetch(`/wp-json/wc/store/v1/products/${id}?_=${Date.now()}`, {
            credentials: 'same-origin',
            cache: 'no-store',
          });

          if (!response.ok) {
            result[id] = { hasImage: false, status: response.status };
            return;
          }

          const product = await response.json();
          const hasImage = Array.isArray(product?.images) && product.images.some((image) => !!(image?.src || image?.thumbnail || image?.full || image?.url));
          result[id] = { hasImage, status: response.status };
        } catch (error) {
          result[id] = { hasImage: false, error: error?.message || String(error) };
        }
      })
    );

    return result;
  }, ids);
}

async function openEditor(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/post.php?post=${HOME_POST_ID}&action=edit`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForSelector('#content', { state: 'attached', timeout: 30000 });
}

async function saveEditor(page) {
  const candidates = [
    '#publish',
    '#save-post',
    'button.editor-post-publish-button',
    'button.editor-post-save-draft',
  ];

  for (const selector of candidates) {
    const locator = page.locator(selector).first();
    if (await locator.count()) {
      await locator.click().catch(() => null);
      await page.waitForTimeout(3000);
      return true;
    }
  }

  const fallback = page.locator('button, input[type="submit"]').filter({
    hasText: /mettre à jour|update|publish|save/i,
  }).first();

  if (await fallback.count()) {
    await fallback.click().catch(() => null);
    await page.waitForTimeout(3000);
    return true;
  }

  return false;
}

async function purgeCaches(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/index.php`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);

  const actions = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href || '',
      }))
      .filter((item) => /purge|vider|cache|litespeed|cloudflare/i.test(`${item.text} ${item.href}`))
  );

  for (const action of actions) {
    await page.goto(action.href, { waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => null);
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(1000);
  }

  return actions;
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await openEditor(page, config);

    const beforeContent = await page.$eval('#content', (node) => node.value || '');
    const shortcodes = extractShortcodeIds(beforeContent);
    const ids = [...new Set(shortcodes.flatMap((item) => item.ids))];

    const imageMap = await fetchProductsWithImages(page, ids);

    let nextContent = beforeContent;
    const changes = [];

    for (const shortcode of shortcodes) {
      const keepIds = shortcode.ids.filter((id) => imageMap[id]?.hasImage);
      const nextList = keepIds.join(', ');
      const originalList = shortcode.ids.join(', ');

      if (nextList === originalList) continue;

      const replacement = shortcode.raw.replace(
        new RegExp(`${shortcode.attrName}="[^"]*"`),
        `${shortcode.attrName}="${nextList}"`
      );

      nextContent = nextContent.slice(0, shortcode.start) + replacement + nextContent.slice(shortcode.end);
      changes.push({
        shortcode: shortcode.shortcode,
        attrName: shortcode.attrName,
        beforeCount: shortcode.ids.length,
        afterCount: keepIds.length,
      });
    }

    if (changes.length > 0) {
      await page.$eval('#content', (node, value) => {
        node.value = value;
        node.dispatchEvent(new Event('input', { bubbles: true }));
        node.dispatchEvent(new Event('change', { bubbles: true }));
      }, nextContent);

      await saveEditor(page);
      await purgeCaches(page, config);
    }

    const report = {
      updatedAt: new Date().toISOString(),
      postId: HOME_POST_ID,
      totalShortcodes: shortcodes.length,
      uniqueIdsChecked: ids.length,
      changes,
      imageMap,
      didUpdate: changes.length > 0,
    };

    writeReport('filter-home-products-with-images.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
