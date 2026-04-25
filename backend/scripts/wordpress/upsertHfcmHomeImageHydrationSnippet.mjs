import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Home Image Hydration';

const SNIPPET_CODE = `<script data-no-optimize="1" data-cfasync="false">
(function() {
  if (window.__gamaHomeImageHydrationInstalled) return;
  window.__gamaHomeImageHydrationInstalled = true;

  function isHomePage() {
    return document.body && document.body.classList.contains('home');
  }

  function shouldSwap(img) {
    if (!img || img.dataset.gamaHydrated === '1') return false;
    var dataSrc = img.getAttribute('data-src');
    var dataSrcset = img.getAttribute('data-srcset');
    if (!dataSrc && !dataSrcset) return false;

    var src = img.getAttribute('src') || '';
    return (
      src.indexOf('/themes/woodmart/images/lazy.svg') !== -1 ||
      src.indexOf('data:image/svg+xml') === 0 ||
      src.indexOf('data:image/svg+xml;base64') === 0 ||
      !src
    );
  }

  function hydrateImage(img, eager) {
    if (!shouldSwap(img)) return;

    var dataSrc = img.getAttribute('data-src');
    var dataSrcset = img.getAttribute('data-srcset');
    var dataSizes = img.getAttribute('data-sizes');

    if (dataSrc) {
      img.setAttribute('src', dataSrc);
      img.removeAttribute('data-src');
    }
    if (dataSrcset) {
      img.setAttribute('srcset', dataSrcset);
      img.removeAttribute('data-srcset');
    }
    if (dataSizes) {
      img.setAttribute('sizes', dataSizes);
      img.removeAttribute('data-sizes');
    }

    img.setAttribute('decoding', 'async');
    img.setAttribute('loading', eager ? 'eager' : 'lazy');
    if (eager) {
      img.setAttribute('fetchpriority', 'high');
    }

    img.dataset.gamaHydrated = '1';
    img.classList.add('gama-image-hydrated');
  }

  function collectTargets(root) {
    var scope = root || document;
    return Array.prototype.slice.call(
      scope.querySelectorAll(
        '.product-image-link img[data-src], .super-block-slider img[data-src], .wd-swiper img[data-src]'
      )
    );
  }

  function primeAboveTheFold() {
    collectTargets().forEach(function(img) {
      var rect = img.getBoundingClientRect();
      var nearViewport = rect.top < window.innerHeight * 1.5 && rect.bottom > -200;
      if (nearViewport) {
        hydrateImage(img, true);
      }
    });
  }

  function observeLazyTargets() {
    var observer = new IntersectionObserver(
      function(entries) {
        entries.forEach(function(entry) {
          if (!entry.isIntersecting) return;
          hydrateImage(entry.target, false);
          observer.unobserve(entry.target);
        });
      },
      { rootMargin: '400px 0px' }
    );

    collectTargets().forEach(function(img) {
      if (img.dataset.gamaObserved === '1') return;
      img.dataset.gamaObserved = '1';
      observer.observe(img);
    });

    var mutationObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          if (!(node instanceof HTMLElement)) return;
          collectTargets(node).forEach(function(img) {
            if (img.dataset.gamaObserved === '1') return;
            img.dataset.gamaObserved = '1';
            observer.observe(img);
          });
        });
      });
    });

    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true,
    });
  }

  function run() {
    if (!isHomePage()) return;
    primeAboveTheFold();
    observeLazyTargets();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', run, { once: true });
  } else {
    run();
  }
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

        if (!title) return null;

        return {
          id,
          title: title.trim(),
          editHref,
          deleteHref,
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
  await page.selectOption('select[name="data[snippet_type]"]', 'html');
  await page.selectOption('select[name="data[display_on]"]', 's_is_home');
  await page.selectOption('select[name="data[location]"]', 'header');
  await page.selectOption('select[name="data[device_type]"]', 'both');
  await page.selectOption('select[name="data[status]"]', 'active');

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

  const submit = page.locator('input[name="insert"], input[type="submit"]').first();
  await submit.click();
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
    const created = after
      .filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase())
      .sort((left, right) => right.id - left.id)[0] || null;

    const purge = await purgeCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      snippetName: SNIPPET_NAME,
      snippetId: created?.id || null,
      purge,
    };

    writeReport('upsert-hfcm-home-image-hydration-snippet.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
