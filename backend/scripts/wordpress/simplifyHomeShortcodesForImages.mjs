import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const HOME_POST_ID = '2124';

function replaceAttr(raw, attr, value) {
  const attrRe = new RegExp(`\\b${attr}="[^"]*"`, 'i');
  if (attrRe.test(raw)) {
    return raw.replace(attrRe, `${attr}="${value}"`);
  }
  return raw.replace(/\]$/, ` ${attr}="${value}"]`);
}

function transformShortcodes(content) {
  const re = /\[(woodmart_products)\b([^\]]*)\]/gi;
  const changes = [];

  const nextContent = content.replace(re, (raw) => {
    let next = raw;
    const before = raw;

    next = replaceAttr(next, 'lazy_loading', 'no');
    next = replaceAttr(next, 'scroll_carousel_init', 'no');
    next = replaceAttr(next, 'autoplay', 'no');

    if (next !== before) {
      changes.push({ before, after: next });
    }

    return next;
  });

  return { nextContent, changes };
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
  const candidates = ['#publish', '#save-post', 'button.editor-post-publish-button'];
  for (const selector of candidates) {
    const locator = page.locator(selector).first();
    if (await locator.count()) {
      await locator.click().catch(() => null);
      await page.waitForTimeout(3000);
      return true;
    }
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
    const { nextContent, changes } = transformShortcodes(beforeContent);

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
      changesCount: changes.length,
      changes,
      didUpdate: changes.length > 0,
    };

    writeReport('simplify-home-shortcodes-for-images.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
