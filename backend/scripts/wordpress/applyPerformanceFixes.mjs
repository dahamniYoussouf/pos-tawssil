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

async function collectActivePlugins(page, config) {
  await gotoAdminPage(page, config, 'plugins.php?plugin_status=active');

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
      settingsHref: row.querySelector('.settings a')?.href || '',
    }))
  );
}

async function deactivatePlugin(page, config, matcher) {
  const plugins = await collectActivePlugins(page, config);
  const plugin = plugins.find((item) => matcher(item));

  if (!plugin) {
    return {
      changed: false,
      status: 'not_found',
    };
  }

  if (!plugin.active || !plugin.deactivateHref) {
    return {
      changed: false,
      status: 'already_inactive_or_missing_link',
      plugin,
    };
  }

  await page.goto(plugin.deactivateHref, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);

  const pluginsAfter = await collectActivePlugins(page, config);
  const stillActive = pluginsAfter.some(
    (item) =>
      (plugin.plugin && item.plugin === plugin.plugin) ||
      (plugin.slug && item.slug === plugin.slug) ||
      normalizeText(item.title) === normalizeText(plugin.title)
  );

  return {
    changed: !stillActive,
    status: stillActive ? 'deactivation_failed' : 'deactivated',
    plugin,
  };
}

async function setOptionByLabel(page, labelNeedle, targetValue) {
  return page.evaluate(
    ({ labelNeedle: rawLabelNeedle, targetValue: rawTargetValue }) => {
      const needle = String(rawLabelNeedle || '')
        .toLowerCase()
        .replace(/\s+/g, ' ')
        .trim();
      const targetValue = String(rawTargetValue);
      const rows = Array.from(
        document.querySelectorAll(
          'tr, .litespeed-row, .litespeed-trow, .lsws-setting-row, .lsws-settings-line, .form-table > tbody > tr'
        )
      );

      const readValue = (row) => {
        const checkedRadio = row.querySelector('input[type="radio"]:checked');
        if (checkedRadio) return checkedRadio.value;

        const checkbox = row.querySelector('input[type="checkbox"]');
        if (checkbox) return checkbox.checked ? '1' : '0';

        const select = row.querySelector('select');
        if (select) return select.value;

        return '';
      };

      const findLabel = (row) => {
        const parts = [
          row.querySelector('th')?.textContent || '',
          row.querySelector('label')?.textContent || '',
          row.querySelector('.litespeed-label')?.textContent || '',
          row.querySelector('.lsws-label')?.textContent || '',
        ];
        return parts.join(' ').replace(/\s+/g, ' ').trim();
      };

      const row = rows.find((item) => findLabel(item).toLowerCase().includes(needle));
      if (!row) {
        return {
          found: false,
          label: rawLabelNeedle,
        };
      }

      const label = findLabel(row);
      const before = readValue(row);
      let changed = false;
      let controlType = '';

      const radio = row.querySelector(`input[type="radio"][value="${CSS.escape(targetValue)}"]`);
      if (radio) {
        controlType = 'radio';
        if (!radio.checked) {
          radio.click();
          radio.dispatchEvent(new Event('change', { bubbles: true }));
          radio.dispatchEvent(new Event('input', { bubbles: true }));
          changed = true;
        }
      } else {
        const checkbox = row.querySelector('input[type="checkbox"]');
        if (checkbox) {
          controlType = 'checkbox';
          const shouldCheck = targetValue === '1';
          if (checkbox.checked !== shouldCheck) {
            checkbox.click();
            checkbox.dispatchEvent(new Event('change', { bubbles: true }));
            checkbox.dispatchEvent(new Event('input', { bubbles: true }));
            changed = true;
          }
        } else {
          const select = row.querySelector('select');
          if (select) {
            controlType = 'select';
            if (select.value !== targetValue) {
              select.value = targetValue;
              select.dispatchEvent(new Event('change', { bubbles: true }));
              select.dispatchEvent(new Event('input', { bubbles: true }));
              changed = true;
            }
          }
        }
      }

      return {
        found: true,
        label,
        before,
        after: readValue(row),
        changed,
        controlType,
      };
    },
    { labelNeedle, targetValue }
  );
}

