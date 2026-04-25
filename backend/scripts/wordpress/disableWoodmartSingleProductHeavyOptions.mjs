import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const outDir = path.resolve('backend/scripts/wordpress/out');
const settingsPath = 'admin.php?page=xts_theme_settings&tab=general_single_product_section';

const targetOptions = [
  'linked_variations',
  'product_page_brand',
  'brand_tab',
  'compare',
  'wishlist',
  'related_products',
  'bought_together_enabled',
];

async function gotoAdminPage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);
}

async function readOptionValues(page) {
  return page.evaluate((names) => {
    const result = {};
    for (const name of names) {
      const input = document.querySelector(`input[name="xts-woodmart-options[${name}]"]`);
      result[name] = input ? String(input.value ?? '') : null;
    }
    return result;
  }, targetOptions);
}

async function setOptionsDisabled(page) {
  return page.evaluate((names) => {
    const updates = [];

    for (const name of names) {
      const input = document.querySelector(`input[name="xts-woodmart-options[${name}]"]`);
      if (!input) {
        updates.push({ name, found: false });
        continue;
      }

      const before = String(input.value ?? '');
      input.value = '0';
      input.setAttribute('value', '0');
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));

      const field = input.closest('.xts-field');
      const activeButton = field?.querySelector('.xts-buttons-control-inner .xts-btn.xts-active');
      const zeroButton =
        field?.querySelector('.xts-buttons-control-inner [data-value="0"]') ||
        field?.querySelector('.xts-buttons-control-inner .xts-btn:last-child');

      if (activeButton && zeroButton && activeButton !== zeroButton) {
        activeButton.classList.remove('xts-active');
        zeroButton.classList.add('xts-active');
      }

      const switcher = field?.querySelector('.xts-switcher-btn, .xts-switcher');
      if (switcher) {
        switcher.classList.remove('xts-active', 'xts-enabled');
        switcher.setAttribute('aria-checked', 'false');
      }

      updates.push({
        name,
        found: true,
        before,
        after: String(input.value ?? ''),
        changed: before !== '0',
      });
    }

    return updates;
  }, targetOptions);
}

async function saveOptions(page) {
  return page.evaluate(async () => {
    const form = document.querySelector('form[action="options.php"], form[action$="/options.php"]');
    if (!(form instanceof HTMLFormElement)) {
      return { submitted: false, reason: 'form_not_found' };
    }

    const formData = new FormData(form);
    const body = new URLSearchParams();

    for (const [key, value] of formData.entries()) {
      body.append(key, String(value));
    }

    const response = await fetch(form.action, {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      body: body.toString(),
    });

    const text = await response.text();

    return {
      submitted: true,
      status: response.status,
      ok: response.ok,
      url: response.url,
      bodyPreview: text.replace(/\s+/g, ' ').trim().slice(0, 1000),
    };
  });
}

async function purgeCaches(page, config) {
  await gotoAdminPage(page, config, 'index.php');

  const purgeTargets = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a')).map((link) => ({
      id: link.id || '',
      text: (link.textContent || '').trim(),
      href: link.href || '',
    }))
  );

  const used = [];

  for (const target of purgeTargets) {
    const haystack = `${target.id} ${target.text} ${target.href}`.toLowerCase();
    if (
      !target.href ||
      !(
        haystack.includes('purge all') ||
        haystack.includes('tout purger - lscache') ||
        haystack.includes('purge all lscache') ||
        haystack.includes('tout purger - cloudflare') ||
        haystack.includes('purge all cloudflare') ||
        haystack.includes('purge all css/js') ||
        haystack.includes('tout purger - cache css/js')
      )
    ) {
      continue;
    }

    await page.goto(target.href, { waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => null);
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(1000);
    used.push(target);
  }

  return used;
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await gotoAdminPage(page, config, settingsPath);

    const before = await readOptionValues(page);
    const updates = await setOptionsDisabled(page);
    const save = await saveOptions(page);

    await gotoAdminPage(page, config, settingsPath);
    const after = await readOptionValues(page);
    const purges = await purgeCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      settingsPath,
      before,
      updates,
      save,
      after,
      purges,
    };

    writeReport('disable-woodmart-single-heavy-options.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
