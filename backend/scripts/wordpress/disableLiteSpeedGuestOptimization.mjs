import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function goto(page, url) {
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function toggleByLabel(page, patterns, desired = false) {
  return page.evaluate(
    ({ patterns, desired }) => {
      const matches = [];
      const patternRegexes = patterns.map((p) => new RegExp(p, 'i'));

      function labelMatches(text) {
        return patternRegexes.some((re) => re.test(text));
      }

      const rows = Array.from(
        document.querySelectorAll(
          'tr, .litespeed-row, .litespeed-trow, .lsws-setting-row, .lsws-settings-line, .form-table > tbody > tr'
        )
      );

      for (const row of rows) {
        const text = (row.textContent || '').replace(/\s+/g, ' ').trim();
        if (!labelMatches(text)) continue;

        const checkedRadio = row.querySelector('input[type="radio"]:checked');
        if (checkedRadio) {
          const target = row.querySelector(`input[type="radio"][value="${desired ? '1' : '0'}"]`);
          const before = checkedRadio.value;
          if (target && !target.checked) {
            target.click();
            target.dispatchEvent(new Event('change', { bubbles: true }));
          }
          matches.push({
            label: text.slice(0, 160),
            type: 'radio',
            before,
            after: row.querySelector('input[type="radio"]:checked')?.value || '',
          });
          continue;
        }

        const checkbox = row.querySelector('input[type="checkbox"]');
        if (checkbox) {
          const before = checkbox.checked;
          if (before !== desired) {
            checkbox.click();
            checkbox.dispatchEvent(new Event('change', { bubbles: true }));
          }
          matches.push({
            label: text.slice(0, 160),
            type: 'checkbox',
            before: before ? '1' : '0',
            after: checkbox.checked ? '1' : '0',
          });
        }
      }

      return matches;
    },
    { patterns, desired }
  );
}

async function saveSettings(page) {
  const button = page.locator('button[name="litespeed_save"], input[type="submit"][name="litespeed_save"]').first();
  if ((await button.count()) > 0) {
    await button.click();
  } else {
    await page.locator('input[type="submit"], button[type="submit"]').first().click();
  }
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);
}

async function purgeCaches(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/index.php`);

  const actions = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href || '',
      }))
      .filter((item) => {
        const haystack = `${item.text} ${item.href}`.toLowerCase();
        return (
          haystack.includes('purge all') ||
          haystack.includes('tout purger - lscache') ||
          haystack.includes('tout purger - cache css/js') ||
          haystack.includes('tout purger - cloudflare')
        );
      })
  );

  const used = [];
  for (const action of actions) {
    if (!action.href) continue;
    await goto(page, action.href);
    used.push(action);
  }

  return used;
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=litespeed-cache&tab=cache`);
    const cacheChanges = [
      ...(await toggleByLabel(page, ['Guest Mode', 'Mode invit'], false)),
      ...(await toggleByLabel(page, ['Guest Optimization', 'Optimisation invit'], false)),
    ];
    await saveSettings(page);

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=litespeed-page_optm`);
    const pageOptChanges = [
      ...(await toggleByLabel(page, ['Delay JS', 'Retarder JS', 'Reporter JS', 'JS différ'], false)),
      ...(await toggleByLabel(page, ['Defer JS', 'Différer JS'], false)),
    ];
    if (pageOptChanges.length > 0) {
      await saveSettings(page);
    }

    const purges = await purgeCaches(page, config);
    const report = {
      updatedAt: new Date().toISOString(),
      cacheChanges,
      pageOptChanges,
      purges,
    };

    writeReport('disable-litespeed-guest-optimization.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
