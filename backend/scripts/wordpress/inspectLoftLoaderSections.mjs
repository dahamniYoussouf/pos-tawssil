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
  await page.waitForTimeout(2500);
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

    const report = await page.evaluate(() => {
      const sections = Array.from(document.querySelectorAll('[id^="accordion-section-"]')).map((node) => ({
        id: node.id,
        title: (node.textContent || '').replace(/\s+/g, ' ').trim(),
        classes: node.className || '',
      }));

      const controls = Array.from(document.querySelectorAll('[id^="customize-control-"]')).map((node) => ({
        id: node.id,
        text: (node.textContent || '').replace(/\s+/g, ' ').trim(),
        classes: node.className || '',
      }));

      return {
        url: location.href,
        title: document.title,
        saveButton: {
          text: (document.querySelector('#save')?.textContent || '').replace(/\s+/g, ' ').trim(),
          disabled: !!document.querySelector('#save')?.disabled,
        },
        sections: sections.filter((item) => /loft|loader|background|display|advanced|more/i.test(item.id + item.title)),
        controls: controls.filter((item) => /loft|loader|background|display|advanced|more/i.test(item.id + item.text)),
      };
    });

    writeReport('inspect-loftloader-sections.json', {
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
