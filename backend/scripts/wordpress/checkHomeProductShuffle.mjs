import { launchWordPressBrowser, resolveSyncConfig } from './productCategoryMenuSync.mjs';

const config = resolveSyncConfig();
const { browser, page } = await launchWordPressBrowser(config);

try {
  page.on('console', (msg) => console.log('CONSOLE', msg.type(), msg.text()));
  page.on('pageerror', (err) => console.log('PAGEERROR', err.message));

  await page.goto(config.baseUrl + '/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(8000);

  const data = await page.evaluate(() => {
    const containers = Array.from(
      document.querySelectorAll(
        '.home .wd-products-element .products.wd-products[data-source="main_loop"], .home .woocommerce .products.wd-products[data-source="main_loop"], .home .products.wd-products[data-source="main_loop"]'
      )
    ).slice(0, 2);
    const randomSections = Array.from(document.querySelectorAll('.home .gama-home-random-products')).slice(0, 2);

    return {
      containers: containers.map((container, index) => ({
        index,
        randomized: container.getAttribute('data-gama-randomized'),
        hidden: getComputedStyle(container).display === 'none',
        ids: Array.from(container.querySelectorAll('.wd-product')).map((el) => el.getAttribute('data-id')).slice(0, 8),
        titles: Array.from(container.querySelectorAll('.wd-entities-title')).map((el) => (el.textContent || '').trim()).slice(0, 8),
        html: container.outerHTML.slice(0, 500),
      })),
      randomSections: randomSections.map((section, index) => ({
        index,
        sectionIndex: section.getAttribute('data-gama-section'),
        ids: Array.from(section.querySelectorAll('.wd-product')).map((el) => el.getAttribute('data-id')).slice(0, 8),
        titles: Array.from(section.querySelectorAll('.wd-entities-title')).map((el) => (el.textContent || '').trim()).slice(0, 8),
        html: section.outerHTML.slice(0, 500),
      })),
    };
  });

  console.log(JSON.stringify(data, null, 2));
} finally {
  await browser.close();
}
