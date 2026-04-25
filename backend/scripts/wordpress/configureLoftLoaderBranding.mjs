import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const DEFAULT_LOGO_URL = 'https://gamaoutillage.net/wp-content/uploads/2024/12/Logo-Gama-Outillage.png';

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2000);
}

async function setCustomizerSettings(page, nextValues) {
  return page.evaluate((entries) => {
    const api = window.wp?.customize;
    if (!api) {
      return {
        error: 'wp.customize not found',
      };
    }

    const changes = [];

    for (const [id, next] of Object.entries(entries)) {
      const control =
        (api.control && typeof api.control.instance === 'function' ? api.control.instance(id) : null) ||
        (typeof api.control === 'function' ? api.control(id) : null);
      const setting =
        control?.setting ||
        (typeof api.instance === 'function' ? api.instance(id) : null) ||
        (typeof api === 'function' ? api(id) : null);

      if (!setting) {
        changes.push({
          id,
          found: false,
          viaControl: !!control,
        });
        continue;
      }

      const before = setting.get();
      const changed = String(before) !== String(next);
      if (changed) {
        setting.set(next);
      }

      changes.push({
        id,
        found: true,
        viaControl: !!control,
        before,
        after: setting.get(),
        changed,
      });
    }

    return { changes };
  }, nextValues);
}

async function publishCustomizer(page) {
  const clicked = await page.evaluate(() => {
    const button = document.querySelector('#save');
    if (!(button instanceof HTMLButtonElement)) {
      return {
        clicked: false,
      };
    }

    const disabledBefore = button.disabled;
    if (button.disabled) {
      button.disabled = false;
    }

    button.click();

    return {
      clicked: true,
      text: (button.textContent || '').replace(/\s+/g, ' ').trim(),
      disabledBefore,
    };
  });

  if (!clicked.clicked) {
    return clicked;
  }

  await page
    .waitForFunction(
      () => {
        const button = document.querySelector('#save');
        return button && /publi|published|saved/i.test((button.textContent || '').trim());
      },
      null,
      { timeout: 30000 }
    )
    .catch(() => null);
  await page.waitForTimeout(2500);

  const finalState = await page.evaluate(() => ({
    saveText: (document.querySelector('#save')?.textContent || '').replace(/\s+/g, ' ').trim(),
    notice: Array.from(document.querySelectorAll('.notice, .customize-action-notifications li, .accordion-section-notice'))
      .map((node) => (node.textContent || '').replace(/\s+/g, ' ').trim())
      .filter(Boolean)
      .slice(0, 20),
  }));

  return {
    ...clicked,
    ...finalState,
  };
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

async function fetchPublicHeaders(url) {
  const response = await fetch(url, {
    method: 'GET',
    redirect: 'follow',
    headers: {
      'user-agent': 'Codex LoftLoader Branding',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
    },
  });

  return {
    url: response.url,
    status: response.status,
    setCookie: response.headers.get('set-cookie') || '',
    cacheControl: response.headers.get('cache-control') || '',
    cfCacheStatus: response.headers.get('cf-cache-status') || '',
    liteSpeedCache: response.headers.get('x-litespeed-cache') || '',
    liteSpeedCacheControl: response.headers.get('x-litespeed-cache-control') || '',
  };
}

async function main() {
  const config = resolveSyncConfig();
  const logoUrl = process.env.WP_LOFTLOADER_LOGO_URL || DEFAULT_LOGO_URL;
  const logoWidth = process.env.WP_LOFTLOADER_LOGO_WIDTH || '320';
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await goto(
      page,
      `${config.baseUrl}/wp-admin/customize.php?return=%2Fwp-admin%2Fplugins.php%3Fplugin_status%3Dactive&plugin=loftloader-lite`
    );
    await page
      .waitForFunction(
        () =>
          !!(
            window.wp?.customize &&
            window.wp.customize.control &&
            typeof window.wp.customize.control.each === 'function' &&
            (() => {
              let found = false;
              window.wp.customize.control.each((control) => {
                if (control?.id === 'loftloader_loader_type') {
                  found = true;
                }
              });
              return found;
            })()
          ),
        null,
        { timeout: 30000 }
      )
      .catch(() => null);

    const settings = {
      loftloader_main_switch: 'on',
      loftloader_bg_color: '#ffffff',
      loftloader_bg_opacity: '100',
      loftloader_bg_animation: 'fade',
      loftloader_loader_type: 'imgloading',
      loftloader_loader_color: '#1f77b8',
      loftloader_custom_img: logoUrl,
      loftloader_img_width: String(logoWidth),
    };

    const apply = await setCustomizerSettings(page, settings);
    const publish = await publishCustomizer(page);
    const purge = await purgeCaches(page, config);
    const headers = {
      home: await fetchPublicHeaders(`${config.baseUrl}/`),
      category: await fetchPublicHeaders(`${config.baseUrl}/categorie/outillage-a-main/`),
    };

    const report = {
      updatedAt: new Date().toISOString(),
      settings,
      apply,
      publish,
      purge,
      headers,
    };

    writeReport('configure-loftloader-branding.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
