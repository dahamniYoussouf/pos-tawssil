import { launchWordPressBrowser, loginToWordPress, resolveSyncConfig } from './productCategoryMenuSync.mjs';

const config = resolveSyncConfig();
const { browser, page } = await launchWordPressBrowser(config);

try {
  await loginToWordPress(page, config);
  await page.goto(`${config.baseUrl}/wp-admin/post.php?post=2124&action=edit`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(2000);

  const data = await page.evaluate(() => {
    const content = document.querySelector('#content');
    return {
      title: document.title,
      hasContent: !!content,
      contentPreview: content && 'value' in content ? content.value.slice(0, 6000) : '',
      bodyText: (document.body?.innerText || '').slice(0, 4000),
    };
  });

  console.log(JSON.stringify(data, null, 2));
} finally {
  await browser.close();
}
