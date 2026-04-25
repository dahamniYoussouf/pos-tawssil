import fs from 'fs';
import path from 'path';
import { chromium } from 'playwright-core';

const outDir = path.resolve('scripts/wordpress/out');

function parseArgs(argv) {
  const result = {};

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith('--')) continue;

    const key = token.slice(2);
    const next = argv[index + 1];
    if (!next || next.startsWith('--')) {
      result[key] = 'true';
      continue;
    }

    result[key] = next;
    index += 1;
  }

  return result;
}

function resolveConfig() {
  const args = parseArgs(process.argv.slice(2));
  const domain = args.domain || process.env.HOSTINGER_DOMAIN || 'gamaoutillage.net';
  const schedule = args.schedule || process.env.HOSTINGER_CRON_SCHEDULE || '*/5 * * * *';
  const command =
    args.command ||
    process.env.HOSTINGER_CRON_COMMAND ||
    `wget -q -O /dev/null https://${domain}/wp-cron.php?doing_wp_cron`;
  const cdpUrl = args['cdp-url'] || process.env.HOSTINGER_CDP_URL || 'http://127.0.0.1:9222';

  return {
    domain,
    schedule,
    command,
    cdpUrl,
    cronUrl: `https://hpanel.hostinger.com/websites/${domain}/advanced/cron-jobs?redirectLocation=side_menu`,
  };
}

async function getHostingerPage(browser) {
  for (const context of browser.contexts()) {
    for (const page of context.pages()) {
      if (/hostinger\.com/i.test(page.url())) {
        return page;
      }
    }
  }

  const [firstContext] = browser.contexts();
  return firstContext.newPage();
}

async function collectState(page) {
  return page.evaluate(() => ({
    url: location.href,
    title: document.title,
    bodyText: document.body?.innerText || '',
    commandValue: document.querySelector('#cron-job-command')?.value || '',
    scheduleValue: document.querySelector('#cron-job-common-options')?.value || '',
    buttons: Array.from(document.querySelectorAll('button'))
      .map((button) => ({
        text: (button.textContent || '').trim(),
        qa: button.getAttribute('data-qa') || '',
        disabled: button.disabled,
      }))
      .filter((item) => item.text || item.qa)
      .slice(0, 100),
  }));
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true });

  const config = resolveConfig();
  const browser = await chromium.connectOverCDP(config.cdpUrl);

  try {
    const page = await getHostingerPage(browser);

    await page.goto(config.cronUrl, { waitUntil: 'domcontentloaded' });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);

    const before = await collectState(page);
    const alreadyExists = before.bodyText.includes('wp-cron.php');

    let status = 'already_exists';

    if (!alreadyExists) {
      await page.getByText('Custom', { exact: true }).click({ timeout: 15000 }).catch(() => null);
      await page.fill('#cron-job-command', config.command);

      const choosePreset = async (fieldName, optionText) => {
        const field = page.locator(`[name="${fieldName}"] input.field__input--dropdown`).first();
        await field.click({ force: true });
        await page.waitForTimeout(300);
        await page.locator('.hp-list-item', { hasText: optionText }).first().click({ timeout: 15000 });
        await page.waitForTimeout(300);
      };

      await choosePreset('minute', 'Every 5 minutes (*/5)');
      await choosePreset('hour', 'Every Hour (*)');
      await choosePreset('day', 'Every Day (*)');
      await choosePreset('month', 'Every Month (*)');
      await choosePreset('weekDay', 'Every Weekday (*)');

      await page.getByRole('button', { name: 'Save' }).click({ timeout: 15000 });
      await page.waitForTimeout(4000);
      await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => null);
      status = 'created_or_updated';
    }

    const after = await collectState(page);

    const report = {
      checkedAt: new Date().toISOString(),
      status,
      domain: config.domain,
      schedule: config.schedule,
      command: config.command,
      before: {
        url: before.url,
        title: before.title,
        commandValue: before.commandValue,
        scheduleValue: before.scheduleValue,
        bodyText: before.bodyText.slice(0, 15000),
      },
      after: {
        url: after.url,
        title: after.title,
        commandValue: after.commandValue,
        scheduleValue: after.scheduleValue,
        bodyText: after.bodyText.slice(0, 15000),
      },
    };

    await page.screenshot({
      path: path.join(outDir, 'hostinger-cron-after-save.png'),
      fullPage: true,
    }).catch(() => null);

    fs.writeFileSync(path.join(outDir, 'hostinger-cron-create.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
