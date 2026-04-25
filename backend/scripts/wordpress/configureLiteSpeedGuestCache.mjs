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

async function toggleByLabel(page, patterns, desired = true) {
  return page.evaluate(
    ({ patterns, desired }) => {
      const matches = [];
      const patternRegexes = patterns.map((p) => new RegExp(p, 'i'));

      function labelMatches(text) {
        return patternRegexes.some((re) => re.test(text));
      }

      const rows = Array.from(document.querySelectorAll('tr, .litespeed-row, .form-table tr'));
      for (const row of rows) {
        const text = (row.textContent || '').replace(/\s+/g, ' ').trim();
        if (!labelMatches(text)) continue;
        const input =
          row.querySelector('input[type="checkbox"]') ||
          row.querySelector('input[type="radio"]') ||
          row.querySelector('select') ||
          null;
        if (!input) continue;

        if (input instanceof HTMLInputElement && input.type === 'checkbox') {
          const before = input.checked;
          if (before !== desired) {
            input.click();
          }
          matches.push({ label: text.slice(0, 120), type: 'checkbox', before, after: input.checked });
        } else if (input instanceof HTMLSelectElement) {
          const before = input.value;
          const option = Array.from(input.options).find((opt) => /on|yes|enabled|actif|activ/i.test(opt.textContent || ''));
          if (desired && option) {
            input.value = option.value;
            input.dispatchEvent(new Event('change', { bubbles: true }));
          }
          matches.push({ label: text.slice(0, 120), type: 'select', before, after: input.value });
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

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=litespeed-cache&tab=cache`);

    const changes = [];
    changes.push(
      ...(await toggleByLabel(page, [
        'Guest Mode',
        'Mode invit',
      ], true))
    );
    changes.push(
      ...(await toggleByLabel(page, [
        'Guest Optimization',
        'Optimisation invit',
      ], true))
    );
    changes.push(
      ...(await toggleByLabel(page, [
        'Cache Mobile',
        'Mobile Cache',
      ], true))
    );
    changes.push(
      ...(await toggleByLabel(page, [
        'Separate Cache',
        'Cache mobile sépar',
        'Separate Cache',
      ], true))
    );

    await saveSettings(page);

    const report = {
      updatedAt: new Date().toISOString(),
      url: page.url(),
      changes,
    };

    writeReport('configure-litespeed-guest-cache.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