async function clickSaveSettings(page) {
  const clicked = await page.evaluate(() => {
    const isVisible = (node) => {
      if (!(node instanceof HTMLElement)) return false;
      const style = window.getComputedStyle(node);
      return style.display !== 'none' && style.visibility !== 'hidden' && node.offsetParent !== null;
    };

    const candidates = Array.from(
      document.querySelectorAll('button, input[type="submit"], input.button-primary, button.button-primary')
    );

    const target =
      candidates.find((node) => {
        if (!isVisible(node)) return false;
        const text = `${node.textContent || ''} ${node.getAttribute('value') || ''}`
          .toLowerCase()
          .replace(/\s+/g, ' ')
          .trim();
        return (
          text.includes('save') ||
          text.includes('enregistrer') ||
          text.includes('mettre à jour') ||
          text.includes('submit')
        );
      }) || null;

    if (!target) {
      return {
        clicked: false,
      };
    }

    target.click();

    return {
      clicked: true,
      tag: target.tagName.toLowerCase(),
      text: `${target.textContent || ''} ${target.getAttribute('value') || ''}`.replace(/\s+/g, ' ').trim(),
      id: target.id || '',
      name: target.getAttribute('name') || '',
    };
  });

  if (!clicked.clicked) {
    return clicked;
  }

  await page.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => null);
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2500);

  return clicked;
}

async function applyLiteSpeedSettings(page, config, adminPath, options) {
  await gotoAdminPage(page, config, adminPath);

  const updates = [];
  for (const option of options) {
    updates.push(await setOptionByLabel(page, option.label, option.value));
  }

  const changed = updates.some((item) => item.changed);
  const save = changed ? await clickSaveSettings(page) : { clicked: false, reason: 'no_changes' };

  return {
    adminPath,
    updates,
    changed,
    save,
  };
}

async function applyOptionalGuestSettings(page, config) {
  const attempts = [];

  for (const adminPath of ['admin.php?page=litespeed-general', 'admin.php?page=litespeed-cache']) {
    await gotoAdminPage(page, config, adminPath);

    for (const label of ['Mode invité', 'Optimisation invité', 'Guest Mode', 'Guest Optimization']) {
      attempts.push({
        adminPath,
        label,
        result: await setOptionByLabel(page, label, '1'),
      });
    }

    if (attempts.some((item) => item.adminPath === adminPath && item.result.changed)) {
      attempts.push({
        adminPath,
        label: '__save__',
        result: await clickSaveSettings(page),
      });
    }
  }

  return attempts;
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

  return {
    cleared: used.length > 0,
    actions: used,
  };
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const pluginChanges = {
      queryMonitor: await deactivatePlugin(
        page,
        config,
        (plugin) =>
          normalizeText(plugin.title).includes('query monitor') ||
          plugin.slug === 'query-monitor' ||
          plugin.plugin === 'query-monitor/query-monitor.php'
      ),
      loftLoader: await deactivatePlugin(
        page,
        config,
        (plugin) =>
          normalizeText(plugin.title).includes('loftloader') ||
          plugin.slug === 'loftloader' ||
          plugin.plugin === 'loftloader/loftloader.php'
      ),
    };

    const cacheSettings = await applyLiteSpeedSettings(page, config, 'admin.php?page=litespeed-cache', [
      { label: 'Servir le périmé', value: '1' },
      // Keep Instant Click disabled until the public asset is reliably served as JavaScript.
      { label: 'Clic instantané', value: '0' },
    ]);

    const pageOptimizationSettings = await applyLiteSpeedSettings(
      page,
      config,
      'admin.php?page=litespeed-page_optm',
      [
        { label: 'Chargement différé des images', value: '1' },
        { label: 'Chargement différé des iframes', value: '1' },
        { label: 'Ajouter les dimensions manquantes', value: '1' },
      ]
    );

    const guestSettings = await applyOptionalGuestSettings(page, config);
    const cachePurge = await purgeAllCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      pluginChanges,
      cacheSettings,
      pageOptimizationSettings,
      guestSettings,
      cachePurge,
    };

    writeReport('apply-performance-fixes.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
