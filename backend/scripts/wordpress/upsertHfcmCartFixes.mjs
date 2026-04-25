import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Cart/Checkout Fixes';
const CHECKOUT_URL = 'https://gamaoutillage.net/commande/';

const SNIPPET_CODE = `<script data-no-optimize="1" data-cfasync="false">
(function() {
  if (window.__gamaCartFixesInstalled) return;
  window.__gamaCartFixesInstalled = true;

  var LOCK_ATTR = 'data-gama-cart-locked';
  var LOCK_TIME = 1200;
  document.addEventListener('click', function(event) {
    var target = event.target && event.target.closest
      ? event.target.closest('.add_to_cart_button, .ajax_add_to_cart, button.single_add_to_cart_button, form.cart button[type="submit"]')
      : null;
    if (!target) return;

    if (target.getAttribute(LOCK_ATTR) === '1') {
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    }

    target.setAttribute(LOCK_ATTR, '1');
    target.classList.add('gama-cart-locked');
    window.setTimeout(function() {
      target.removeAttribute(LOCK_ATTR);
      target.classList.remove('gama-cart-locked');
    }, LOCK_TIME);
  }, true);

  function ensureCheckoutButton() {
    var path = window.location.pathname || '';
    if (!/panier|cart/.test(path)) return;

    if (document.querySelector('.wc-proceed-to-checkout, a.checkout-button')) return;

    var cartTotals = document.querySelector(
      '.cart_totals, .wc-cart-totals, .cart-collaterals, .wd-cart-totals, .woocommerce-cart-form'
    );
    if (!cartTotals) return;

    var wrapper = document.createElement('div');
    wrapper.className = 'wc-proceed-to-checkout gama-checkout-injected';
    wrapper.innerHTML = '<a href="${CHECKOUT_URL}" class="checkout-button button alt wc-forward">Finaliser la commande</a>';
    cartTotals.appendChild(wrapper);
  }

  document.addEventListener('DOMContentLoaded', ensureCheckoutButton);
  window.setTimeout(ensureCheckoutButton, 1200);
})();
</script>
<style>
.gama-cart-locked {
  pointer-events: none !important;
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

    writeReport('upsert-hfcm-cart-fixes.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
