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
  await page.waitForTimeout(2000);
}

async function main() {
  const config = resolveSyncConfig();
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

    const report = await page.evaluate(() => {
      const api = window.wp?.customize;
      if (!api) {
        return {
          error: 'wp.customize not found',
        };
      }

      const controls = [];
      api.control.each((control) => {
        controls.push({
          id: control.id,
          type: control.params?.type || '',
          label: control.params?.label || '',
          section: control.section?.() || control.params?.section || '',
          priority: control.priority?.() || control.params?.priority || '',
          value: control.setting?.get ? control.setting.get() : '',
          choices: control.params?.choices || null,
          inputAttrs: control.params?.input_attrs || null,
          description: control.params?.description || '',
          hasContainer: !!control.container,
          containerLength: control.container?.length || 0,
          containerPreview:
            control.container && control.container[0]
              ? (control.container[0].outerHTML || '').slice(0, 1000)
              : '',
        });
      });

      const settings = [];
      api.each((setting) => {
        settings.push({
          id: setting.id,
          value: setting.get ? setting.get() : '',
          dirty: setting._dirty || false,
        });
      });

      return {
        url: location.href,
        title: document.title,
        meta: {
          apiType: typeof api,
          controlType: typeof api.control,
          hasControlEach: !!api.control?.each,
          hasControlInstance: !!api.control?.instance,
          sampleControlInstance: api.control?.instance ? !!api.control.instance('loftloader_loader_type') : null,
          hasInstance: typeof api.instance === 'function',
          sampleInstance: typeof api.instance === 'function' ? !!api.instance('loftloader_loader_type') : null,
        },
        controls: controls.filter((item) => /loftloader/i.test(item.id || item.label || item.section || '')),
        settings: settings.filter((item) => /loftloader/i.test(item.id)),
      };
    });

    writeReport('inspect-loftloader-customizer-api.json', {
      updatedAt: new Date().toISOString(),
      ...report,
    });
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
