import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

function normalizeText(value) {
  return String(value || '')
    .replace(/\s+/g, ' ')
    .trim();
}

async function capturePage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);

  return page.evaluate(() => {
    const rows = Array.from(document.querySelectorAll('tr, .form-group, .cmb-row, .pys-option, .pys-field'));

    const matches = rows
      .map((row) => {
        const text = (row.textContent || '').replace(/\s+/g, ' ').trim();
        if (!/session|cookie/i.test(text)) {
          return null;
        }

        const inputs = Array.from(row.querySelectorAll('input, select, textarea')).map((input) => ({
          tag: input.tagName.toLowerCase(),
          type: input.getAttribute('type') || '',
          name: input.getAttribute('name') || '',
          id: input.id || '',
          value: input.value || '',
          checked: input instanceof HTMLInputElement ? input.checked : false,
        }));

        return {
          text,
          inputs,
        };
      })
      .filter(Boolean);

    return {
      url: location.href,
      title: document.title,
      bodyPreview: (document.body?.innerText || '').slice(0, 12000),
      matches,
      links: Array.from(document.querySelectorAll('a'))
        .map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href,
        }))
        .filter((item) => /session|cookie/i.test(item.text))
        .slice(0, 50),
    };
  });
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const dashboard = await capturePage(page, config, 'admin.php?page=pixelyoursite');
    const globalSettings = await capturePage(page, config, 'admin.php?page=pixelyoursite_settings');

    const report = {
      updatedAt: new Date().toISOString(),
      dashboard: {
        url: dashboard.url,
        title: dashboard.title,
        matches: dashboard.matches,
        bodyPreview: dashboard.bodyPreview,
      },
      globalSettings: {
        url: globalSettings.url,
        title: globalSettings.title,
        matches: globalSettings.matches,
        bodyPreview: globalSettings.bodyPreview,
      },
    };

    writeReport('inspect-pixelyoursite-settings.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
