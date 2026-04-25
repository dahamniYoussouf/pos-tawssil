import { launchWordPressBrowser, resolveSyncConfig } from './productCategoryMenuSync.mjs';

const config = resolveSyncConfig();
const { browser, page } = await launchWordPressBrowser(config);

try {
  page.on('console', (msg) => console.log('CONSOLE', msg.type(), msg.text()));
  page.on('pageerror', (err) => console.log('PAGEERROR', err.message));

  await page.goto(config.baseUrl + '/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(8000);

  const data = await page.evaluate(() => {
    const cards = Array.from(document.querySelectorAll('.home .wd-product')).slice(0, 4);
    return cards.map((card) => {
      const img = card.querySelector('img.attachment-woocommerce_thumbnail');
      const top = card.querySelector('.product-element-top');
      const link = card.querySelector('.product-image-link');
      const slider = card.querySelector('.wd-product-grid-slider');
      const rect = (node) => {
        if (!node) return null;
        const box = node.getBoundingClientRect();
        const style = getComputedStyle(node);
        return {
          width: box.width,
          height: box.height,
          display: style.display,
          visibility: style.visibility,
          opacity: style.opacity,
        };
      };
      return {
        id: card.getAttribute('data-id'),
        title: (card.querySelector('.wd-entities-title')?.textContent || '').trim(),
        card: rect(card),
        top: rect(top),
        link: rect(link),
        slider: rect(slider),
        image: img
          ? {
              src: img.getAttribute('src'),
              complete: img.complete,
              naturalWidth: img.naturalWidth,
              naturalHeight: img.naturalHeight,
              loading: img.getAttribute('loading'),
              fetchpriority: img.getAttribute('fetchpriority'),
              rect: rect(img),
            }
          : null,
      };
    });
  });

  console.log(JSON.stringify(data, null, 2));
} finally {
  await browser.close();
}
