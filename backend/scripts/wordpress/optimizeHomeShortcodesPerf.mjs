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
  const re = /\[(products|woodmart_products)\b([^\]]*)\]/gi;
  const changes = [];

  const nextContent = content.replace(re, (raw, shortcode) => {
    if (shortcode.toLowerCase() !== 'woodmart_products') {
      return raw;
    }

    let next = raw;
    const before = raw;

    next = replaceAttr(next, 'lazy_loading', 'yes');
    next = replaceAttr(next, 'autoplay', 'no');
    next = replaceAttr(next, 'scroll_carousel_init', 'yes');

    const idsMatch = raw.match(/\b(include|ids)="([^"]+)"/i);
    const taxonomiesMatch = raw.match(/\btaxonomies="([^"]+)"/i);
    const itemsPerPageMatch = raw.match(/\b(items_per_page)="([^"]+)"/i);

    if (idsMatch) {
      const ids = idsMatch[2].split(',').map((value) => value.trim()).filter(Boolean);
      if (ids.length > 8) {
        next = replaceAttr(next, idsMatch[1], ids.slice(0, 8).join(', '));
      }
      if (itemsPerPageMatch) {
        const nextCount = Math.min(Number(itemsPerPageMatch[2]) || ids.length, Math.min(ids.length, 8));
        next = replaceAttr(next, 'items_per_page', String(nextCount));
      }
    } else if (taxonomiesMatch) {
      const current = Number(itemsPerPageMatch?.[2] || '0');
      const target = current > 0 ? Math.min(current, 8) : 8;
      next = replaceAttr(next, 'items_per_page', String(target));
    }

    const slidesPerViewMatch = next.match(/\bslides_per_view="([^"]+)"/i);
    if (slidesPerViewMatch) {
      const nextSlides = Math.min(Number(slidesPerViewMatch[1]) || 0, 4);
      if (nextSlides > 0) {
        next = replaceAttr(next, 'slides_per_view', String(nextSlides));
      }
    }

    if (next !== before) {
      changes.push({
        before,
        after: next,
      });
    }

    return next;
  });

  return {
    nextContent,
    changes,
  };
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

    writeReport('optimize-home-shortcodes-perf.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
