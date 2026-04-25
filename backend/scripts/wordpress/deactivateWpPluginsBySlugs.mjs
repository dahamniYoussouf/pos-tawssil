import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const outDir = path.resolve('backend/scripts/wordpress/out');

function normalizeText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

async function gotoAdminPage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectPlugins(page, config, status = 'active') {
  await gotoAdminPage(page, config, `plugins.php?plugin_status=${status}`);

  return page.evaluate(() =>
    Array.from(document.querySelectorAll('tr[data-slug]')).map((row) => ({
      slug: row.getAttribute('data-slug') || '',
      plugin: row.getAttribute('data-plugin') || '',
      title:
        row.querySelector('.plugin-title strong')?.textContent?.trim() ||
        row.querySelector('strong')?.textContent?.trim() ||
        '',
      active: row.classList.contains('active'),
      deactivateHref: row.querySelector('.deactivate a')?.href || '',
      activateHref: row.querySelector('.activate a')?.href || '',
    }))
  );
}

async function purgeAllCaches(page, config) {
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

async function deactivateBySlug(page, config, slug) {
  const activePlugins = await collectPlugins(page, config, 'active');
  const target = activePlugins.find(
    (plugin) => plugin.slug === slug || normalizeText(plugin.title) === normalizeText(slug)
  );

  if (!target) {
    return {
      slug,
      status: 'not_found_or_inactive',
      changed: false,
    };
  }

  if (!target.deactivateHref) {
    return {
      slug,
      status: 'missing_deactivate_link',
      changed: false,
      plugin: target,
    };
  }

  await page.goto(target.deactivateHref, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);

  const attempt = await page.evaluate(() => ({
    url: location.href,
    title: document.title,
    notices: Array.from(document.querySelectorAll('.notice, #message, .updated, .error')).map((node) =>
      (node.textContent || '').replace(/\s+/g, ' ').trim()
    ),
    bodyPreview: (document.body?.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 2500),
  }));

  const stillActive = (await collectPlugins(page, config, 'active')).some(
    (plugin) =>
      plugin.slug === target.slug ||
      plugin.plugin === target.plugin ||
      normalizeText(plugin.title) === normalizeText(target.title)
  );

  return {
    slug,
    status: stillActive ? 'deactivation_failed' : 'deactivated',
    changed: !stillActive,
    plugin: target,
    attempt,
  };
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const targetSlugs = String(process.env.WP_PLUGIN_SLUGS || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  if (!targetSlugs.length) {
    throw new Error('Missing WP_PLUGIN_SLUGS. Provide a comma-separated slug list.');
  }

  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const results = [];
    for (const slug of targetSlugs) {
      results.push(await deactivateBySlug(page, config, slug));
    }

    const purgeActions = await purgeAllCaches(page, config);
    const report = {
      updatedAt: new Date().toISOString(),
      targetSlugs,
      results,
      purgeActions,
    };

    writeReport('deactivate-wp-plugins-by-slugs.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
