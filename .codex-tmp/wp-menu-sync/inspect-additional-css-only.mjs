import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
} from '../../backend/scripts/wordpress/productCategoryMenuSync.mjs';

const outDir = path.resolve('.codex-tmp/wp-menu-sync/out');

async function expandAdditionalCssSection(page) {
  const selectors = [
    '#accordion-section-custom_css h3',
    '#sub-accordion-section-custom_css h3',
  ];

  for (const selector of selectors) {
    const locator = page.locator(selector).first();
    if (await locator.count()) {
      await locator.click().catch(() => null);
      await page.waitForTimeout(1500);
    }
  }
}

async function collectCssState(page) {
  return page.evaluate(() => {
    const textareaCandidates = Array.from(document.querySelectorAll('textarea')).map((node) => ({
      id: node.id || '',
      value: node.value || '',
      placeholder: node.getAttribute('placeholder') || '',
      ariaLabel: node.getAttribute('aria-label') || '',
      dataLink: node.getAttribute('data-customize-setting-link') || '',
      className: node.className || '',
    }));

    const customCss =
      document.querySelector('#_customize-input-custom_css') ||
      document.querySelector('textarea[data-customize-setting-link="custom_css"]') ||
      null;

    const codeMirror = document.querySelector('.CodeMirror');

    return {
      url: location.href,
      title: document.title,
      bodyPreview: (document.body?.innerText || '').slice(0, 4000),
      textareaCandidates,
      customCssFound: !!customCss,
      customCssId: customCss?.id || '',
      customCssValue: customCss?.value || '',
      codeMirrorText: codeMirror?.textContent || '',
      accordionState: Array.from(document.querySelectorAll('#customize-theme-controls .control-section')).map((section) => ({
        id: section.id || '',
        expanded: section.classList.contains('open'),
        title: section.querySelector('.accordion-section-title')?.textContent?.trim() || '',
      })),
    };
  });
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/customize.php`, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(2500);

    const before = await collectCssState(page);
    await expandAdditionalCssSection(page);
    const after = await collectCssState(page);

    await page.screenshot({ path: path.join(outDir, 'customizer-additional-css.png'), fullPage: true }).catch(() => null);

    const report = {
      checkedAt: new Date().toISOString(),
      before,
      after: {
        ...after,
        customCssValuePreview: String(after.customCssValue || '').slice(0, 12000),
        codeMirrorTextPreview: String(after.codeMirrorText || '').slice(0, 12000),
      },
    };

    fs.writeFileSync(path.join(outDir, 'additional-css-inspect.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
