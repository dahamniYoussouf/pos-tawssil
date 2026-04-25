import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

async function gotoPlugins(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/plugins.php?plugin_status=active`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectPluginRow(page, matcher) {
  return page.evaluate((matcherSource) => {
    const normalize = (value) =>
      String(value || '')
        .toLowerCase()
        .replace(/\s+/g, ' ')
        .trim();

    const matcher = new Function(`return (${matcherSource});`)();
    const rows = Array.from(document.querySelectorAll('tr[data-slug]'));
    const items = rows.map((row) => ({
      slug: row.getAttribute('data-slug') || '',
      plugin: row.getAttribute('data-plugin') || '',
      title:
        row.querySelector('.plugin-title strong')?.textContent?.trim() ||
        row.querySelector('strong')?.textContent?.trim() ||
        '',
      active: row.classList.contains('active'),
      deactivateHref: row.querySelector('.deactivate a')?.href || '',
      rowText: normalize(row.textContent || ''),
    }));

    return items.find((item) => matcher(item, normalize)) || null;
  }, matcher.toString());
}

async function attemptDeactivate(page, target) {
  await page.goto(target.deactivateHref, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);

  return page.evaluate(() => ({
    url: location.href,
    title: document.title,
    notices: Array.from(document.querySelectorAll('.notice, #message, .updated, .error')).map((node) =>
      (node.textContent || '').replace(/\s+/g, ' ').trim()
    ),
    bodyPreview: (document.body?.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 4000),
  }));
}

async function inspectTarget(page, config, matcher) {
  await gotoPlugins(page, config);
  const before = await collectPluginRow(page, matcher);

  if (!before?.deactivateHref) {
    return { before, deactivateAttempt: null, after: before };
  }

  const deactivateAttempt = await attemptDeactivate(page, before);
  await gotoPlugins(page, config);
  const after = await collectPluginRow(page, matcher);

  return {
    before,
    deactivateAttempt,
    after,
  };
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const queryMonitor = await inspectTarget(
      page,
      config,
      (item, normalize) =>
        normalize(item.title).includes('query monitor') ||
        item.slug === 'query-monitor' ||
        item.plugin === 'query-monitor/query-monitor.php'
    );

    const loftLoader = await inspectTarget(
      page,
      config,
      (item, normalize) =>
        normalize(item.title).includes('loftloader') ||
        item.slug === 'loftloader' ||
        item.plugin === 'loftloader/loftloader.php'
    );

    const report = {
      updatedAt: new Date().toISOString(),
      queryMonitor,
      loftLoader,
    };

    writeReport('inspect-plugin-deactivation.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
