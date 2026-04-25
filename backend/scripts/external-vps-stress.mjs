import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { performance } from "node:perf_hooks";

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const backendDir = path.resolve(__dirname, "..");
const resultsDir = path.join(backendDir, "stress-results");

const round = (value, digits = 2) => Number.parseFloat(Number(value).toFixed(digits));

const percentile = (values, p) => {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
  return sorted[index];
};

const nowIso = () => new Date().toISOString();

const decodeBody = async (response) => {
  const text = await response.text();
  if (!text) return null;

  try {
    return JSON.parse(text);
  } catch {
    return text.slice(0, 400);
  }
};

const fetchOnce = async (target) => {
  const startedAt = performance.now();
  const response = await fetch(target.url, {
    method: target.method || "GET",
    headers: target.headers || {}
  });
  const elapsedMs = performance.now() - startedAt;
  const body = await decodeBody(response);

  return {
    elapsedMs,
    status: response.status,
    headers: {
      server: response.headers.get("server"),
      rateLimitLimit: response.headers.get("ratelimit-limit"),
      rateLimitRemaining: response.headers.get("ratelimit-remaining"),
      cfCacheStatus: response.headers.get("cf-cache-status")
    },
    body
  };
};

const runScenario = async ({
  name,
  target,
  totalRequests,
  concurrency,
  successStatuses
}) => {
  const latencies = [];
  const statusCounts = {};
  const samples = [];
  const headerSnapshots = [];
  let index = 0;
  const startedAt = performance.now();

  const worker = async () => {
    while (true) {
      const current = index;
      index += 1;
      if (current >= totalRequests) {
        return;
      }

      try {
        const result = await fetchOnce(target);
        latencies.push(result.elapsedMs);
        const statusKey = String(result.status);
        statusCounts[statusKey] = (statusCounts[statusKey] || 0) + 1;

        if (headerSnapshots.length < 3) {
          headerSnapshots.push(result.headers);
        }

        if (!successStatuses.includes(result.status) && samples.length < 5) {
          samples.push({
            index: current,
            status: result.status,
            body: result.body
          });
        }
      } catch (error) {
        const statusKey = "NETWORK_ERROR";
        statusCounts[statusKey] = (statusCounts[statusKey] || 0) + 1;
        if (samples.length < 5) {
          samples.push({
            index: current,
            status: statusKey,
            body: error?.message || String(error)
          });
        }
      }
    }
  };

  await Promise.all(Array.from({ length: concurrency }, () => worker()));

  const durationMs = performance.now() - startedAt;
  const successCount = successStatuses.reduce(
    (sum, status) => sum + (statusCounts[String(status)] || 0),
    0
  );

  return {
    name,
    url: target.url,
    total_requests: totalRequests,
    concurrency,
    duration_ms: round(durationMs),
    requests_per_second: round((totalRequests / durationMs) * 1000),
    success_count: successCount,
    success_rate: round((successCount / totalRequests) * 100, 1),
    latency_ms: {
      min: round(Math.min(...latencies)),
      avg: round(latencies.reduce((sum, value) => sum + value, 0) / latencies.length),
      p50: round(percentile(latencies, 50)),
      p95: round(percentile(latencies, 95)),
      max: round(Math.max(...latencies))
    },
    status_counts: statusCounts,
    header_snapshots: headerSnapshots,
    error_samples: samples
  };
};

const targets = [
  {
    key: "cf_health",
    url: "https://tawsilapp.com/api/health",
    successStatuses: [200]
  },
  {
    key: "cf_announcement_active",
    url: "https://tawsilapp.com/api/announcement/getactive",
    successStatuses: [200]
  },
  {
    key: "cf_restaurant_getall",
    url: "https://tawsilapp.com/api/restaurant/getall",
    successStatuses: [200]
  },
  {
    key: "cf_orderitem_getall",
    url: "https://tawsilapp.com/api/orderitem/getall",
    successStatuses: [200]
  },
  {
    key: "cf_order_noauth",
    url: "https://tawsilapp.com/api/order",
    successStatuses: [401]
  },
  {
    key: "origin_health",
    url: "https://197.140.29.107/api/health",
    successStatuses: [200]
  },
  {
    key: "origin_orderitem_getall",
    url: "https://197.140.29.107/api/orderitem/getall",
    successStatuses: [200]
  }
];

const buildScenarios = () => {
  const scenarios = [];

  for (const target of targets) {
    scenarios.push({
      name: `Sequential ${target.key}`,
      target,
      totalRequests: 8,
      concurrency: 1,
      successStatuses: target.successStatuses
    });
  }

  for (const target of targets) {
    const isHeavy = target.key.includes("orderitem") || target.key.includes("restaurant");
    scenarios.push({
      name: `Concurrent ${target.key}`,
      target,
      totalRequests: isHeavy ? 15 : 20,
      concurrency: 5,
      successStatuses: target.successStatuses
    });
  }

  return scenarios;
};

const main = async () => {
  await fs.mkdir(resultsDir, { recursive: true });

  const scenarios = buildScenarios();
  const results = [];

  for (const scenario of scenarios) {
    const result = await runScenario(scenario);
    results.push(result);
    console.log(
      `${result.name}: ${result.success_rate}% success | avg ${result.latency_ms.avg}ms | p95 ${result.latency_ms.p95}ms | ${result.requests_per_second} req/s`
    );
  }

  const report = {
    generated_at: nowIso(),
    mode: "external vps/domain stress test",
    notes: [
      "Targets are intentionally limited to stay below the public rate limit budget.",
      "Direct origin requests use the VPS IP over HTTPS with TLS verification disabled for this measurement."
    ],
    results
  };

  const outputPath = path.join(resultsDir, "external-vps-stress-report.json");
  await fs.writeFile(outputPath, JSON.stringify(report, null, 2), "utf8");
  console.log(`\nReport written to ${outputPath}`);
};

main().catch((error) => {
  console.error("External VPS stress test failed:", error);
  process.exitCode = 1;
});
