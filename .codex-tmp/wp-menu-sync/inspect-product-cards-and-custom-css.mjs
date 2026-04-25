import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
} from '../../backend/scripts/wordpress/productCategoryMenuSync.mjs';

const outDir = path.resolve('.codex-tmp/wp-menu-sync/out');

async function captureFrontendProductCard(page, baseUrl) {
  const stamp = Date.now();
  const candidateUrls = [
    `${baseUrl}/boutique-outillage/?codex=${stamp}`,
    `${baseUrl}/categorie/outillage-a-main/?codex=${stamp}`,
    `${baseUrl}/boutique/?codex=${stamp}`,
    `${baseUrl}/shop/?codex=${stamp}`,
    `${baseUrl}/categorie-produit/outillage-a-main/?codex=${stamp}`,
    `${baseUrl}/categorie-produit/?codex=${stamp}`,
    `${baseUrl}/?codex=${stamp}`,
  ];

  let lastError = null;

  for (const url of candidateUrls) {
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
      await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
      await page.waitForTimeout(3000);
      await page.evaluate(() => {
        const selectors = ['.wd-page-preloader', '.woodmart-preloader', '.wd-preloader', '#wd-page-preloader', '.preloader'];
        for (const selector of selectors) {
          for (const node of document.querySelectorAll(selector)) {
            node.remove();
          }
        }
        document.body.classList.remove('wd-preloader-active');
        document.documentElement.classList.remove('wd-preloader-active');
        document.body.style.overflow = 'auto';
      });
      await page.waitForTimeout(1200);

      const summary = await page.evaluate(() => {
        const selectors = [
          '.products .product-grid-item',
          '.products .product',
          '.wd-products .product-grid-item',
          'li.product',
          '.product-grid-item',
        ];

        let card = null;
        let selectorUsed = '';

        for (const selector of selectors) {
          const match = document.querySelector(selector);
          if (match) {
            card = match;
            selectorUsed = selector;
            break;
          }
        }

        if (!card) {
          return {
            found: false,
            url: location.href,
            title: document.title,
            bodyPreview: (document.body?.innerText || '').slice(0, 2000),
          };
        }

        const classes = Array.from(card.classList);
        const descendants = Array.from(card.querySelectorAll('*'))
          .slice(0, 120)
          .map((node) => ({
            tag: node.tagName.toLowerCase(),
            className: node.className || '',
            text: (node.textContent || '').trim().slice(0, 120),
          }));

        return {
          found: true,
          url: location.href,
          title: document.title,
          selectorUsed,
          classes,
          text: (card.innerText || '').trim(),
          html: card.outerHTML,
          descendants,
        };
      });

      if (summary.found) {
        await page.locator(summary.selectorUsed).first().scrollIntoViewIfNeeded().catch(() => null);
        await page.waitForTimeout(1200);
        await page.screenshot({ path: path.join(outDir, 'product-card-before.png'), fullPage: true }).catch(() => null);
        return summary;
      }
    } catch (error) {
      lastError = error;
    }
  }

  return {
    found: false,
    error: lastError?.message || 'No product card found on candidate URLs.',
  };
}

async function captureCustomizerCss(page, baseUrl) {
  const candidateUrls = [
    `${baseUrl}/wp-admin/customize.php?autofocus%5Bsection%5D=custom_css`,
    `${baseUrl}/wp-admin/customize.php`,
  ];

  for (const url of candidateUrls) {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(2500);

    const snapshot = await page.evaluate(() => {
      const textarea =
        document.querySelector('textarea[data-customize-setting-link]') ||
        document.querySelector('textarea#_customize-input-custom_css[style], textarea#_customize-input-custom_css') ||
        document.querySelector('textarea');

      return {
        url: location.href,
        title: document.title,
        found: !!textarea,
        css: textarea?.value || '',
        textareaId: textarea?.id || '',
        bodyPreview: (document.body?.innerText || '').slice(0, 3000),
      };
    });

    if (snapshot.found) {
      return snapshot;
    }
  }

  return { found: false, css: '' };
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    const frontendPage = await browser.newPage();
    const frontend = await captureFrontendProductCard(frontendPage, config.baseUrl);

    await loginToWordPress(page, config);
    const customCss = await captureCustomizerCss(page, config.baseUrl);

    const report = {
      checkedAt: new Date().toISOString(),
      frontend,
      customCss: {
        ...customCss,
        cssPreview: String(customCss.css || '').slice(0, 12000),
      },
    };

    fs.writeFileSync(path.join(outDir, 'product-cards-and-custom-css.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
