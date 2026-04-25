import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Home Hero Fix';

const SNIPPET_CODE = `<script data-no-optimize="1" data-cfasync="false">
(function() {
  function promoteHeroImage(img) {
    if (!img) return;
    var dataSrc = img.getAttribute('data-src');
    var dataSrcset = img.getAttribute('data-srcset');
    if (dataSrc) {
      img.setAttribute('src', dataSrc);
      img.removeAttribute('data-src');
    }
    if (dataSrcset) {
      img.setAttribute('srcset', dataSrcset);
      img.removeAttribute('data-srcset');
    }
    img.setAttribute('loading', 'eager');
    img.setAttribute('fetchpriority', 'high');
    img.setAttribute('decoding', 'async');
    img.classList.add('litespeed-load');
  }

  function run() {
    var hero =
      document.querySelector('img[data-src*="WEB-BANNER-DESKTOP"]') ||
      document.querySelector('img[data-src*="WEB-BANNER"]') ||
      document.querySelector('.super-block-slider img[data-src]') ||
      document.querySelector('.wd-swiper img[data-src]');
    promoteHeroImage(hero);

    var mobileHero = document.querySelector('img[data-src*="WEB-BANNER-MOBILE.png"]');
    if (mobileHero) {
      mobileHero.setAttribute('data-src', 'https://gamaoutillage.net/wp-content/uploads/2026/04/WEB-BANNER-DESKTOP-4-scaled-1-scaled.jpg');
      mobileHero.setAttribute('data-srcset', '');
      promoteHeroImage(mobileHero);
    }

    var flagFr = document.querySelector('img[src*="/2025/12/FR-2048x2048.png"], img[data-src*="/2025/12/FR-2048x2048.png"]');
    var flagAr = document.querySelector('img[src*="/2025/12/AR-2048x2048.png"], img[data-src*="/2025/12/AR-2048x2048.png"]');
    if (flagFr) {
      flagFr.setAttribute('src', 'https://gamaoutillage.net/wp-content/uploads/2025/12/FR-150x150.png');
      flagFr.setAttribute('srcset', '');
      flagFr.setAttribute('loading', 'lazy');
      flagFr.setAttribute('width', '24');
      flagFr.setAttribute('height', '24');
    }
    if (flagAr) {
      flagAr.setAttribute('src', 'https://gamaoutillage.net/wp-content/uploads/2025/12/AR-150x150.png');
      flagAr.setAttribute('srcset', '');
      flagAr.setAttribute('loading', 'lazy');
      flagAr.setAttribute('width', '24');
      flagAr.setAttribute('height', '24');
    }

    var replacements = {
      'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-06.jpg':
        'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-06-600x600.jpg',
      'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-07.jpg':
        'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-07-600x600.jpg',
      'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-08.jpg':
        'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-08-600x600.jpg',
      'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-10.jpg':
        'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-10-600x600.jpg',
      'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-11.jpg':
        'https://gamaoutillage.net/wp-content/uploads/2024/08/CT15171-GAMAOUTILLAGE-11-600x600.jpg'
    };

    document.querySelectorAll('img').forEach(function(img) {
      var src = img.getAttribute('src') || '';
      var dataSrc = img.getAttribute('data-src') || '';
      if (replacements[src]) {
        img.setAttribute('src', replacements[src]);
        img.setAttribute('srcset', '');
      }
      if (replacements[dataSrc]) {
        img.setAttribute('data-src', replacements[dataSrc]);
        img.setAttribute('data-srcset', '');
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run, { once: true });
  } else {
    run();
  }
})();
</script>
<style>
.super-block-slider img[data-src],
.wd-swiper img[data-src] {
  background-color: #ffffff;
}
</style>`;

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
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
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
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
    selectByText('select[name="data[location]"]', (text) => /ent[eê]te|header/i.test(text));
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
    return (
      text.includes('purge all lscache') ||
      text.includes('tout purger - lscache') ||
      text.includes('purge all css') ||
      text.includes('cache css/js') ||
      text.includes('cloudflare')
    );
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
    const removedAfterCreate = [];

    for (const duplicate of matches.slice(1)) {
      if (duplicate.deleteHref) {
        await deleteSnippet(page, duplicate.deleteHref);
        removedAfterCreate.push(duplicate);
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
      removedAfterCreate,
      purge,
    };

    writeReport('upsert-hfcm-hero-fix.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
