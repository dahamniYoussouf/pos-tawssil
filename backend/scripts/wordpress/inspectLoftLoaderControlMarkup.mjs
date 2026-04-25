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
    await page.evaluate(() => {
      const ids = ['loftloader_background', 'loftloader_loader'];
      for (const id of ids) {
        const section = document.querySelector(`#accordion-section-${id} .accordion-section-title`);
        if (section instanceof HTMLElement && !section.closest('.open')) {
          section.click();
        }
      }
    });
    await page.waitForTimeout(1500);

    const report = await page.evaluate(() => {
      const ids = [
        'loftloader_bg_color',
        'loftloader_bg_opacity',
        'loftloader_loader_color',
        'loftloader_custom_img',
        'loftloader_img_width',
      ];

      return ids.map((id) => {
        const control = document.querySelector(`#customize-control-${id}`);
        return {
          id,
          text: (control?.textContent || '').replace(/\s+/g, ' ').trim(),
          html: control?.innerHTML || '',
          inputs: Array.from(control?.querySelectorAll('input, select, textarea, button') || []).map((node) => ({
            tag: node.tagName.toLowerCase(),
            type: node.getAttribute('type') || '',
            name: node.getAttribute('name') || '',
            id: node.id || '',
            value: node.getAttribute('value') || '',
            dataCustomizeSettingLink: node.getAttribute('data-customize-setting-link') || '',
            ariaLabel: node.getAttribute('aria-label') || '',
          })),
        };
      });
    });

    writeReport('inspect-loftloader-control-markup.json', {
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
