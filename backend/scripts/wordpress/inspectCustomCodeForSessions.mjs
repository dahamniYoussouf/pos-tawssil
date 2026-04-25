import {
  launchWordPressBrowser,
  loginToWordPress,
  resolveSyncConfig,
  writeReport,
} from './productCategoryMenuSync.mjs';

function normalizeText(value) {
  return String(value || '')
    .replace(/\s+/g, ' ')
    .trim();
}

function truncate(value, size = 1500) {
  return String(value || '').slice(0, size);
}

async function gotoAdminPage(page, config, adminPath) {
  await page.goto(`${config.baseUrl}/wp-admin/${adminPath}`, {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1200);
}

async function collectCodeSnippets(page, config) {
  await gotoAdminPage(page, config, 'admin.php?page=snippets');

  return page.evaluate(() =>
    Array.from(document.querySelectorAll('#the-list tr, .wp-list-table tbody tr'))
      .map((row) => {
        const titleLink =
          row.querySelector('.row-title') ||
          row.querySelector('.snippet-title a') ||
          row.querySelector('strong a');

        if (!titleLink) return null;

        const actions = Array.from(row.querySelectorAll('.row-actions a')).map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href,
        }));

        return {
          title: (titleLink.textContent || '').trim(),
          editHref: titleLink.href || actions.find((item) => /edit|modifier/i.test(item.text))?.href || '',
          rowText: (row.textContent || '').replace(/\s+/g, ' ').trim(),
          actions,
        };
      })
      .filter(Boolean)
  );
}

async function readCodeSnippet(page, snippet) {
  if (!snippet.editHref) {
    return {
      ...snippet,
      source: 'code-snippets',
      code: '',
      matched: false,
    };
  }

  await page.goto(snippet.editHref, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1000);

  const payload = await page.evaluate(() => {
    const title =
      document.querySelector('#title')?.value ||
      document.querySelector('input[name="snippet_name"]')?.value ||
      document.title;

    const textareaCandidates = Array.from(document.querySelectorAll('textarea')).map((node) => ({
      id: node.id || '',
      name: node.getAttribute('name') || '',
      value: node.value || '',
    }));

    const code =
      document.querySelector('.CodeMirror')?.CodeMirror?.getValue?.() ||
      textareaCandidates.find((item) => item.value && item.value.length > 20)?.value ||
      '';

    return {
      title,
      code,
      textareaCandidates,
      bodyPreview: (document.body?.innerText || '').slice(0, 2500),
    };
  });

  const matched = /(session_start|phpsessid|\$_session|\bsession\b)/i.test(payload.code);

  return {
    ...snippet,
    source: 'code-snippets',
    title: normalizeText(payload.title || snippet.title),
    code: payload.code,
    matched,
    bodyPreview: payload.bodyPreview,
  };
}

async function collectHfcmSnippets(page, config) {
  await gotoAdminPage(page, config, 'admin.php?page=hfcm-list');

  return page.evaluate(() =>
    Array.from(document.querySelectorAll('table tbody tr'))
      .map((row) => {
        const links = Array.from(row.querySelectorAll('a')).map((link) => ({
          text: (link.textContent || '').trim(),
          href: link.href,
        }));

        const editHref = links.find((item) => /edit|modifier/i.test(item.text))?.href || links[0]?.href || '';
        const title = links[0]?.text || row.querySelector('strong')?.textContent || '';

        if (!title) return null;

        return {
          title: title.trim(),
          editHref,
          rowText: (row.textContent || '').replace(/\s+/g, ' ').trim(),
          links,
        };
      })
      .filter(Boolean)
  );
}

async function readHfcmSnippet(page, snippet) {
  if (!snippet.editHref) {
    return {
      ...snippet,
      source: 'hfcm',
      code: '',
      matched: false,
    };
  }

  await page.goto(snippet.editHref, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
  await page.waitForTimeout(1000);

  const payload = await page.evaluate(() => {
    const fields = Array.from(document.querySelectorAll('textarea, input[type="text"], input[type="search"]')).map(
      (node) => ({
        id: node.id || '',
        name: node.getAttribute('name') || '',
        value: node.value || '',
      })
    );

    const code =
      document.querySelector('.CodeMirror')?.CodeMirror?.getValue?.() ||
      fields.find((item) => item.value && item.value.length > 20)?.value ||
      '';

    return {
      title:
        document.querySelector('input[name="name"]')?.value ||
        document.querySelector('#title')?.value ||
        document.title,
      code,
      bodyPreview: (document.body?.innerText || '').slice(0, 2500),
      fields,
    };
  });

  const matched = /(session_start|phpsessid|\$_session|\bsession\b)/i.test(payload.code);

  return {
    ...snippet,
    source: 'hfcm',
    title: normalizeText(payload.title || snippet.title),
    code: payload.code,
    matched,
    bodyPreview: payload.bodyPreview,
  };
}

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const codeSnippets = await collectCodeSnippets(page, config);
    const codeSnippetDetails = [];
    for (const snippet of codeSnippets.slice(0, 20)) {
      codeSnippetDetails.push(await readCodeSnippet(page, snippet));
    }

    const hfcmSnippets = await collectHfcmSnippets(page, config);
    const hfcmDetails = [];
    for (const snippet of hfcmSnippets.slice(0, 20)) {
      hfcmDetails.push(await readHfcmSnippet(page, snippet));
    }

    const report = {
      updatedAt: new Date().toISOString(),
      codeSnippets: codeSnippetDetails.map((item) => ({
        source: item.source,
        title: item.title,
        editHref: item.editHref,
        matched: item.matched,
        codePreview: truncate(item.code),
        bodyPreview: item.bodyPreview,
      })),
      hfcmSnippets: hfcmDetails.map((item) => ({
        source: item.source,
        title: item.title,
        editHref: item.editHref,
        matched: item.matched,
        codePreview: truncate(item.code),
        bodyPreview: item.bodyPreview,
      })),
    };

    writeReport('inspect-custom-code-for-sessions.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
