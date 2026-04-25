import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Loader Overlay';
const LOGO_URL = 'https://gamaoutillage.net/wp-content/uploads/2024/02/Logo-Gama-Outillage.png.webp';

const SNIPPET_CODE = `<style>
.gama-loader-screen {
  position: fixed;
  inset: 0;
  z-index: 2147483647;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  opacity: 1;
  visibility: visible;
  pointer-events: none;
  transition: opacity 0.35s ease, visibility 0.35s ease;
}

.gama-loader-screen.is-leaving {
  opacity: 0;
  visibility: hidden;
}

.gama-loader-screen__logo {
  width: min(420px, 72vw);
  aspect-ratio: 2048 / 859;
  background: url("${LOGO_URL}") center center / contain no-repeat;
  animation: gamaLoaderFloat 1.05s ease-in-out infinite alternate;
}

.gama-loader-screen.is-leaving .gama-loader-screen__logo {
  animation: none;
  transform: scale(0.98);
}

@keyframes gamaLoaderFloat {
  0% {
    transform: translateY(0) scale(1);
    opacity: 0.92;
  }

  100% {
    transform: translateY(-6px) scale(1.02);
    opacity: 1;
  }
}

@media (prefers-reduced-motion: reduce) {
  .gama-loader-screen__logo {
    animation: none;
  }
}
</style>
<script data-no-optimize="1" data-cfasync="false">
(function() {
  if (window.__gamaLoaderInstalled) return;
  window.__gamaLoaderInstalled = true;

  var doc = document;
  var overlay = doc.createElement('div');
  overlay.className = 'gama-loader-screen';
  overlay.setAttribute('aria-hidden', 'true');
  overlay.innerHTML = '<div class="gama-loader-screen__logo"></div>';

  var target = doc.body || doc.documentElement;
  target.appendChild(overlay);

  var finished = false;
  function finish() {
    if (finished) return;
    finished = true;
    overlay.classList.add('is-leaving');
    window.setTimeout(function() {
      overlay.remove();
    }, 420);
  }

  if (doc.readyState === 'complete') {
    window.setTimeout(finish, 120);
  } else {
    window.addEventListener('load', function() {
      window.setTimeout(finish, 160);
    }, { once: true });
  }

  window.setTimeout(finish, 2400);
})();
</script>`;

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

async function fillSnippetForm(page, isEdit = false) {
  await page.fill('input[name="data[name]"]', SNIPPET_NAME);
  await page.selectOption('select[name="data[snippet_type]"]', { label: 'HTML' });
  await page.selectOption('select[name="data[display_on]"]', { label: 'Sur l’ensemble du site' });
  await page.selectOption('select[name="data[location]"]', { label: 'Entête' });
  await page.selectOption('select[name="data[device_type]"]', { label: 'Afficher sur tous les appareils' });
  await page.selectOption('select[name="data[status]"]', { label: 'Activé' });

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

  const submitSelector = isEdit ? 'input[type="submit"][value*="Mettre"], input[type="submit"][value*="mettre"]' : 'input[name="insert"]';
  const submit = page.locator(submitSelector).first();
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

async function fetchHomepage(config) {
  const response = await fetch(`${config.baseUrl}/`, {
    headers: {
      'user-agent': 'Codex HFCM Loader Check',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
    },
  });

  const html = await response.text();
  return {
    status: response.status,
    containsSnippet: html.includes('__gamaLoaderInstalled') && html.includes('gama-loader-screen__logo'),
    containsLogoUrl: html.includes(LOGO_URL),
    loaderScriptCount: (html.match(/__gamaLoaderInstalled/g) || []).length,
    loaderLogoCount: (html.match(/gama-loader-screen__logo/g) || []).length,
    cacheStatus: response.headers.get('x-litespeed-cache') || '',
    cacheControl: response.headers.get('x-litespeed-cache-control') || '',
  };
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
    await fillSnippetForm(page, false);

    const after = await collectHfcmSnippets(page, config);
    const createdMatches = after
      .filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase())
      .sort((left, right) => right.id - left.id);
    const kept = createdMatches[0] || null;
    const removedAfterCreate = [];

    for (const duplicate of createdMatches.slice(1)) {
      if (duplicate.deleteHref) {
        await deleteSnippet(page, duplicate.deleteHref);
        removedAfterCreate.push(duplicate);
      }
    }

    const finalList = await collectHfcmSnippets(page, config);
    const remaining = finalList.filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase());
    const purge = await purgeCaches(page, config);
    const homepageCheck = await fetchHomepage(config);

    const report = {
      updatedAt: new Date().toISOString(),
      snippetName: SNIPPET_NAME,
      mode: existing.length ? 'recreated' : 'created',
      deleted: existing,
      kept,
      removedAfterCreate,
      remaining,
      purge,
      homepageCheck,
    };

    writeReport('upsert-hfcm-loader-snippet.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
