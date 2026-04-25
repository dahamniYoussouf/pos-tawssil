import fs from 'fs';
import path from 'path';

const htmlPath = path.join('backend', 'scripts', 'wordpress', 'out', 'homepage.html');
const html = fs.readFileSync(htmlPath, 'utf8');

function collectUrls(pattern) {
  const urls = new Set();
  let match;
  while ((match = pattern.exec(html)) !== null) {
    const url = match[1];
    if (url && /^https?:\/\//i.test(url)) {
      urls.add(url);
    }
  }
  return urls;
}

const srcUrls = collectUrls(/(?:src|data-src|data-lazy-src|data-original)\s*=\s*["']([^"']+)["']/gi);
const srcsetUrls = new Set();
let srcsetMatch;
const srcsetRegex = /srcset\s*=\s*["']([^"']+)["']/gi;
while ((srcsetMatch = srcsetRegex.exec(html)) !== null) {
  const entries = srcsetMatch[1].split(',');
  for (const entry of entries) {
    const url = entry.trim().split(/\s+/)[0];
    if (url && /^https?:\/\//i.test(url)) {
      srcsetUrls.add(url);
    }
  }
}

const allUrls = Array.from(new Set([...srcUrls, ...srcsetUrls])).filter((url) =>
  /\.(png|jpe?g|webp|gif|svg)(\?|$)/i.test(url)
);

async function headSize(url) {
  try {
    const response = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    const length = response.headers.get('content-length');
    return {
      url,
      status: response.status,
      size: length ? Number(length) : null,
      contentType: response.headers.get('content-type') || '',
    };
  } catch (error) {
    return { url, status: 0, size: null, contentType: '', error: String(error) };
  }
}

const MAX_URLS = 200;
const results = [];
const sample = allUrls.slice(0, MAX_URLS);
let index = 0;
const CONCURRENCY = 8;

async function worker() {
  while (index < sample.length) {
    const current = sample[index];
    index += 1;
    results.push(await headSize(current));
  }
}

const workers = Array.from({ length: CONCURRENCY }, () => worker());
await Promise.all(workers);

results.sort((a, b) => (b.size || 0) - (a.size || 0));

const report = {
  updatedAt: new Date().toISOString(),
  totalImages: allUrls.length,
  sampled: results.length,
  largest: results.slice(0, 30),
};

const outPath = path.join('backend', 'scripts', 'wordpress', 'out', 'homepage-image-sizes.json');
fs.writeFileSync(outPath, JSON.stringify(report, null, 2));

console.log(JSON.stringify(report, null, 2));
