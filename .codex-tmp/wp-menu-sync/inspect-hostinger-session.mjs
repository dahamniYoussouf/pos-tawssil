import fs from 'fs';
import path from 'path';
import { chromium } from 'playwright-core';

const outDir = path.resolve('.codex-tmp/wp-menu-sync/out');
const browserPath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const userDataDir = 'C:\\Users\\YoucefDahamni\\AppData\\Local\\Google\\Chrome\\User Data';

function summarizeText(text) {
  return String(text || '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 3000);
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const context = await chromium.launchPersistentContext(userDataDir, {
    executablePath: browserPath,
    headless: true,
    args: ['--profile-directory=Default'],
    viewport: { width: 1440, height: 1100 },
  });

  const page = context.pages()[0] || (await context.newPage());

  try {
    await page.goto('https://hpanel.hostinger.com/', { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => null);
    await page.screenshot({ path: path.join(outDir, 'hostinger-session.png'), fullPage: true });

    const report = await page.evaluate(() => {
      const bodyText = document.body?.innerText || '';
      const fields = Array.from(document.querySelectorAll('input, button, a'))
        .slice(0, 100)
        .map((node) => ({
          tag: node.tagName.toLowerCase(),
          type: node.getAttribute('type') || '',
          text: (node.textContent || '').trim().slice(0, 120),
          name: node.getAttribute('name') || '',
          id: node.id || '',
          href: node.getAttribute('href') || '',
        }));

      return {
        url: location.href,
        title: document.title,
        bodyText,
        fields,
      };
    });

    const summary = {
      checkedAt: new Date().toISOString(),
      url: report.url,
      title: report.title,
      bodyTextPreview: summarizeText(report.bodyText),
      fields: report.fields,
    };

    fs.writeFileSync(path.join(outDir, 'hostinger-session.json'), `${JSON.stringify(summary, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(summary, null, 2));
  } finally {
    await context.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
