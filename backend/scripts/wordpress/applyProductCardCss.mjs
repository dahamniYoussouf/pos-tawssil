import fs from 'fs';
import path from 'path';
import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const MARKER_START = '/* CODEX PRODUCT CARD START */';
const MARKER_END = '/* CODEX PRODUCT CARD END */';
const outDir = path.resolve('backend/scripts/wordpress/out');

const PRODUCT_CARD_CSS = `${MARKER_START}
/* Product cards: boutique + categories */
body .products .product-grid-item .product-wrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  container-type: inline-size;
  gap: 14px;
  height: 100%;
  padding: 16px 16px 14px;
  background: linear-gradient(180deg, #f5f8fc 0%, #e8eef5 100%);
  border-radius: 24px;
  box-shadow: 0 14px 28px rgba(17, 50, 92, 0.08);
  overflow: hidden;
  transition: transform 0.22s ease, box-shadow 0.22s ease;
}

body .products .product-grid-item:hover .product-wrapper {
  transform: translateY(-3px);
  box-shadow: 0 18px 34px rgba(17, 50, 92, 0.11);
}

body .products .product-grid-item .content-product-imagin,
body .products .product-grid-item .wd-product-grid-slider-pagin,
body .products .product-grid-item .fade-in-block.wd-scroll,
body .products .product-grid-item .star-rating,
body .products .product-grid-item .tinv-wraper .tinvwl_add_to_wishlist-text,
body .products .product-grid-item .tinv-wraper .tinvwl_already_on_wishlist-text,
body .products .product-grid-item .tinv-wraper .tinvwl-tooltip,
body .products .product-grid-item .tinv-wraper .tinv-wishlist-clear {
  display: none !important;
}

body .products .product-grid-item .product-element-top {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 194px;
  padding: 12px;
  background: #ffffff;
  border-radius: 20px;
  overflow: hidden;
}

body .products .product-grid-item .product-image-link {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 164px;
}

body .products .product-grid-item img.attachment-woocommerce_thumbnail {
  width: 100%;
  height: auto;
  max-height: 158px;
  object-fit: contain;
}

body .products .product-grid-item .product-element-bottom {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas:
    "title title"
    "brand sku"
    "price cart";
  align-items: center;
  gap: 8px 10px;
}

body .products .product-grid-item .wd-entities-title {
  grid-area: title;
  margin: 0;
  min-height: 2.24em;
  font-size: clamp(13.5px, 0.9vw, 16px);
  line-height: 1.12;
  font-weight: 800;
  letter-spacing: 0;
  text-transform: uppercase;
  color: #153761;
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

body .products .product-grid-item .wd-entities-title a {
  color: inherit;
}

body .products .product-grid-item .wrap-price {
  display: contents;
}

body .products .product-grid-item .pwb-brands-in-loop {
  grid-area: brand;
  font-size: 13px;
  font-weight: 700;
  line-height: 1;
  color: #2380d6;
}

body .products .product-grid-item .pwb-brands-in-loop a {
  color: inherit;
}

body .products .product-grid-item .wd-product-sku {
  grid-area: sku;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin: 0;
  padding: 0;
  font-size: 12px;
  line-height: 1;
  color: #8b98a8;
}

body .products .product-grid-item .wd-product-sku .wd-label {
  display: none;
}

body .products .product-grid-item .price {
  grid-area: price;
  display: inline-flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 4px;
  margin: 0;
  font-size: clamp(18px, 1.28vw, 22px);
  font-weight: 800;
  line-height: 1;
  color: #153761;
}

body .products .product-grid-item .price .woocommerce-Price-amount {
  margin: 0;
  padding: 0;
  background: none;
  border-radius: 0;
  box-shadow: none !important;
  color: inherit;
}

body .products .product-grid-item .price del .woocommerce-Price-amount {
  opacity: 0.45;
}

body .products .product-grid-item .price del {
  order: 2;
  width: 100%;
  font-size: 0.72em;
  line-height: 1;
  color: #97a4b3;
}

body .products .product-grid-item .price ins {
  order: 1;
  text-decoration: none;
}

body .products .product-grid-item .wd-add-btn {
  grid-area: cart;
  justify-self: end;
  align-self: end;
  margin: 0 !important;
  max-width: 100%;
  min-width: 92px;
}

body .products .product-grid-item .wd-add-btn .add-to-cart-loop {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 40px;
  min-width: 92px;
  padding: 0 8px;
  border: 0;
  width: auto;
  max-width: 92px;
  border-radius: 16px !important;
  background: linear-gradient(180deg, #2890e4 0%, #176fc5 100%);
  box-shadow: 0 10px 20px rgba(24, 114, 195, 0.22);
  color: #ffffff;
  font-size: 0;
  font-weight: 700;
  line-height: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

body .products .product-grid-item .wd-add-btn .add-to-cart-loop::before {
  content: "";
  width: 15px;
  height: 15px;
  flex: 0 0 15px;
  font-size: 0;
  background: center / contain no-repeat
    url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23ffffff' stroke-width='2.1' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M6 8h12l-1 11H7L6 8Z'/%3E%3Cpath d='M9 8a3 3 0 0 1 6 0'/%3E%3C/svg%3E");
}

body .products .product-grid-item .wd-add-btn .add-to-cart-loop > span {
  display: none !important;
  width: 0 !important;
  max-width: 0 !important;
  overflow: hidden !important;
  opacity: 0 !important;
  font-size: 0 !important;
  line-height: 0 !important;
}

body .products .product-grid-item .wd-add-btn .add-to-cart-loop::after {
  content: "Ajout";
  display: inline-block;
  flex: 0 0 auto;
  white-space: nowrap;
  text-transform: uppercase;
  font-size: 10.5px;
  line-height: 1;
  color: #ffffff;
}

body .products .product-grid-item .wd-add-btn .product_type_variable::after,
body .products .product-grid-item .wd-add-btn .product_type_grouped::after,
body .products .product-grid-item .wd-add-btn .product_type_external::after {
  content: "Choix";
}

body .products .product-grid-item .wd-add-btn .add-to-cart-loop:hover {
  color: #ffffff;
  transform: translateY(-1px);
  box-shadow: 0 16px 28px rgba(24, 114, 195, 0.28);
}

body .products .product-grid-item .tinv-wraper.woocommerce.tinv-wishlist,
body .products .product-grid-item .tinv-wraper.tinv-wishlist {
  position: absolute;
  top: 14px;
  right: 14px;
  z-index: 5;
  padding: 0 !important;
  margin: 0 !important;
  background: transparent !important;
}

body .products .product-grid-item .tinv-wraper .tinvwl_add_to_wishlist_button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  padding: 0;
  border-radius: 999px;
  background: #ffffff;
  box-shadow: 0 10px 18px rgba(17, 50, 92, 0.12);
}

body .products .product-grid-item .tinv-wraper .tinvwl_add_to_wishlist_button img {
  width: 16px;
  height: 16px;
  object-fit: contain;
}

body .products .product-grid-item .product-labels {
  position: absolute;
  top: 14px;
  left: 14px;
  z-index: 5;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-width: calc(100% - 62px);
}

body .products .product-grid-item .product-label {
  margin: 0;
  padding: 6px 10px;
  border-radius: 999px;
  background: #a7d8fb;
  color: #1b6cb0;
  box-shadow: none;
  font-size: 10px;
  font-weight: 700;
  line-height: 1;
  text-transform: none;
}

@media (max-width: 1024px) {
  body .products .product-grid-item .product-wrapper {
    padding: 14px 14px 12px;
    border-radius: 22px;
    gap: 12px;
  }

  body .products .product-grid-item .product-element-top {
    min-height: 176px;
    padding: 10px;
    border-radius: 18px;
  }

  body .products .product-grid-item .product-image-link {
    min-height: 146px;
  }

  body .products .product-grid-item img.attachment-woocommerce_thumbnail {
    max-height: 138px;
  }
}

@media (max-width: 767px) {
  body .products .product-grid-item .product-wrapper {
    padding: 14px 14px 12px;
    border-radius: 22px;
    gap: 12px;
  }

  body .products .product-grid-item .product-element-top {
    min-height: 162px;
    padding: 10px;
    border-radius: 18px;
  }

  body .products .product-grid-item .product-image-link {
    min-height: 138px;
  }

  body .products .product-grid-item img.attachment-woocommerce_thumbnail {
    max-height: 132px;
  }

  body .products .product-grid-item .product-element-bottom {
    grid-template-columns: 1fr auto;
    grid-template-areas:
      "title title"
      "brand sku"
      "price price"
      "cart cart";
    gap: 10px;
  }

  body .products .product-grid-item .wd-add-btn {
    width: 100%;
    justify-self: stretch;
  }

  body .products .product-grid-item .wd-add-btn .add-to-cart-loop {
    width: 100%;
    min-height: 38px;
    padding: 0 10px;
  }

  body .products .product-grid-item .tinv-wraper.woocommerce.tinv-wishlist,
  body .products .product-grid-item .tinv-wraper.tinv-wishlist,
  body .products .product-grid-item .product-labels {
    top: 12px;
  }

  body .products .product-grid-item .tinv-wraper.woocommerce.tinv-wishlist,
  body .products .product-grid-item .tinv-wraper.tinv-wishlist {
    right: 12px;
  }

  body .products .product-grid-item .product-labels {
    left: 12px;
    max-width: calc(100% - 58px);
  }

  body .products .product-grid-item .product-label {
    padding: 6px 10px;
    font-size: 11px;
  }
}

@container (max-width: 280px) {
  body .products .product-grid-item .product-wrapper {
    gap: 10px;
    padding: 12px 12px 11px;
    border-radius: 20px;
  }

  body .products .product-grid-item .product-element-top {
    min-height: 154px;
    padding: 10px;
    border-radius: 16px;
  }

  body .products .product-grid-item .product-image-link {
    min-height: 130px;
  }

  body .products .product-grid-item img.attachment-woocommerce_thumbnail {
    max-height: 118px;
  }

  body .products .product-grid-item .product-element-bottom {
    gap: 6px 8px;
  }

  body .products .product-grid-item .wd-entities-title {
    min-height: 2.16em;
    font-size: 12px;
    line-height: 1.08;
  }

  body .products .product-grid-item .pwb-brands-in-loop {
    font-size: 11px;
  }

  body .products .product-grid-item .wd-product-sku {
    font-size: 10px;
  }

  body .products .product-grid-item .price {
    font-size: 16px;
    gap: 3px;
  }

  body .products .product-grid-item .price del {
    font-size: 0.66em;
  }

  body .products .product-grid-item .wd-add-btn {
    min-width: 68px;
  }

  body .products .product-grid-item .wd-add-btn .add-to-cart-loop {
    min-height: 34px;
    min-width: 68px;
    max-width: 68px;
    padding: 0 8px;
    font-size: 0;
    border-radius: 14px !important;
  }

  body .products .product-grid-item .wd-add-btn .add-to-cart-loop::before {
    width: 13px;
    height: 13px;
    flex: 0 0 13px;
  }

  body .products .product-grid-item .wd-add-btn .add-to-cart-loop::after {
    content: "Aj.";
    display: inline-block;
    font-size: 9px;
  }

  body .products .product-grid-item .wd-add-btn .product_type_variable::after,
  body .products .product-grid-item .wd-add-btn .product_type_grouped::after,
  body .products .product-grid-item .wd-add-btn .product_type_external::after {
    content: "Choix";
  }

  body .products .product-grid-item .tinv-wraper.woocommerce.tinv-wishlist,
  body .products .product-grid-item .tinv-wraper.tinv-wishlist {
    top: 12px;
    right: 12px;
  }

  body .products .product-grid-item .tinv-wraper .tinvwl_add_to_wishlist_button {
    width: 30px;
    height: 30px;
  }

  body .products .product-grid-item .tinv-wraper .tinvwl_add_to_wishlist_button img {
    width: 14px;
    height: 14px;
  }

  body .products .product-grid-item .product-labels {
    top: 12px;
    left: 12px;
    max-width: calc(100% - 48px);
  }

  body .products .product-grid-item .product-label {
    padding: 5px 8px;
    font-size: 9px;
  }
}
${MARKER_END}`;

