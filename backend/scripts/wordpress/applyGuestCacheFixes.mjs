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

async function gotoAdminPage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function fetchPublicHeaders(url) {
  const response = await fetch(url, {
    method: 'GET',
    redirect: 'follow',
    headers: {
      'user-agent': 'Codex Guest Cache Fix',
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

async function setCheckboxByContextText(page, needle, desiredChecked) {
  return page.evaluate(
    ({ rawNeedle, desiredChecked }) => {
      const normalize = (value) =>
        String(value || '')
          .toLowerCase()
          .replace(/\s+/g, ' ')
          .trim();

      const needle = normalize(rawNeedle);
      const inputs = Array.from(document.querySelectorAll('input[type="checkbox"]'));

      const scored = inputs
        .map((input) => {
          const contexts = [];
          let current = input;
          for (let depth = 0; current && depth < 6; depth += 1) {
            current = current.parentElement;
            if (!current) break;
            contexts.push({
              depth: depth + 1,
              text: normalize(current.textContent),
              html: current.outerHTML?.slice(0, 800) || '',
            });
          }

          const best = contexts.find((item) => item.text.includes(needle)) || null;
          if (!best) return null;

          return {
            input,
            score: 100 - best.depth,
            contextText: best.text,
          };
        })
        .filter(Boolean)
        .sort((left, right) => right.score - left.score);

      const target = scored[0];
      if (!target) {
        return {
          found: false,
          changed: false,
        };
      }

      const input = target.input;
      const before = !!input.checked;

      if (before !== desiredChecked) {
        input.click();
        input.dispatchEvent(new Event('change', { bubbles: true }));
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }

      return {
        found: true,
        changed: before !== desiredChecked,
        before,
        after: !!input.checked,
        name: input.name || '',
        id: input.id || '',
        contextText: target.contextText.slice(0, 500),
      };
    },
    { rawNeedle: needle, desiredChecked }
  );
}

async function clickSaveSettings(page) {
  const result = await page.evaluate(() => {
    const normalize = (value) =>
      String(value || '')
        .toLowerCase()
        .replace(/\s+/g, ' ')
        .trim();

    const isVisible = (node) => {
      if (!(node instanceof HTMLElement)) return false;
      const style = window.getComputedStyle(node);
      return style.display !== 'none' && style.visibility !== 'hidden' && node.offsetParent !== null;
    };

    const candidates = Array.from(
      document.querySelectorAll('button, input[type="submit"], input.button-primary, button.button-primary')
    );

    const button =
      candidates.find((node) => {
        if (!isVisible(node)) return false;
        const text = normalize(`${node.textContent || ''} ${node.getAttribute('value') || ''}`);
        return text.includes('save changes') || text.includes('save') || text.includes('enregistrer');
      }) || null;

    if (!button) {
      return { clicked: false };
    }

    const text = `${button.textContent || ''} ${button.getAttribute('value') || ''}`.replace(/\s+/g, ' ').trim();
    button.click();
    return {
      clicked: true,
      text,
      tag: button.tagName.toLowerCase(),
      id: button.id || '',
      name: button.getAttribute('name') || '',
    };
  });

  if (!result.clicked) {
    return result;
  }

  await page.waitForLoadState('domcontentloaded', { timeout: 30000 }).catch(() => null);
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2500);

  return result;
}

async function purgeCaches(page, config) {
  await gotoAdminPage(page, config, 'index.php');

  const targets = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href || '',
      }))
      .filter((item) => item.href)
  );

  const relevant = targets.filter((item) => {
    const text = normalizeText(`${item.text} ${item.href}`);
    return (
      text.includes('purge all lscache') ||
      text.includes('tout purger - lscache') ||
      text.includes('purge all css') ||
      text.includes('tout purger - cache css/js') ||
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

  try {
    await loginToWordPress(page, config);

    const before = {
      home: await fetchPublicHeaders(`${config.baseUrl}/`),
      category: await fetchPublicHeaders(`${config.baseUrl}/categorie/outillage-a-main/`),
    };

    await gotoAdminPage(page, config, 'admin.php?page=pixelyoursite_settings');
    const disablePhpSessions = await setCheckboxByContextText(page, 'disable php sessions', true);
    const save = disablePhpSessions.changed ? await clickSaveSettings(page) : { clicked: false, reason: 'no_changes' };
    const purge = await purgeCaches(page, config);

    const after = {
      home: await fetchPublicHeaders(`${config.baseUrl}/`),
      category: await fetchPublicHeaders(`${config.baseUrl}/categorie/outillage-a-main/`),
    };

    const report = {
      updatedAt: new Date().toISOString(),
      before,
      disablePhpSessions,
      save,
      purge,
      after,
    };

    writeReport('apply-guest-cache-fixes.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
