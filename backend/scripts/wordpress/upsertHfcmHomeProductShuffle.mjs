import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

const SNIPPET_NAME = 'GAMA Home Product Shuffle';

const SNIPPET_CODE = `<script data-no-optimize="1" data-cfasync="false">
(function() {
  if (window.__gamaHomeProductShuffleInstalled) return;
  window.__gamaHomeProductShuffleInstalled = true;
  document.documentElement.setAttribute('data-gama-home-shuffle-patched', '1');

  var API_BASE = '/wp-json/wc/store/v1/products';
  var MAX_PRODUCTS = 12;
  var MAX_RUNTIME_MS = 12000;
  var CHECK_INTERVAL_MS = 350;
  var SECTION_SELECTOR = '.home .wd-products-element .products.wd-products[data-source="main_loop"], .home .woocommerce .products.wd-products[data-source="main_loop"], .home .products.wd-products[data-source="main_loop"]';
  var startedAt = Date.now();
  var intervalId = null;
  var stopped = false;

  function randInt(max) {
    return Math.floor(Math.random() * max);
  }

  function shuffle(items) {
    for (var i = items.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
    return items;
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function pickContainers() {
    var found = [];
    document.querySelectorAll(SECTION_SELECTOR).forEach(function(container) {
      if (found.indexOf(container) === -1) found.push(container);
    });
    return found.slice(0, 2);
  }

  function formatPriceHtml(product) {
    if (product && product.price_html) {
      return product.price_html;
    }

    var prices = product && product.prices ? product.prices : null;
    if (!prices || !prices.price) return '';

    var decimals = Number(prices.currency_minor_unit || 0);
    var amount = Number(prices.price) / Math.pow(10, decimals);
    var formatted = amount.toLocaleString('fr-FR', {
      minimumFractionDigits: decimals > 0 ? decimals : 0,
      maximumFractionDigits: decimals > 0 ? decimals : 0,
    });

    return '<span class="woocommerce-Price-amount amount"><bdi>' +
      escapeHtml(formatted + ' ' + (prices.currency_suffix || prices.currency_symbol || 'DA')) +
      '</bdi></span>';
  }

  function pickImage(product) {
    if (!product || !Array.isArray(product.images) || !product.images.length) return null;
    return product.images[0] || null;
  }

  function hasImage(product) {
    var image = pickImage(product);
    return !!(image && (image.src || image.thumbnail || image.full || image.url));
  }

  function buildProductCard(product) {
    var permalink = product.permalink || '#';
    var sku = product.sku || '';
    var priceHtml = formatPriceHtml(product);
    var image = pickImage(product) || {};
    var imageUrl = image.src || image.thumbnail || image.full || image.url || '';
    var imageWidth = Number(image.width || (image.dimensions && image.dimensions.width) || 300) || 300;
    var imageHeight = Number(image.height || (image.dimensions && image.dimensions.height) || 300) || 300;
    var imageSrcset = escapeHtml(image.srcset || '');
    var imageSizes = escapeHtml(image.sizes || '');
    var title = escapeHtml(product.name || '');
    var imageAlt = escapeHtml(image.alt || title);

    return [
      '<div class="wd-product wd-hover-fw-button wd-hover-with-fade wd-fade-off product-grid-item product type-product post-' + escapeHtml(product.id) + ' status-publish instock has-post-thumbnail shipping-taxable purchasable product-type-simple" data-loop="1" data-id="' + escapeHtml(product.id) + '">',
        '<div class="product-wrapper">',
          '<div class="content-product-imagin"></div>',
          '<div class="product-element-top wd-quick-shop" style="min-height:194px;padding:12px;background:#fff;border-radius:20px;overflow:hidden;display:flex;align-items:center;justify-content:center;">',
            '<a href="' + escapeHtml(permalink) + '" class="product-image-link" style="width:100%;min-height:164px;display:flex;align-items:stretch;justify-content:center;">',
              '<div class="wd-product-grid-slider wd-fill" style="width:100%;height:164px;display:flex;align-items:stretch;justify-content:center;overflow:hidden;">',
                imageUrl ? '<img class="attachment-woocommerce_thumbnail size-woocommerce_thumbnail" loading="eager" fetchpriority="high" decoding="async" width="' + imageWidth + '" height="' + imageHeight + '" src="' + escapeHtml(imageUrl) + '"' + (imageSrcset ? ' srcset="' + imageSrcset + '"' : '') + (imageSizes ? ' sizes="' + imageSizes + '"' : '') + ' alt="' + imageAlt + '" style="width:100%;height:100%;object-fit:cover;display:block;">' : '<div class="gama-home-product-placeholder" style="width:100%;height:100%;background:linear-gradient(135deg,#f4f6f8,#ffffff);"></div>',
              '</div>',
            '</a>',
            '<div class="wd-buttons wd-pos-r-t"></div>',
          '</div>',
          '<div class="product-element-bottom">',
            '<h3 class="wd-entities-title"><a href="' + escapeHtml(permalink) + '">' + title + '</a></h3>',
            '<div class="wrap-price"><span class="price">' + priceHtml + '</span></div>',
            '<div class="wd-add-btn wd-add-btn-replace"><a href="/?add-to-cart=' + encodeURIComponent(product.id) + '" data-quantity="1" class="button product_type_simple add_to_cart_button ajax_add_to_cart add-to-cart-loop" data-product_id="' + escapeHtml(product.id) + '" data-product_sku="' + escapeHtml(sku) + '" rel="nofollow" role="button"><span>Ajouter au panier</span></a></div>',
            '<div class="wd-product-detail wd-product-sku"><span class="wd-label">SKU:</span> ' + escapeHtml(sku) + '</div>',
          '</div>',
        '</div>',
      '</div>',
    ].join('');
  }

  function buildRandomSection(container, products, sectionIndex) {
    var existing = container.previousElementSibling;
    if (existing && existing.classList && existing.classList.contains('gama-home-random-products') && existing.dataset.gamaSection === String(sectionIndex)) {
      existing.innerHTML = products.map(buildProductCard).join('');
      return existing;
    }

    var wrapper = document.createElement('div');
    wrapper.className = container.className + ' gama-home-random-products';
    wrapper.setAttribute('data-gama-section', String(sectionIndex));
    wrapper.setAttribute('data-source', 'gama-random');
    wrapper.innerHTML = products.map(buildProductCard).join('');

    container.parentNode.insertBefore(wrapper, container);
    return wrapper;
  }

  function replaceContainer(container, products, sectionIndex) {
    if (!container || !Array.isArray(products) || !products.length) return false;

    var existing = Array.from(container.querySelectorAll('.wd-product')).map(function(node) {
      return String(node.getAttribute('data-id') || node.getAttribute('data-product_id') || node.dataset.id || '');
    }).filter(Boolean);
    var nextIds = products.map(function(product) { return String(product.id || ''); }).filter(Boolean);
    if (container.getAttribute('data-gama-randomized') === '1' && nextIds.length && existing.join(',') === nextIds.join(',')) {
      return false;
    }

    buildRandomSection(container, products, sectionIndex);
    container.style.setProperty('display', 'none', 'important');
    container.setAttribute('data-gama-randomized', '1');
    container.setAttribute('data-gama-randomized-at', String(Date.now()));
    return true;
  }

  function fetchProducts(page) {
    var url = API_BASE + '?per_page=' + MAX_PRODUCTS + '&page=' + page + '&orderby=date&order=desc&_=' + Date.now();
    return fetch(url, { credentials: 'same-origin', cache: 'no-store' })
      .then(function(response) {
        if (!response.ok) throw new Error('Store API error ' + response.status);
        return response.json();
      });
  }

  function loadRandomProducts() {
    var page = randInt(20) + 1;
    return fetchProducts(page)
      .catch(function() {
        return fetchProducts(1);
      })
      .then(function(products) {
        return Array.isArray(products) ? products.filter(hasImage) : [];
      });
  }

  function loadProductsWithImages(requiredCount) {
    var pages = [randInt(20) + 1, randInt(20) + 1, randInt(20) + 1, 1];
    var collected = [];
    var seenIds = Object.create(null);

    function appendBatch(batch) {
      (Array.isArray(batch) ? batch : []).forEach(function(product) {
        if (!hasImage(product)) return;
        var id = String(product && product.id ? product.id : '');
        if (!id || seenIds[id]) return;
        seenIds[id] = true;
        collected.push(product);
      });
    }

    function next(index) {
      if (collected.length >= requiredCount || index >= pages.length) {
        return Promise.resolve(collected);
      }

      return fetchProducts(pages[index])
        .catch(function() {
          return [];
        })
        .then(function(batch) {
          appendBatch(batch);
          return next(index + 1);
        });
    }

    return next(0);
  }

  function markVisible() {
    document.documentElement.classList.add('gama-home-shuffle-loading');
  }

  function markReady() {
    document.documentElement.classList.remove('gama-home-shuffle-loading');
  }

  function applyOnce() {
    var containers = pickContainers();
    if (!containers.length) return Promise.resolve(false);

    markVisible();
    console.info('[GAMA] shuffle containers', containers.length);

    return loadProductsWithImages(containers.length * 4).then(function(products) {
      if (!Array.isArray(products) || !products.length) return false;
      var picked = shuffle(products.slice()).slice(0, containers.length * 4);
      var changed = false;

      containers.forEach(function(container, index) {
        var subset = picked.slice(index * 4, index * 4 + 4);
        if (subset.length) {
          changed = replaceContainer(container, subset, index) || changed;
        }
      });

      if (changed) {
        markReady();
        console.info('[GAMA] Home product shuffle applied', picked.map(function(product) { return product.name; }));
      } else {
        console.info('[GAMA] Home product shuffle unchanged');
      }

      return changed;
    }).catch(function(error) {
      console.warn('[GAMA] Home product shuffle failed', error && error.message ? error.message : error);
      return false;
    });
  }

  function waitForTargets() {
    function stop() {
      if (stopped) return;
      stopped = true;
      if (intervalId) clearInterval(intervalId);
      intervalId = null;
      markReady();
    }

    function tick() {
      if (stopped) return;
      if (Date.now() - startedAt > MAX_RUNTIME_MS) {
        stop();
        return;
      }

      applyOnce().then(function(changed) {
        if (changed) {
          stop();
        }
      });
    }

    tick();
    intervalId = window.setInterval(tick, CHECK_INTERVAL_MS);
    window.setTimeout(stop, MAX_RUNTIME_MS);
  }

  function resetState() {
    document.querySelectorAll('.home .products.wd-products[data-gama-randomized="1"]').forEach(function(container) {
      container.removeAttribute('data-gama-randomized');
      container.removeAttribute('data-gama-randomized-at');
    });
  }

  function start() {
    console.info('[GAMA] Home product shuffle start');
    resetState();
    waitForTargets();
  }

  start();
})();
</script>
<style>
html.gama-home-shuffle-loading .home .products.wd-products {
  min-height: 480px;
}

html.gama-home-shuffle-loading .home .products.wd-products .wd-product {
  opacity: 0.35;
}

.gama-home-product-placeholder {
  width: 100%;
  padding-top: 100%;
  background: linear-gradient(135deg, #f4f6f8, #ffffff);
}

.gama-home-random-products .product-element-top {
  min-height: 194px;
}

.gama-home-random-products {
  display: grid !important;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 2px;
}

.gama-home-random-products .wd-product {
  width: auto;
}

.gama-home-random-products .product-image-link {
  min-height: 164px;
}

.gama-home-random-products .wd-product-grid-slider {
  height: 164px;
}

.gama-home-random-products img.attachment-woocommerce_thumbnail {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

@media (max-width: 1024px) {
  .gama-home-random-products {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 767px) {
  .gama-home-random-products {
    grid-template-columns: repeat(1, minmax(0, 1fr));
  }
}
</style>`;

