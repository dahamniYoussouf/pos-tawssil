import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Home Image Fix';

const SNIPPET_CODE = `<script data-no-optimize="1" data-cfasync="false">
(function() {
  if (window.__gamaHomeImageFixInstalled) return;
  window.__gamaHomeImageFixInstalled = true;

  var RUN_TIMEOUT = 10000;
  var RUN_INTERVAL = 250;
  var startedAt = Date.now();
  var timer = null;
  var done = false;

  function isHome() {
    return document.body && document.body.classList.contains('home');
  }

  function isLazyPlaceholder(src) {
    return !src || /^data:image\\//i.test(src);
  }

  function fixImage(img) {
    if (!(img instanceof HTMLImageElement)) return false;

    var currentSrc = img.getAttribute('src') || '';
    var dataSrc = img.getAttribute('data-src') || '';
    var dataSrcset = img.getAttribute('data-srcset') || '';
    var dataSizes = img.getAttribute('data-sizes') || '';
    var lazySrc = img.getAttribute('data-lazy-src') || '';

    var nextSrc = dataSrc || lazySrc || currentSrc;
    if (!nextSrc || !img.complete || (!isLazyPlaceholder(currentSrc) && currentSrc === nextSrc)) {
      return false;
    }

    img.loading = 'eager';
    img.fetchPriority = 'high';
    img.decoding = 'async';

    if (dataSrcset) img.setAttribute('srcset', dataSrcset);
    if (dataSizes) img.setAttribute('sizes', dataSizes);
    img.setAttribute('src', nextSrc);
    img.removeAttribute('data-src');
    img.removeAttribute('data-lazy-src');
    img.removeAttribute('data-lazyloaded');
    img.classList.add('entered', 'litespeed-loaded');
    return true;
  }

  function run() {
    if (done || !isHome()) return false;

    var touched = false;
    document.querySelectorAll('.home .products img.attachment-woocommerce_thumbnail, .home .wd-product-grid-slider img').forEach(function(img) {
      touched = fixImage(img) || touched;
    });

    if (touched) {
      document.documentElement.classList.add('gama-home-images-fixed');
      done = true;
    }

    return touched;
  }

  function stop() {
    if (timer) clearInterval(timer);
    timer = null;
    document.documentElement.classList.remove('gama-home-images-fixing');
  }

  function start() {
    if (!isHome()) return;

    document.documentElement.classList.add('gama-home-images-fixing');
    run();

    timer = window.setInterval(function() {
      if (Date.now() - startedAt > RUN_TIMEOUT) {
        stop();
        return;
      }

      if (run()) {
        stop();
      }
    }, RUN_INTERVAL);

    window.setTimeout(stop, RUN_TIMEOUT);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start, { once: true });
  } else {
    start();
  }
})();
</script>
<style>
html.gama-home-images-fixing .home .products img.attachment-woocommerce_thumbnail {
  opacity: 1 !important;
  visibility: visible !important;
}
</style>`;

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectHfcmSnippets(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`);

  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const links = Array.from(row.querySelectorAll('a')).map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href || '',
        }));

        const editHref = links.find((item) => /edit|modifier/i.test(item.text))?.href || '';
        const deleteHref = links.find((item) => /delete|supprimer/i.test(item.text))?.href || '';
        const title = row.querySelector('td.name strong')?.textContent || row.querySelector('strong')?.textContent || '';
        const id = Number(row.querySelector('input[name="snippets[]"]')?.value || '0');
        const enabled = !!row.querySelector('.round-toggle:checked');

        if (!title) return null;

        return {
          id,
          title: title.trim(),
          editHref,
          deleteHref,
          enabled,
          rowText: (row.textContent || '').replace(/\s+/g, ' ').trim(),
        };
      })
      .filter(Boolean)
  );
}

async function deleteSnippet(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function fillSnippetForm(page) {
  await page.fill('input[name="data[name]"]', SNIPPET_NAME);
  await page.evaluate(() => {
    function selectByText(selector, matcher) {
      const select = document.querySelector(selector);
      if (!(select instanceof HTMLSelectElement)) return;
      const option = Array.from(select.options).find((opt) => matcher(opt.textContent || ''));
      if (option) {
        select.value = option.value;
        select.dispatchEvent(new Event('change', { bubbles: true }));
      }
    }

    selectByText('select[name="data[snippet_type]"]', (text) => /html/i.test(text));
    selectByText('select[name="data[display_on]"]', (text) => /ensemble|site/i.test(text));
    selectByText('select[name="data[location]"]', (text) => /ent[eÃª]te|header/i.test(text));
    selectByText('select[name="data[device_type]"]', (text) => /tous|toutes|all/i.test(text));
    selectByText('select[name="data[status]"]', (text) => /activ/i.test(text));
  });

  await page.evaluate((code) => {
    const textarea = document.querySelector('textarea[name="data[snippet]"]');
    if (textarea instanceof HTMLTextAreaElement) {
      textarea.value = code;
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
      textarea.dispatchEvent(new Event('change', { bubbles: true }));
    }

    const codeMirror = document.querySelector('.CodeMirror')?.CodeMirror;
    if (codeMirror?.setValue) {
      codeMirror.setValue(code);
      codeMirror.save?.();
    }
  }, SNIPPET_CODE);

  await page.waitForTimeout(300);

  const submit = page.locator('input[name="insert"]').first();
  if ((await submit.count()) > 0) {
    await submit.click();
  } else {
    await page.locator('input[type="submit"]').first().click();
  }

  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);
}

async function purgeCaches(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/index.php`);

  const targets = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href || '',
      }))
      .filter((item) => item.href)
  );

  const relevant = targets.filter((item) => {
    const text = `${item.text} ${item.href}`.toLowerCase();
    return text.includes('purge') || text.includes('vider') || text.includes('cache') || text.includes('litespeed') || text.includes('cloudflare');
  });

  for (const target of relevant) {
    await page.goto(target.href, { waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => null);
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(1000);
  }

  return relevant;
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const before = await collectHfcmSnippets(page, config);
    const existing = before.filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase());

    for (const snippet of existing) {
      if (snippet.deleteHref) {
        await deleteSnippet(page, snippet.deleteHref);
      }
    }

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-create`);
    await fillSnippetForm(page);

    const after = await collectHfcmSnippets(page, config);
    const matches = after
      .filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase())
      .sort((left, right) => right.id - left.id);
    const kept = matches[0] || null;

    for (const duplicate of matches.slice(1)) {
      if (duplicate.deleteHref) {
        await deleteSnippet(page, duplicate.deleteHref);
      }
    }

    const remaining = (await collectHfcmSnippets(page, config)).filter(
      (item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase()
    );

    const purge = await purgeCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      snippetName: SNIPPET_NAME,
      deleted: existing,
      kept,
      remaining,
      purge,
    };

    writeReport('upsert-hfcm-home-image-fix.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
