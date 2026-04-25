import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function findAdminLink(page, candidates) {
  return page.evaluate((patterns) => {
    const links = Array.from(document.querySelectorAll('#adminmenu a'));
    const match = links.find((link) => {
      const text = (link.textContent || '').trim().toLowerCase();
      const href = (link.getAttribute('href') || '').toLowerCase();
      return patterns.some((pattern) => text.includes(pattern) || href.includes(pattern));
    });

    return match
      ? {
          text: (match.textContent || '').trim(),
          href: match.href,
          rawHref: match.getAttribute('href') || '',
        }
      : null;
  }, candidates.map((candidate) => candidate.toLowerCase()));
}

async function findAdminLinks(page, candidates) {
  return page.evaluate((patterns) => {
    return Array.from(document.querySelectorAll('#adminmenu a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href,
        rawHref: link.getAttribute('href') || '',
      }))
      .filter((link) => {
        const text = link.text.toLowerCase();
        const href = link.rawHref.toLowerCase();
        return patterns.some((pattern) => text.includes(pattern) || href.includes(pattern));
      });
  }, candidates.map((candidate) => candidate.toLowerCase()));
}

async function captureFeedsPage(page) {
  const tableRows = await page.evaluate(() =>
    Array.from(document.querySelectorAll('table.wp-list-table tbody tr'))
      .map((row) => {
        const cells = Array.from(row.querySelectorAll('td'));
        if (!cells.length) return null;

        const feedName = cells[1]?.innerText?.trim() || '';
        const category = cells[4]?.innerText?.trim() || '';
        const products = cells[5]?.innerText?.trim() || '';
        const updated = cells[6]?.innerText?.trim() || '';

        return {
          feedName,
          category,
          products,
          updated,
          rowText: row.innerText.trim(),
        };
      })
      .filter(Boolean)
  );

  const pageText = await page.locator('body').innerText();

  return {
    url: page.url(),
    rows: tableRows,
    pageText,
  };
}

async function captureGenericAdminPage(page) {
  const title = await page.title();
  const bodyText = await page.locator('body').innerText();
  const links = await page.evaluate(() =>
    Array.from(document.querySelectorAll('a'))
      .map((link) => ({
        text: (link.textContent || '').trim(),
        href: link.href,
        rawHref: link.getAttribute('href') || '',
      }))
      .filter((link) => link.text || link.rawHref)
  );

  return {
    url: page.url(),
    title,
    bodyText,
    links,
  };
}

async function captureSpecificPages(page, links) {
  const pages = [];
  const seen = new Set();

  for (const link of links) {
    if (!link?.href || seen.has(link.href)) continue;
    seen.add(link.href);
    await page.goto(link.href, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle');
    pages.push({
      target: link,
      captured: await captureGenericAdminPage(page),
    });
  }

  return pages;
}

async function captureCronPage(page) {
  const bodyText = await page.locator('body').innerText();

  const cronRows = await page.evaluate(() =>
    Array.from(document.querySelectorAll('table.wp-list-table tbody tr'))
      .map((row) => row.innerText.trim())
      .filter(Boolean)
  );

  return {
    url: page.url(),
    bodyText,
    rows: cronRows,
  };
}

async function captureSiteHealth(page) {
  const bodyText = await page.locator('body').innerText();
  return {
    url: page.url(),
    bodyText,
  };
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);
    await page.goto(`${config.baseUrl}/wp-admin/`, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle');

    const feedLink =
      (await findAdminLink(page, [
        'product catalog feed',
        'woo feed',
        'feed',
        'webappick',
      ])) || null;

    const feedLinks =
      (await findAdminLinks(page, [
        'product catalog',
        'feed',
        'wpwoof',
        'woo-feed',
        'webappick',
        'scheduled job',
      ])) || [];

    const cronLink =
      (await findAdminLink(page, [
        'cron events',
        'crontrol',
      ])) || null;

    const siteHealthLink =
      (await findAdminLink(page, [
        'site health',
        'santé du site',
      ])) || null;

    let feeds = null;
    let feedPages = [];
    const feedTargets = feedLink?.href ? [feedLink, ...feedLinks] : feedLinks;
    const seenFeedTargets = new Set();

    for (const target of feedTargets) {
      if (!target?.href || seenFeedTargets.has(target.href)) continue;
      seenFeedTargets.add(target.href);
      await page.goto(target.href, { waitUntil: 'domcontentloaded' });
      await page.waitForLoadState('networkidle');
      const captured = await captureGenericAdminPage(page);
      feedPages.push({ target, captured });

      if (!feeds && /feed|catalog/i.test(captured.title + '\n' + captured.bodyText)) {
        feeds = await captureFeedsPage(page);
      }
    }

    const extraFeedLinks =
      feedPages
        .flatMap((entry) => entry.captured.links)
        .filter((link) => /wpwoof-settings/.test(link.href) && /tab=logs|tab=feeds|paged=2/.test(link.href)) || [];

    const extraFeedPages = await captureSpecificPages(page, extraFeedLinks);

    let cron = null;
    if (cronLink?.href) {
      await page.goto(cronLink.href, { waitUntil: 'domcontentloaded' });
      await page.waitForLoadState('networkidle');
      cron = await captureCronPage(page);
    }

    let siteHealth = null;
    if (siteHealthLink?.href) {
      await page.goto(siteHealthLink.href, { waitUntil: 'domcontentloaded' });
      await page.waitForLoadState('networkidle');
      siteHealth = await captureSiteHealth(page);
    }

    const report = {
      checkedAt: new Date().toISOString(),
      feedLink,
      feedLinks,
      feedPages,
      extraFeedPages,
      cronLink,
      siteHealthLink,
      feeds,
      cron,
      siteHealth,
    };

    writeReport('audit-feed-automation.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
