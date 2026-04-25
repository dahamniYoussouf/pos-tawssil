import crypto from "node:crypto";

const parsePositiveInt = (value, fallback) => {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const parseNonNegativeInt = (value, fallback) => {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
};

const QUEUE_CONCURRENCY = parsePositiveInt(
  process.env.NOTIFICATION_QUEUE_CONCURRENCY,
  process.env.NODE_ENV === "production" ? 4 : 2
);
const QUEUE_MAX_SIZE = parsePositiveInt(
  process.env.NOTIFICATION_QUEUE_MAX_SIZE,
  process.env.NODE_ENV === "production" ? 5000 : 1000
);
const QUEUE_MAX_RETRIES = parseNonNegativeInt(
  process.env.NOTIFICATION_QUEUE_MAX_RETRIES,
  2
);
const QUEUE_RETRY_BASE_MS = parsePositiveInt(
  process.env.NOTIFICATION_QUEUE_RETRY_BASE_MS,
  1500
);

const queue = [];
let activeJobs = 0;
let drainScheduled = false;

const stats = {
  enqueued: 0,
  processed: 0,
  failed: 0,
  retried: 0,
  dropped: 0
};

const scheduleDrain = () => {
  if (drainScheduled) {
    return;
  }

  drainScheduled = true;
  setImmediate(() => {
    drainScheduled = false;
    drainQueue();
  });
};

const logFailure = (message, error) => {
  if (error) {
    console.error(message, error);
    return;
  }
  console.error(message);
};

const requeueWithDelay = (job) => {
  const delayMs = Math.min(
    QUEUE_RETRY_BASE_MS * Math.max(1, job.attempt),
    30_000
  );

  const timer = setTimeout(() => {
    queue.unshift(job);
    scheduleDrain();
  }, delayMs);

  timer?.unref?.();
};

const runJob = async (job) => {
  activeJobs += 1;
  job.attempt += 1;

  try {
    await job.handler();
    stats.processed += 1;
  } catch (error) {
    if (job.attempt <= job.maxRetries) {
      stats.retried += 1;
      logFailure(
        `[NOTIF_QUEUE] Job ${job.name} failed on attempt ${job.attempt}, retrying`,
        error
      );
      requeueWithDelay(job);
    } else {
      stats.failed += 1;
      logFailure(
        `[NOTIF_QUEUE] Job ${job.name} failed after ${job.attempt} attempt(s)`,
        error
      );
    }
  } finally {
    activeJobs -= 1;
    drainQueue();
  }
};

const drainQueue = () => {
  while (activeJobs < QUEUE_CONCURRENCY && queue.length > 0) {
    const job = queue.shift();
    void runJob(job);
  }
};

export const enqueueNotificationTask = (
  name,
  handler,
  { maxRetries = QUEUE_MAX_RETRIES } = {}
) => {
  if (typeof handler !== "function") {
    throw new TypeError("Notification queue handler must be a function");
  }

  if (queue.length + activeJobs >= QUEUE_MAX_SIZE) {
    stats.dropped += 1;
    logFailure(
      `[NOTIF_QUEUE] Queue full, dropping job ${name} (size=${queue.length}, active=${activeJobs})`
    );
    return {
      accepted: false,
      dropped: true,
      queue_size: queue.length,
      active_jobs: activeJobs
    };
  }

  const job = {
    id: crypto.randomUUID(),
    name,
    handler,
    attempt: 0,
    maxRetries
  };

  queue.push(job);
  stats.enqueued += 1;
  scheduleDrain();

  return {
    accepted: true,
    dropped: false,
    job_id: job.id,
    queue_size: queue.length,
    active_jobs: activeJobs
  };
};

export const getNotificationQueueStats = () => ({
  ...stats,
  queued: queue.length,
  active_jobs: activeJobs,
  concurrency: QUEUE_CONCURRENCY,
  max_size: QUEUE_MAX_SIZE
});
