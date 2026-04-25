import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function fetchPublicHeaders(url) {
  const response = await fetch(url, {
    method: 'GET',
    redirect: 'follow',
    headers: {
      'user-agent': 'Codex Session Probe',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
    },
  });

  return {
    url: response.url,
    status: response.status,
    setCookie: response.headers.get('set-cookie') || '',
    cacheControl: response.headers.get('cache-control') || '',
    pragma: response.headers.get('pragma') || '',
    cfCacheStatus: response.headers.get('cf-cache-status') || '',
    liteSpeedCacheControl: response.headers.get('x-litespeed-cache-control') || '',
  };
}

async function gotoPlugins(page, config, status = 'active') {
  await page.goto(`${config.baseUrl}/wp-admin/plugins.php?plugin_status=${status}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function findPlugin(page, config, pluginFile, status = 'active') {
  await gotoPlugins(page, config, status);

  return page.evaluate(
    (needle) =>
      Array.from(document.querySelectorAll('tr[data-plugin]'))
        .map((row) => ({
          plugin: row.getAttribute('data-plugin') || '',
          title:
            row.querySelector('.plugin-title strong')?.textContent?.trim() ||
            row.querySelector('strong')?.textContent?.trim() ||
            '',
          deactivateHref: row.querySelector('.deactivate a')?.href || '',
          activateHref: row.querySelector('.activate a')?.href || '',
        }))
        .find((item) => item.plugin === needle) || null,
    pluginFile
  );
}

async function purgeCaches(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/index.php`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);

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
  const pluginFile = process.env.WP_PROBE_PLUGIN || 'myrewards-display.php';

  try {
    await loginToWordPress(page, config);

    const beforePlugin = await findPlugin(page, config, pluginFile, 'active');
    const beforeHeaders = await fetchPublicHeaders(config.baseUrl + '/');

    let deactivated = false;
    let deactivationNotice = null;
    if (beforePlugin?.deactivateHref) {
      await page.goto(beforePlugin.deactivateHref, {
        waitUntil: 'domcontentloaded',
        timeout: 60000,
      });
      await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
      await page.waitForTimeout(1200);
      deactivated = !(await findPlugin(page, config, pluginFile, 'active'));
      deactivationNotice = await page.evaluate(() =>
        Array.from(document.querySelectorAll('.notice, #message')).map((node) =>
          (node.textContent || '').replace(/\s+/g, ' ').trim()
        )
      );
    }

    const purgesAfterDeactivate = deactivated ? await purgeCaches(page, config) : [];
    const whileDisabledHeaders = deactivated ? await fetchPublicHeaders(config.baseUrl + '/') : null;

    let reactivated = false;
    let afterPlugin = null;
    if (deactivated) {
      const inactivePlugin = await findPlugin(page, config, pluginFile, 'inactive');
      if (inactivePlugin?.activateHref) {
        await page.goto(inactivePlugin.activateHref, {
          waitUntil: 'domcontentloaded',
          timeout: 60000,
        });
        await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
        await page.waitForTimeout(1200);
        afterPlugin = await findPlugin(page, config, pluginFile, 'active');
        reactivated = !!afterPlugin;
      }
    }

    const purgesAfterReactivate = reactivated ? await purgeCaches(page, config) : [];
    const restoredHeaders = reactivated ? await fetchPublicHeaders(config.baseUrl + '/') : null;

    const report = {
      updatedAt: new Date().toISOString(),
      pluginFile,
      beforePlugin,
      beforeHeaders,
      deactivated,
      deactivationNotice,
      purgesAfterDeactivate,
      whileDisabledHeaders,
      reactivated,
      afterPlugin,
      purgesAfterReactivate,
      restoredHeaders,
    };

    writeReport('probe-plugin-session-impact.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
