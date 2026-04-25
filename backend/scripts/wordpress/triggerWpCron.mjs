import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { loadWordPressSyncEnv } from './productCategoryMenuSync.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const outDir = path.join(__dirname, 'out');

function parseArgs(argv) {
  const args = {};

  for (let index = 0; index < argv.length; index += 1) {
    const current = argv[index];
    if (!current.startsWith('--')) continue;

    const key = current.slice(2);
    const next = argv[index + 1];

    if (!next || next.startsWith('--')) {
      args[key] = 'true';
      continue;
    }

    args[key] = next;
    index += 1;
  }

  return args;
}

function normalizeBaseUrl(value) {
  return String(value || '').trim().replace(/\/+$/, '');
}

function resolveBaseUrl(cliArgs) {
  loadWordPressSyncEnv();

  const baseUrl = normalizeBaseUrl(cliArgs['base-url'] || process.env.WP_BASE_URL);
  if (!baseUrl) {
    throw new Error('Missing WordPress base URL. Pass --base-url or set WP_BASE_URL.');
  }

  return baseUrl;
}

function resolveTimeoutMs(cliArgs) {
  const parsed = Number(cliArgs['timeout-ms'] || process.env.WP_CRON_TIMEOUT_MS || 45000);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 45000;
}

function writeReport(report) {
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(path.join(outDir, 'trigger-wp-cron.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf8');
}

async function main() {
  const cliArgs = parseArgs(process.argv.slice(2));
  const baseUrl = resolveBaseUrl(cliArgs);
  const timeoutMs = resolveTimeoutMs(cliArgs);
  const requestUrl = `${baseUrl}/wp-cron.php?doing_wp_cron=${Date.now()}`;
  const controller = new AbortController();
  const startedAt = new Date().toISOString();
  const timeoutHandle = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(requestUrl, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        'user-agent': 'codex-wordpress-cron-trigger/1.0',
        'cache-control': 'no-cache',
      },
    });

    const body = await response.text();
    const report = {
      startedAt,
      finishedAt: new Date().toISOString(),
      ok: response.ok,
      status: response.status,
      statusText: response.statusText,
      requestUrl,
      responsePreview: body.slice(0, 500),
    };

    writeReport(report);

    if (!response.ok) {
      throw new Error(`wp-cron request failed with status ${response.status}.`);
    }

    console.log(JSON.stringify(report, null, 2));
  } finally {
    clearTimeout(timeoutHandle);
  }
}

main().catch((error) => {
  const report = {
    startedAt: new Date().toISOString(),
    ok: false,
    error: error.stack || error.message || String(error),
  };
  writeReport(report);
  console.error(report.error);
  process.exit(1);
});
