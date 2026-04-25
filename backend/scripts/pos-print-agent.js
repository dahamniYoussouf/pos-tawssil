import axios from "axios";
import { io } from "socket.io-client";
import { printOrderOnPrinter } from "../src/services/printService.js";

const BACKEND_URL = (process.env.POS_BACKEND_URL || "http://localhost:3000").replace(/\/$/, "");
const API_PREFIX = process.env.POS_API_PREFIX || "/api";
const SOCKET_PATH = process.env.POS_SOCKET_PATH || "/socket.io";
const TOKEN = process.env.POS_TOKEN;
const POLL_INTERVAL_MS = Number(process.env.POS_POLL_INTERVAL_MS || 15000);
const USE_TEMPLATE = String(process.env.POS_USE_TEMPLATE || "").toLowerCase() === "true";

if (!TOKEN) {
  console.error("[POS] Missing POS_TOKEN in environment.");
  process.exit(1);
}

const api = axios.create({
  baseURL: `${BACKEND_URL}${API_PREFIX}`,
  headers: {
    Authorization: `Bearer ${TOKEN}`,
    "Content-Type": "application/json",
  },
  timeout: 20000,
});

const inFlight = new Set();

function log(...args) {
  console.log("[POS]", ...args);
}

async function claimPrintJob(jobId) {
  const { data } = await api.post(`/cashier/print-jobs/${jobId}/claim`);
  return data?.data;
}

async function completePrintJob(jobId, success, errorMessage = null) {
  await api.post(`/cashier/print-jobs/${jobId}/complete`, {
    success,
    error_message: errorMessage || undefined,
  });
}

async function printJob(jobId) {
  if (inFlight.has(jobId)) return;
  inFlight.add(jobId);
  let claimed = false;
  try {
    const payload = await claimPrintJob(jobId);
    claimed = true;
    if (!payload) {
      log("Claim returned empty payload for job", jobId);
      return;
    }

    const { order, printer } = payload;
    const restaurantName =
      order?.restaurant?.name ||
      order?.restaurant_name ||
      order?.restaurant?.nom ||
      "Restaurant";

    const result = await printOrderOnPrinter(printer, order, restaurantName, {
      useTemplate: USE_TEMPLATE,
      cashierName: order?.cashier?.name || order?.created_by_cashier?.name || null,
      cashierCode: order?.cashier?.cashier_code || order?.created_by_cashier?.cashier_code || null,
    });

    if (result?.ok) {
      log(`Printed job ${jobId} on "${result.printerName || printer?.name}"`);
      await completePrintJob(jobId, true);
    } else {
      const errMsg = result?.error || "Print failed";
      log(`Print failed for job ${jobId}:`, errMsg);
      await completePrintJob(jobId, false, errMsg);
    }
  } catch (err) {
    const status = err?.response?.status;
    const msg = err?.response?.data?.message || err?.message || String(err);
    log(`Job ${jobId} error:`, msg);
    if (claimed) {
      try {
        await completePrintJob(jobId, false, msg);
      } catch (completeErr) {
        log(`Failed to complete job ${jobId}:`, completeErr?.message || completeErr);
      }
    } else if (status && [400, 401, 403, 404].includes(status)) {
      // Not claimed, nothing to complete.
      return;
    }
  } finally {
    inFlight.delete(jobId);
  }
}

async function fetchPendingJobs() {
  const { data } = await api.get("/cashier/print-jobs/pending");
  return data?.data || [];
}

async function handleQueuedEvent(payload = {}) {
  const jobId = payload.job_id;
  if (jobId) {
    await printJob(jobId);
    return;
  }

  // Some emitters don't include job_id (legacy)
  const pending = await fetchPendingJobs();
  if (!pending.length) return;

  const orderId = payload.order_id;
  const printerId = payload.printer_id;
  const restaurantId = payload.restaurant_id;

  const candidates = pending.filter((job) => {
    if (orderId && job.order_id !== orderId) return false;
    if (printerId && job.printer_id !== printerId) return false;
    if (restaurantId && job.restaurant_id !== restaurantId) return false;
    return true;
  });

  for (const job of candidates) {
    await printJob(job.id);
  }
}

async function pollPending() {
  try {
    const pending = await fetchPendingJobs();
    for (const job of pending) {
      await printJob(job.id);
    }
  } catch (err) {
    log("Polling error:", err?.message || err);
  }
}

const socket = io(BACKEND_URL, {
  path: SOCKET_PATH,
  transports: ["websocket"],
  auth: { token: TOKEN },
});

socket.on("connect", () => {
  log("Socket connected:", socket.id);
});

socket.on("print_job:queued", (payload) => {
  log("print_job:queued", payload?.job_id || "");
  handleQueuedEvent(payload).catch((err) => log("Queue handler error:", err?.message || err));
});

socket.on("connect_error", (err) => {
  log("Socket error:", err?.message || err);
});

socket.on("disconnect", (reason) => {
  log("Socket disconnected:", reason);
});

if (POLL_INTERVAL_MS > 0) {
  setInterval(() => {
    pollPending();
  }, POLL_INTERVAL_MS);
}

log("POS print agent started.");
