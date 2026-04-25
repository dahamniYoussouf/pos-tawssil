import { createBackup } from "./databaseBackup.service.js";
import SystemConfig from "../models/SystemConfig.js";

let schedulerStarted = false;
let schedulerTimer = null;
const DISABLED_RECHECK_MS = 15 * 60 * 1000;

const normalizeBoolean = (value, fallback) => {
  if (value === undefined || value === null) return fallback;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    if (["true", "1", "yes", "on"].includes(normalized)) return true;
    if (["false", "0", "no", "off"].includes(normalized)) return false;
  }
  return fallback;
};

const normalizeNumber = (value, fallback, min, max) => {
  if (value === undefined || value === null) return fallback;
  const parsed = Number.parseInt(String(value), 10);
  if (!Number.isFinite(parsed)) return fallback;
  if (min !== undefined && parsed < min) return fallback;
  if (max !== undefined && parsed > max) return fallback;
  return parsed;
};

const parseScheduleTime = async () => {
  const fallbackEnabled = normalizeBoolean(process.env.BACKUP_SCHEDULE_ENABLED, true);
  const fallbackHour = normalizeNumber(process.env.BACKUP_SCHEDULE_HOUR ?? "2", 2, 0, 23);
  const fallbackMinute = normalizeNumber(process.env.BACKUP_SCHEDULE_MINUTE ?? "0", 0, 0, 59);

  try {
    const [enabledValue, hourValue, minuteValue] = await Promise.all([
      SystemConfig.get("BACKUP_SCHEDULE_ENABLED", fallbackEnabled),
      SystemConfig.get("BACKUP_SCHEDULE_HOUR", fallbackHour),
      SystemConfig.get("BACKUP_SCHEDULE_MINUTE", fallbackMinute)
    ]);

    return {
      enabled: normalizeBoolean(enabledValue, fallbackEnabled),
      hour: normalizeNumber(hourValue, fallbackHour, 0, 23),
      minute: normalizeNumber(minuteValue, fallbackMinute, 0, 59)
    };
  } catch (error) {
    console.warn("Backup scheduler: failed to read system config, using env defaults.");
    return {
      enabled: fallbackEnabled,
      hour: fallbackHour,
      minute: fallbackMinute
    };
  }
};

const computeNextRun = (hour, minute) => {
  const now = new Date();
  const next = new Date(now);
  next.setHours(hour, minute, 0, 0);

  if (next <= now) {
    next.setDate(next.getDate() + 1);
  }

  return next;
};

const scheduleNextRun = async () => {
  const { enabled, hour, minute } = await parseScheduleTime();

  if (!enabled) {
    console.log("🛑 Backup scheduler disabled (BACKUP_SCHEDULE_ENABLED=0)");
    schedulerTimer = setTimeout(() => {
      scheduleNextRun();
    }, DISABLED_RECHECK_MS);
    return;
  }

  const nextRun = computeNextRun(hour, minute);
  const delay = nextRun.getTime() - Date.now();

  schedulerTimer = setTimeout(async () => {
    try {
      await createBackup({
        source: "auto",
        label: `Daily backup ${nextRun.toISOString().slice(0, 10)}`
      });
      console.log(`✅ Daily backup completed (${nextRun.toISOString()})`);
    } catch (error) {
      console.error("❌ Daily backup failed:", error?.message || error);
    } finally {
      scheduleNextRun();
    }
  }, Math.max(delay, 0));

  console.log(`🗓️ Next backup scheduled at ${nextRun.toISOString()}`);
};

export const startBackupScheduler = () => {
  if (schedulerStarted) return;

  schedulerStarted = true;
  scheduleNextRun();
};

export const stopBackupScheduler = () => {
  if (schedulerTimer) {
    clearTimeout(schedulerTimer);
    schedulerTimer = null;
  }
  schedulerStarted = false;
};

export const restartBackupScheduler = () => {
  stopBackupScheduler();
  startBackupScheduler();
};
