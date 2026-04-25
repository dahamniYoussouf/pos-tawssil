import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const outDir = path.resolve('backend/scripts/wordpress/out');

async function gotoAdminPage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
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
      return { clicked: false };
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
    await gotoAdminPage(page, config, 'admin.php?page=litespeed-page_optm');

    const updates = [
      await setOptionByLabel(page, 'Chargement différé des images', '0'),
      await setOptionByLabel(page, 'Lazy Load Images', '0'),
      await setOptionByLabel(page, 'Image WebP Replacement', '1'),
      await setOptionByLabel(page, 'Remplacement WebP des images', '1'),
      await setOptionByLabel(page, 'Ajouter les dimensions manquantes', '1'),
      await setOptionByLabel(page, 'Add Missing Sizes', '1'),
    ];

    const changed = updates.some((item) => item.changed);
    const save = changed ? await clickSaveSettings(page) : { clicked: false, reason: 'no_changes' };
    const purge = await purgeAllCaches(page, config);

    const report = {
      updatedAt: new Date().toISOString(),
      page: 'litespeed-page_optm',
      updates,
      changed,
      save,
      purge,
    };

    writeReport('disable-litespeed-image-lazyload.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