async function goto(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectHfcmSnippets(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-list`);

  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const links = Array.from(row.querySelectorAll('a')).map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href || '',
        }));

        const editHref = links.find((item) => /edit|modifier/i.test(item.text))?.href || '';
        const deleteHref = links.find((item) => /delete|supprimer/i.test(item.text))?.href || '';
        const title = row.querySelector('td.name strong')?.textContent || row.querySelector('strong')?.textContent || '';
        const id = Number(row.querySelector('input[name="snippets[]"]')?.value || '0');
        const enabled = !!row.querySelector('.round-toggle:checked');

        if (!title) return null;

        return {
          id,
          title: title.trim(),
          editHref,
          deleteHref,
          enabled,
          rowText: (row.textContent || '').replace(/\s+/g, ' ').trim(),
        };
      })
      .filter(Boolean)
  );
}

async function deleteSnippet(page, url) {
  await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function fillSnippetForm(page) {
  await page.fill('input[name="data[name]"]', SNIPPET_NAME);
  await page.evaluate(() => {
    function selectByText(selector, matcher) {
      const select = document.querySelector(selector);
      if (!(select instanceof HTMLSelectElement)) return;
      const option = Array.from(select.options).find((opt) => matcher(opt.textContent || ''));
      if (option) {
        select.value = option.value;
        select.dispatchEvent(new Event('change', { bubbles: true }));
      }
    }

    selectByText('select[name="data[snippet_type]"]', (text) => /html/i.test(text));
    selectByText('select[name="data[display_on]"]', (text) => /ensemble|site/i.test(text));
    selectByText('select[name="data[location]"]', (text) => /ent[eê]te|header/i.test(text));
    selectByText('select[name="data[device_type]"]', (text) => /tous|toutes|all/i.test(text));
    selectByText('select[name="data[status]"]', (text) => /activ/i.test(text));
  });

  await page.evaluate((code) => {
    const textarea = document.querySelector('textarea[name="data[snippet]"]');
    if (textarea instanceof HTMLTextAreaElement) {
      textarea.value = code;
      textarea.dispatchEvent(new Event('input', { bubbles: true }));
      textarea.dispatchEvent(new Event('change', { bubbles: true }));
    }

    const codeMirror = document.querySelector('.CodeMirror')?.CodeMirror;
    if (codeMirror?.setValue) {
      codeMirror.setValue(code);
      codeMirror.save?.();
    }
  }, SNIPPET_CODE);
  await page.waitForTimeout(300);

  const submit = page.locator('input[name="insert"]').first();
  if ((await submit.count()) > 0) {
    await submit.click();
  } else {
    await page.locator('input[type="submit"]').first().click();
  }

  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1500);
}

async function purgeCaches(page, config) {
  await goto(page, `${config.baseUrl}/wp-admin/index.php`);

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

async function fetchHomepage(config) {
  const response = await fetch(`${config.baseUrl}/`, {
    headers: {
      'user-agent': 'Codex HFCM Home Shuffle Check',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
    },
  });

  const html = await response.text();
  return {
    status: response.status,
    containsSnippet: html.includes('__gamaHomeProductShuffleInstalled'),
    shuffleCount: (html.match(/__gamaHomeProductShuffleInstalled/g) || []).length,
    cacheStatus: response.headers.get('x-litespeed-cache') || '',
    cacheControl: response.headers.get('x-litespeed-cache-control') || '',
  };
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const before = await collectHfcmSnippets(page, config);
    const existing = before.filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase());

    for (const snippet of existing) {
      if (snippet.deleteHref) {
        await deleteSnippet(page, snippet.deleteHref);
      }
    }

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=hfcm-create`);
    await fillSnippetForm(page);

    const after = await collectHfcmSnippets(page, config);
    const matches = after
      .filter((item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase())
      .sort((left, right) => right.id - left.id);
    const kept = matches[0] || null;

    for (const duplicate of matches.slice(1)) {
      if (duplicate.deleteHref) {
        await deleteSnippet(page, duplicate.deleteHref);
      }
    }

    const remaining = (await collectHfcmSnippets(page, config)).filter(
      (item) => item.title.toLowerCase() === SNIPPET_NAME.toLowerCase()
    );

    const purge = await purgeCaches(page, config);
    const homepageCheck = await fetchHomepage(config);

    const report = {
      updatedAt: new Date().toISOString(),
      snippetName: SNIPPET_NAME,
      deleted: existing,
      kept,
      remaining,
      purge,
      homepageCheck,
    };

    writeReport('upsert-hfcm-home-product-shuffle.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
