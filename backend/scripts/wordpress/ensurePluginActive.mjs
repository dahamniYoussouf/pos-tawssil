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
      'user-agent': 'Codex Ensure Plugin Active',
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
    liteSpeedCache: response.headers.get('x-litespeed-cache') || '',
  };
}

async function gotoPlugins(page, config, status) {
  await page.goto(`${config.baseUrl}/wp-admin/plugins.php?plugin_status=${status}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function findPlugin(page, config, pluginFile, status) {
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
          activateHref: row.querySelector('.activate a')?.href || '',
          deactivateHref: row.querySelector('.deactivate a')?.href || '',
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
  const pluginFile = process.env.WP_PLUGIN_FILE || 'loftloader/loftloader.php';
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const beforeHeaders = {
      home: await fetchPublicHeaders(`${config.baseUrl}/`),
      category: await fetchPublicHeaders(`${config.baseUrl}/categorie/outillage-a-main/`),
    };

    const activeBefore = await findPlugin(page, config, pluginFile, 'active');
    let activation = {
      changed: false,
      status: activeBefore ? 'already_active' : 'not_found',
      plugin: activeBefore,
    };

    if (!activeBefore) {
      const inactivePlugin = await findPlugin(page, config, pluginFile, 'inactive');

      if (inactivePlugin?.activateHref) {
        await page.goto(inactivePlugin.activateHref, {
          waitUntil: 'domcontentloaded',
          timeout: 60000,
        });
        await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
        await page.waitForTimeout(1500);

        const activeAfter = await findPlugin(page, config, pluginFile, 'active');
        activation = {
          changed: !!activeAfter,
          status: activeAfter ? 'activated' : 'activation_failed',
          plugin: activeAfter || inactivePlugin,
        };
      }
    }

    const purges = await purgeCaches(page, config);
    const afterHeaders = {
      home: await fetchPublicHeaders(`${config.baseUrl}/`),
      category: await fetchPublicHeaders(`${config.baseUrl}/categorie/outillage-a-main/`),
    };

    const report = {
      updatedAt: new Date().toISOString(),
      pluginFile,
      activation,
      purges,
      beforeHeaders,
      afterHeaders,
    };

    writeReport('ensure-plugin-active.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
