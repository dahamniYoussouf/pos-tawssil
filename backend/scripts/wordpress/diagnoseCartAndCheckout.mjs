import {
  launchWordPressBrowser,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function goto(page, url) {
  const response = await page.goto(url, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
  return response;
}

async function gotoFirstAvailable(page, urls) {
  for (const url of urls) {
    const response = await goto(page, url);
    if (response && response.status() < 400) {
      return { url: response.url(), status: response.status() };
    }
  }
  return { url: urls[0], status: 0 };
}

async function findProduct(page) {
  return page.evaluate(() => {
    const candidates = Array.from(
      document.querySelectorAll('[data-product_id], [data-product-id], a.add_to_cart_button, button.ajax_add_to_cart')
    );
    for (const node of candidates) {
      const productId =
        node.getAttribute('data-product_id') ||
        node.getAttribute('data-product-id') ||
        node.getAttribute('data-productid') ||
        '';
      const href = node.getAttribute('href') || '';
      const url = node.closest('.product')?.querySelector('a')?.getAttribute('href') || '';
      if (productId || /add-to-cart=\d+/.test(href)) {
        return {
          productId: productId || (href.match(/add-to-cart=(\d+)/) || [])[1] || '',
          addToCartUrl: href || '',
          productUrl: url || '',
          buttonSelector: productId ? `[data-product_id="${productId}"]` : '',
        };
      }
    }
    return null;
  });
}

async function getCartSummary(page) {
  return page.evaluate(() => {
    const qtyInputs = Array.from(document.querySelectorAll('input.qty, input.qty-input, input[name*="quantity"]'));
    const quantities = qtyInputs.map((input) => ({
      name: input.getAttribute('name') || '',
      value: input.getAttribute('value') || input.value || '',
    }));
    const notices = Array.from(document.querySelectorAll('.woocommerce-error, .woocommerce-info, .woocommerce-message'))
      .map((node) => (node.textContent || '').replace(/\s+/g, ' ').trim())
      .filter(Boolean);
    return { quantities, notices };
  });
}

async function clearCart(page, cartUrl) {
  await goto(page, cartUrl);
  const removed = await page.evaluate(() => {
    const removeLinks = Array.from(document.querySelectorAll('.woocommerce-cart-form .remove, a.remove'));
    removeLinks.forEach((link) => (link instanceof HTMLElement ? link.click() : null));
    return removeLinks.length;
  });
  if (removed > 0) {
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
    await page.waitForTimeout(1200);
  }
  return removed;
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, context, page } = await launchWordPressBrowser(config);

  const consoleErrors = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
    }
  });

  try {
    const shop = await gotoFirstAvailable(page, [
      `${config.baseUrl}/boutique/`,
      `${config.baseUrl}/shop/`,
      `${config.baseUrl}/categorie/outillage-a-main/`,
      `${config.baseUrl}/`,
    ]);

    const product = await findProduct(page);

    const cartPage = await gotoFirstAvailable(page, [
      `${config.baseUrl}/panier/`,
      `${config.baseUrl}/cart/`,
    ]);

    await goto(page, cartPage.url);
    const cartCheckoutState = await page.evaluate(() => ({
      hasCheckoutButton: !!document.querySelector('.wc-proceed-to-checkout a.checkout-button, a.checkout-button'),
      fixesInstalled: !!window.__gamaCartFixesInstalled,
      proceedExists: !!document.querySelector('.wc-proceed-to-checkout, .gama-checkout-injected'),
      cartContainers: Array.from(document.querySelectorAll('[class*="cart"], [class*="totals"]'))
        .map((node) => node.className || '')
        .filter(Boolean)
        .slice(0, 40),
    }));
    const checkoutFromCart = await page.evaluate(() => {
      const checkoutLink = document.querySelector('.checkout-button, a.checkout-button, .wc-proceed-to-checkout a');
      const candidates = Array.from(document.querySelectorAll('a'))
        .map((link) => ({
          text: (link.textContent || '').replace(/\s+/g, ' ').trim(),
          href: link.getAttribute('href') || '',
        }))
        .filter((item) => /checkout|commande|commander|payment/i.test(item.href + item.text));

      return {
        checkoutUrl: checkoutLink ? checkoutLink.getAttribute('href') : '',
        candidates: candidates.slice(0, 12),
      };
    });

    const checkoutPage = await gotoFirstAvailable(page, [
      checkoutFromCart.checkoutUrl || '',
      `${config.baseUrl}/commander/`,
      `${config.baseUrl}/commande/`,
      `${config.baseUrl}/checkout/`,
    ].filter(Boolean));

    const test = {
      shop,
      product,
      cartPage,
      checkoutPage,
      checkoutFromCart,
      cartCheckoutState,
      addToCartViaUrl: null,
      addToCartViaClick: null,
      checkoutState: null,
      consoleErrors: [],
    };

    if (!product || !product.productId) {
      test.addToCartViaUrl = { error: 'No product found on shop page.' };
    } else {
      await clearCart(page, cartPage.url);

      const addUrl =
        product.addToCartUrl && product.addToCartUrl.includes('add-to-cart')
          ? new URL(product.addToCartUrl, config.baseUrl).toString()
          : `${config.baseUrl}/?add-to-cart=${encodeURIComponent(product.productId)}&quantity=1`;
      await goto(page, addUrl);
      await goto(page, cartPage.url);
      const summary = await getCartSummary(page);
      const cartStateAfterUrl = await page.evaluate(() => ({
        hasCheckoutButton: !!document.querySelector('.wc-proceed-to-checkout a.checkout-button, a.checkout-button'),
        proceedExists: !!document.querySelector('.wc-proceed-to-checkout, .gama-checkout-injected'),
        cartEmpty: !!document.querySelector('.cart-empty, .wc-empty-cart-message'),
      }));

      test.addToCartViaUrl = {
        addUrl,
        summary,
        cartState: cartStateAfterUrl,
      };

      await clearCart(page, cartPage.url);

      const ajaxRequests = [];
      page.on('request', (request) => {
        const url = request.url();
        if (url.includes('wc-ajax=add_to_cart') || url.includes('add-to-cart=')) {
          ajaxRequests.push(url);
        }
      });

      await goto(page, shop.url);

      if (product.buttonSelector) {
        await page.click(product.buttonSelector).catch(() => null);
        await page.waitForTimeout(1800);
      } else {
        await page.click('.add_to_cart_button, .ajax_add_to_cart').catch(() => null);
        await page.waitForTimeout(1800);
      }

      await goto(page, cartPage.url);
      const summaryAfterClick = await getCartSummary(page);
      const cartStateAfterClick = await page.evaluate(() => ({
        hasCheckoutButton: !!document.querySelector('.wc-proceed-to-checkout a.checkout-button, a.checkout-button'),
        proceedExists: !!document.querySelector('.wc-proceed-to-checkout, .gama-checkout-injected'),
        cartEmpty: !!document.querySelector('.cart-empty, .wc-empty-cart-message'),
      }));

      test.addToCartViaClick = {
        ajaxRequests,
        summary: summaryAfterClick,
        cartState: cartStateAfterClick,
      };
    }

    const checkoutUrl =
      checkoutFromCart.checkoutUrl ||
      `${config.baseUrl}/commande/`;

    await goto(page, checkoutUrl);
    const checkoutState = await page.evaluate(() => ({
      url: location.href,
      hasCheckoutForm: !!document.querySelector('form.checkout, form.woocommerce-checkout'),
      notices: Array.from(document.querySelectorAll('.woocommerce-error, .woocommerce-info, .woocommerce-message'))
        .map((node) => (node.textContent || '').replace(/\s+/g, ' ').trim())
        .filter(Boolean),
      blockedButtons: Array.from(document.querySelectorAll('button, input[type="submit"]'))
        .filter((btn) => btn.disabled)
        .map((btn) => (btn.textContent || btn.getAttribute('value') || '').trim())
        .filter(Boolean)
        .slice(0, 10),
    }));

    test.checkoutState = checkoutState;
    test.consoleErrors = consoleErrors.slice(0, 20);

    writeReport('diagnose-cart-checkout.json', {
      updatedAt: new Date().toISOString(),
      test,
    });

    console.log(JSON.stringify({ ok: true, test }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