function normalizeCss(css) {
  return String(css || '').replace(/\r\n/g, '\n').replace(/\r/g, '\n');
}

function upsertCssBlock(existingCss) {
  const normalized = normalizeCss(existingCss).trimEnd();
  const blockPattern = new RegExp(
    `${escapeRegExp(MARKER_START)}[\\s\\S]*?${escapeRegExp(MARKER_END)}`,
    'm'
  );

  if (blockPattern.test(normalized)) {
    return normalized.replace(blockPattern, '').trimEnd();
  }

  return normalized;
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

async function openAdditionalCssEditor(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/customize.php?autofocus%5Bsection%5D=custom_css`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2500);

  const toggleSelectors = [
    '#accordion-section-custom_css .accordion-section-title',
    '#accordion-section-custom_css h3',
    '#sub-accordion-section-custom_css .customize-section-title button',
    '#sub-accordion-section-custom_css h3',
  ];

  for (const selector of toggleSelectors) {
    const locator = page.locator(selector).first();
    if (await locator.count()) {
      await locator.click().catch(() => null);
      await page.waitForTimeout(700);
    }
  }

  await page.waitForFunction(
    () => {
      const editor =
        document.querySelector('#sub-accordion-section-custom_css .CodeMirror') ||
        document.querySelector('#accordion-section-custom_css .CodeMirror') ||
        document.querySelector('.CodeMirror');
      return !!editor?.CodeMirror;
    },
    null,
    { timeout: 30000 }
  );
}

async function readCurrentCss(page) {
  return page.evaluate(() => {
    const editor =
      document.querySelector('#sub-accordion-section-custom_css .CodeMirror') ||
      document.querySelector('#accordion-section-custom_css .CodeMirror') ||
      document.querySelector('.CodeMirror');

    if (!editor?.CodeMirror) {
      throw new Error('Could not find the Additional CSS editor.');
    }

    return editor.CodeMirror.getValue();
  });
}

async function writeCss(page, css) {
  return page.evaluate((nextCss) => {
    const editor =
      document.querySelector('#sub-accordion-section-custom_css .CodeMirror') ||
      document.querySelector('#accordion-section-custom_css .CodeMirror') ||
      document.querySelector('.CodeMirror');

    if (!editor?.CodeMirror) {
      throw new Error('Could not find the Additional CSS editor.');
    }

    const cm = editor.CodeMirror;
    cm.setValue(nextCss);
    cm.save();

    const textArea = cm.getTextArea();
    if (textArea) {
      textArea.value = nextCss;
      textArea.dispatchEvent(new Event('input', { bubbles: true }));
      textArea.dispatchEvent(new Event('change', { bubbles: true }));
    }

    try {
      if (window.wp?.customize) {
        const setting = window.wp.customize('custom_css');
        if (setting && typeof setting.set === 'function') {
          setting.set(nextCss);
        }
      }
    } catch (error) {
      // Ignore if the customizer API is not accessible.
    }

    return {
      length: cm.getValue().length,
      hasMarker: cm.getValue().includes('CODEX PRODUCT CARD START'),
    };
  }, css);
}

async function saveCustomizer(page) {
  await page.waitForFunction(
    () => {
      const button = document.querySelector('#save');
      return !!button && !button.disabled;
    },
    null,
    { timeout: 30000 }
  );

  await page.locator('#save').click();
  await page.waitForTimeout(5000);
}

async function purgeFrontCache(page, config) {
  await page.goto(`${config.baseUrl}/wp-admin/`, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForSelector('#wpadminbar', { state: 'attached', timeout: 30000 });

  const purgeTargets = await page.evaluate(() =>
    Array.from(document.querySelectorAll('#wpadminbar a')).map((link) => ({
      id: link.id || '',
      text: (link.textContent || '').trim(),
      href: link.href || '',
    }))
  );

  const match = purgeTargets.find((item) => {
    const haystack = `${item.id} ${item.text} ${item.href}`.toLowerCase();
    return (
      haystack.includes('purge') ||
      haystack.includes('vider') ||
      haystack.includes('clear cache') ||
      haystack.includes('litespeed') ||
      haystack.includes('cache')
    );
  });

  if (!match?.href) {
    return {
      cleared: false,
      reason: 'No cache purge action found in admin bar.',
      candidates: purgeTargets,
    };
  }

  await page.goto(match.href, { waitUntil: 'domcontentloaded', timeout: 60000 }).catch(() => null);
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2000);

  return {
    cleared: true,
    action: match,
  };
}

async function captureCardScreenshot(page, url, screenshotPath, viewport) {
  if (viewport) {
    await page.setViewportSize(viewport);
  }

  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2000);
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
  await page.waitForTimeout(1000);

  const card = page.locator('.products .product-grid-item').first();
  await card.waitFor({ state: 'attached', timeout: 30000 });
  await card.scrollIntoViewIfNeeded().catch(() => null);
  await page.waitForTimeout(1200);
  await card.screenshot({ path: screenshotPath });

  return page.evaluate(() => {
    const card = document.querySelector('.products .product-grid-item');
    return {
      text: card?.innerText?.trim() || '',
      title: document.title,
      url: location.href,
    };
  });
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await openAdditionalCssEditor(page, config);

    const existingCss = await readCurrentCss(page);
    const nextCss = upsertCssBlock(existingCss);

    fs.writeFileSync(path.join(outDir, 'product-card-custom-css.css'), `${PRODUCT_CARD_CSS}\n`, 'utf8');

    const writeState = await writeCss(page, nextCss);
    await saveCustomizer(page);
    await page.reload({ waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await openAdditionalCssEditor(page, config);

    const persistedCss = await readCurrentCss(page);
    const cachePurge = await purgeFrontCache(page, config);

    const desktopPage = await browser.newPage({ viewport: { width: 1440, height: 1400 } });
    const mobilePage = await browser.newPage({ viewport: { width: 430, height: 1180 } });
    const categoryPage = await browser.newPage({ viewport: { width: 1440, height: 1400 } });

    const boutiqueUrl = `${config.baseUrl}/boutique-outillage/`;
    const categoryUrl = `${config.baseUrl}/categorie/outillage-a-main/`;

    const captureOrNull = async (targetPage, url, screenshotPath) => {
      try {
        return await captureCardScreenshot(targetPage, url, screenshotPath);
      } catch (error) {
        return {
          error: error.message,
          url,
        };
      }
    };

    const boutiqueDesktop = await captureOrNull(
      desktopPage,
      boutiqueUrl,
      path.join(outDir, 'product-card-after-desktop.png')
    );
    const boutiqueMobile = await captureOrNull(
      mobilePage,
      boutiqueUrl,
      path.join(outDir, 'product-card-after-mobile.png')
    );
    const categoryDesktop = await captureOrNull(
      categoryPage,
      categoryUrl,
      path.join(outDir, 'product-card-category-after-desktop.png')
    );

    const report = {
      updatedAt: new Date().toISOString(),
      beforeLength: existingCss.length,
      afterLength: nextCss.length,
      hadMarkerBefore: existingCss.includes(MARKER_START),
      hasMarkerAfter: persistedCss.includes(MARKER_START),
      persistedLength: persistedCss.length,
      writeState,
      cachePurge,
      boutiqueDesktop,
      boutiqueMobile,
      categoryDesktop,
      screenshots: {
        boutiqueDesktop: path.join(outDir, 'product-card-after-desktop.png'),
        boutiqueMobile: path.join(outDir, 'product-card-after-mobile.png'),
        categoryDesktop: path.join(outDir, 'product-card-category-after-desktop.png'),
      },
    };

    writeReport('apply-product-card-css.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
