const baseUrl = 'https://gamaoutillage.net/wp-content/uploads/2025/12/FR';
const baseUrlAr = 'https://gamaoutillage.net/wp-content/uploads/2025/12/AR';
const sizes = [64, 96, 120, 150, 180, 256, 300, 384, 512, 768, 1024];

async function head(url) {
  try {
    const res = await fetch(url, { method: 'HEAD', redirect: 'follow' });
    return {
      url,
      status: res.status,
      size: res.headers.get('content-length') ? Number(res.headers.get('content-length')) : null,
    };
  } catch (error) {
    return { url, status: 0, size: null, error: String(error) };
  }
}

async function main() {
  const results = [];
  for (const size of sizes) {
    results.push(await head(`${baseUrl}-${size}x${size}.png`));
    results.push(await head(`${baseUrlAr}-${size}x${size}.png`));
  }

  results.push(await head(`${baseUrl}-1024x1024.png`));
  results.push(await head(`${baseUrlAr}-1024x1024.png`));

  console.log(JSON.stringify(results.filter((r) => r.status === 200), null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
