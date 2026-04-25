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
  await page.waitForTimeout(1200);
}

async function readSelectedOption(page, selector) {
  return page.evaluate((sel) => {
    const select = document.querySelector(sel);
    if (!(select instanceof HTMLSelectElement)) return null;
    const option = select.selectedOptions?.[0];
    return {
      value: option?.value || '',
      label: (option?.textContent || '').replace(/\s+/g, ' ').trim(),
    };
  }, selector);
}

async function readCheckbox(page, selector) {
  return page.evaluate((sel) => {
    const input = document.querySelector(sel);
    if (!(input instanceof HTMLInputElement)) return null;
    return {
      checked: input.checked,
      value: input.value,
    };
  }, selector);
}

async function fetchPageContent(baseUrl, pageId) {
  if (!pageId) return null;
  const response = await fetch(`${baseUrl}/wp-json/wp/v2/pages/${pageId}?context=edit`, {
    headers: {
      'user-agent': 'Codex Woo Settings Inspector',
    },
  }).catch(() => null);
  if (!response || !response.ok) return null;
  const data = await response.json().catch(() => null);
  if (!data) return null;
  return {
    id: data.id,
    title: data.title?.rendered || '',
    status: data.status || '',
    content: (data.content?.rendered || '').slice(0, 2000),
  };
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=wc-settings&tab=advanced`);
    const cartPage = await readSelectedOption(page, '#woocommerce_cart_page_id');
    const checkoutPage = await readSelectedOption(page, '#woocommerce_checkout_page_id');
    const myAccountPage = await readSelectedOption(page, '#woocommerce_myaccount_page_id');

    await goto(page, `${config.baseUrl}/wp-admin/admin.php?page=wc-settings&tab=account`);
    const guestCheckout = await readCheckbox(page, '#woocommerce_enable_guest_checkout');
    const signupFromCheckout = await readCheckbox(page, '#woocommerce_enable_signup_and_login_from_checkout');

    const cartContent = cartPage?.value ? await fetchPageContent(config.baseUrl, cartPage.value) : null;
    const checkoutContent = checkoutPage?.value ? await fetchPageContent(config.baseUrl, checkoutPage.value) : null;

    const report = {
      updatedAt: new Date().toISOString(),
      cartPage,
      checkoutPage,
      myAccountPage,
      guestCheckout,
      signupFromCheckout,
      cartContent,
      checkoutContent,
    };

    writeReport('inspect-woo-settings.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
