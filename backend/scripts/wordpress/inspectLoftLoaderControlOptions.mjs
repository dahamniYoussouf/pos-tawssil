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
      const ids = ['loftloader_loader_type', 'loftloader_bg_animation'];

      return ids.map((id) => {
        const control = document.querySelector(`#customize-control-${id}`);
        const options = Array.from(control?.querySelectorAll('input, option') || []).map((node) => {
          if (node instanceof HTMLOptionElement) {
            return {
              tag: 'option',
              value: node.value,
              text: (node.textContent || '').replace(/\s+/g, ' ').trim(),
              selected: node.selected,
            };
          }

          const label = node.closest('label');
          return {
            tag: 'input',
            type: node.getAttribute('type') || '',
            value: node.getAttribute('value') || '',
            checked: node instanceof HTMLInputElement ? node.checked : false,
            text: (label?.textContent || '').replace(/\s+/g, ' ').trim(),
          };
        });

        return {
          id,
          text: (control?.textContent || '').replace(/\s+/g, ' ').trim(),
          html: control?.innerHTML || '',
          options,
        };
      });
    });

    writeReport('inspect-loftloader-control-options.json', {
      updatedAt: new Date().toISOString(),
      controls: report,
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
