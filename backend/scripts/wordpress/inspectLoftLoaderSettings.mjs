import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function findPluginLinks(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/plugins.php?plugin_status=active`);

  return page.evaluate(() => {
    const rows = Array.from(document.querySelectorAll('tr[data-plugin]'));
    const row = rows.find((item) => item.getAttribute('data-plugin') === 'loftloader/loftloader.php');
    if (!row) return null;

    const links = Array.from(row.querySelectorAll('a')).map((link) => ({
      text: (link.textContent || '').replace(/\s+/g, ' ').trim(),
      href: link.href || '',
    }));

    return {
      title:
        row.querySelector('.plugin-title strong')?.textContent?.trim() ||
        row.querySelector('strong')?.textContent?.trim() ||
        '',
      links,
    };
  });
}

async function inspectPage(page, url) {
  await goto(page, url);

  return page.evaluate(() => {
    const fields = Array.from(document.querySelectorAll('input, select, textarea'))
      .map((field) => {
        const row = field.closest('tr, .form-field, .option-row, .redux-field, .cmb-row, .field, .inside') || field.parentElement;
        const context = (row?.textContent || field.closest('form')?.textContent || '')
          .replace(/\s+/g, ' ')
          .trim();

        return {
          tag: field.tagName.toLowerCase(),
          type: field.getAttribute('type') || '',
          name: field.getAttribute('name') || '',
          id: field.id || '',
          value: field.value || '',
          checked: field instanceof HTMLInputElement ? field.checked : false,
          context: context.slice(0, 500),
        };
      })
      .filter((field) => /logo|image|background|loader|animation|effect|duration|color/i.test(field.context));

    const links = Array.from(document.querySelectorAll('a'))
      .map((link) => ({
        text: (link.textContent || '').replace(/\s+/g, ' ').trim(),
        href: link.href || '',
      }))
      .filter((item) => /logo|image|background|loader|animation|effect|settings/i.test(`${item.text} ${item.href}`))
      .slice(0, 100);

    return {
      url: location.href,
      title: document.title,
      bodyPreview: (document.body?.innerText || '').slice(0, 20000),
      fields,
      links,
    };
  });
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const pluginLinks = await findPluginLinks(page, config);

    const candidateUrls = [
      ...(pluginLinks?.links || []).map((item) => item.href).filter(Boolean),
      `${config.baseUrl}/wp-admin/options-general.php?page=loftloader-lite`,
      `${config.baseUrl}/wp-admin/admin.php?page=loftloader-lite`,
      `${config.baseUrl}/wp-admin/themes.php?page=loftloader-lite`,
      `${config.baseUrl}/wp-admin/admin.php?page=loftloader`,
      `${config.baseUrl}/wp-admin/options-general.php?page=loftloader`,
    ];

    const visited = [];
    for (const url of Array.from(new Set(candidateUrls))) {
      try {
        const snapshot = await inspectPage(page, url);
        visited.push(snapshot);
      } catch (error) {
        visited.push({
          url,
          error: error.message || String(error),
        });
      }
    }

    const report = {
      updatedAt: new Date().toISOString(),
      pluginLinks,
      visited,
    };

    writeReport('inspect-loftloader-settings.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
