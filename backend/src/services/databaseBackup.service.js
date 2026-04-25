import fs from "fs";
import fsPromises from "fs/promises";
import path from "path";
import crypto from "crypto";
import { spawn } from "child_process";
import DatabaseBackup from "../models/DatabaseBackup.js";
import Admin from "../models/Admin.js";
import Order from "../models/Order.js";
import Restaurant from "../models/Restaurant.js";
import Client from "../models/Client.js";
import Driver from "../models/Driver.js";
import { sequelize } from "../config/database.js";

const DEFAULT_RETENTION = 5;
const BACKUP_DIR = process.env.DB_BACKUP_DIR
  ? path.resolve(process.env.DB_BACKUP_DIR)
  : path.resolve(process.cwd(), "backups");

let jobInProgress = false;

const resolvePgCommand = (envKey, fallback) => {
  const configured = process.env[envKey];
  if (!configured) return fallback;
  const trimmed = configured.trim();
  if (!trimmed) return fallback;

  const looksLikePath = trimmed.includes("\\") || trimmed.includes("/") || trimmed.endsWith(".exe");
  if (looksLikePath && !fs.existsSync(trimmed)) {
    const error = new Error(`${envKey} points to missing file: ${trimmed}`);
    error.status = 500;
    throw error;
  }

  return trimmed;
};

const getRetentionCount = () => {
  const parsed = Number.parseInt(process.env.DB_BACKUP_RETENTION || "", 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : DEFAULT_RETENTION;
};

const buildTimestamp = () => {
  return new Date().toISOString().replace(/[:.]/g, "-");
};

const getDbConfig = () => {
  const config = sequelize?.config || {};
  const options = sequelize?.options || {};
  const database = config.database || options.database || process.env.DB_PG_NAME || "postgres";
  const username =
    config.username ||
    config.user ||
    options.username ||
    options.user ||
    process.env.DB_PG_USER ||
    "postgres";
  const password = config.password || options.password || process.env.DB_PG_PASSWORD || "";
  const host = options.host || process.env.DB_PG_HOST || "localhost";
  const port = options.port || process.env.DB_PG_PORT || 5432;
  const sslRequired =
    options.dialectOptions?.ssl?.require ||
    options.dialectOptions?.ssl === true ||
    process.env.DB_PG_SSL === "true";

  return {
    database,
    username,
    password,
    host,
    port,
    sslRequired: Boolean(sslRequired)
  };
};

const runCommand = (command, args, envOverrides = {}) => {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      env: {
        ...process.env,
        ...envOverrides
      }
    });

    let stderr = "";

    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });

    child.on("error", (err) => {
      reject(err);
    });

    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        const message = stderr.trim() || `${command} exited with code ${code}`;
        reject(new Error(message));
      }
    });
  });
};

const computeChecksum = (filePath) => {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash("sha256");
    const stream = fs.createReadStream(filePath);
    stream.on("data", (chunk) => hash.update(chunk));
    stream.on("error", reject);
    stream.on("end", () => resolve(hash.digest("hex")));
  });
};

const ensureBackupDir = async () => {
  await fsPromises.mkdir(BACKUP_DIR, { recursive: true });
};

const buildDumpArgs = (filePath, dbConfig) => {
  const args = [
    "-Fc",
    "--no-owner",
    "--no-privileges",
    "--file",
    filePath,
    "--host",
    dbConfig.host,
    "--port",
    String(dbConfig.port),
    "--username",
    dbConfig.username,
    "--dbname",
    dbConfig.database
  ];

  return args;
};

const buildRestoreArgs = (filePath, dbConfig) => {
  const args = [
    "--clean",
    "--if-exists",
    "--no-owner",
    "--no-privileges",
    "--exit-on-error",
    "--single-transaction",
    "--host",
    dbConfig.host,
    "--port",
    String(dbConfig.port),
    "--username",
    dbConfig.username,
    "--dbname",
    dbConfig.database,
    filePath
  ];

  return args;
};

const collectBackupStats = async () => {
  const [orders, restaurants, clients, admins, drivers] = await Promise.all([
    Order.count(),
    Restaurant.count(),
    Client.count(),
    Admin.count(),
    Driver.count()
  ]);

  return {
    orders,
    restaurants,
    clients,
    admins,
    drivers
  };
};

const terminateDbConnections = async (database) => {
  try {
    await sequelize.query(
      `
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = :database
          AND pid <> pg_backend_pid();
      `,
      { replacements: { database } }
    );
  } catch (error) {
    console.warn("Could not terminate existing connections:", error?.message || error);
  }
};

const enforceSuccessfulRetention = async (protectedIds = []) => {
  const retention = getRetentionCount();
  const backups = await DatabaseBackup.findAll({
    where: {
      status: ["completed", "restored"]
    },
    order: [["created_at", "DESC"]]
  });

  const protectedSet = new Set(protectedIds.filter(Boolean));
  const kept = [];

  for (const backup of backups) {
    if (protectedSet.has(backup.id)) {
      kept.push(backup.id);
    }
  }

  for (const backup of backups) {
    if (kept.length >= retention) break;
    if (!kept.includes(backup.id)) {
      kept.push(backup.id);
    }
  }

  const toRemove = backups.filter((backup) => !kept.includes(backup.id));
  for (const backup of toRemove) {
    try {
      if (backup.file_path && fs.existsSync(backup.file_path)) {
        await fsPromises.unlink(backup.file_path);
      }
    } catch (error) {
      console.warn(`Failed to delete backup file ${backup.file_path}:`, error?.message || error);
    }

    try {
      await backup.destroy();
    } catch (error) {
      console.warn(`Failed to delete backup record ${backup.id}:`, error?.message || error);
    }
  }
};

export const listBackups = async () => {
  const backups = await DatabaseBackup.findAll({
    order: [["created_at", "DESC"]],
    include: [
      {
        model: Admin,
        as: "creator",
        attributes: ["id", "first_name", "last_name", "email"]
      },
      {
        model: Admin,
        as: "restorer",
        attributes: ["id", "first_name", "last_name", "email"]
      }
    ]
  });

  return backups.map((backup) => ({
    id: backup.id,
    filename: backup.filename,
    file_size: backup.file_size ? Number(backup.file_size) : backup.file_size,
    checksum: backup.checksum,
    status: backup.status,
    source: backup.source,
    label: backup.label,
    database_name: backup.database_name,
    stats: backup.stats || null,
    created_at: backup.created_at,
    updated_at: backup.updated_at,
    error_message: backup.error_message,
    restored_at: backup.restored_at,
    created_by: backup.creator
      ? {
          id: backup.creator.id,
          name: `${backup.creator.first_name} ${backup.creator.last_name}`,
          email: backup.creator.email
        }
      : null,
    restored_by: backup.restorer
      ? {
          id: backup.restorer.id,
          name: `${backup.restorer.first_name} ${backup.restorer.last_name}`,
          email: backup.restorer.email
        }
      : null
  }));
};

const performBackup = async ({
  adminId = null,
  label = null,
  source = "manual",
  skipRetention = false,
  protectedIds = []
} = {}) => {
  const dbConfig = getDbConfig();

  await ensureBackupDir();

  const timestamp = buildTimestamp();
  const filename = `backup_${dbConfig.database}_${timestamp}.dump`;
  const filePath = path.join(BACKUP_DIR, filename);
  let stats = null;

  try {
    stats = await collectBackupStats();
  } catch (error) {
    console.warn("Failed to collect backup stats:", error?.message || error);
  }

  const backupRecord = await DatabaseBackup.create({
    filename,
    file_path: filePath,
    status: "pending",
    source,
    label,
    created_by: adminId,
    database_name: dbConfig.database,
    stats
  });

  try {
    const envOverrides = {};
    if (dbConfig.password) {
      envOverrides.PGPASSWORD = dbConfig.password;
    }
    if (dbConfig.sslRequired) {
      envOverrides.PGSSLMODE = "require";
    }

    const args = buildDumpArgs(filePath, dbConfig);
    const pgDumpCommand = resolvePgCommand("PG_DUMP_PATH", "pg_dump");
    await runCommand(pgDumpCommand, args, envOverrides);

    const fileStats = await fsPromises.stat(filePath);
    const checksum = await computeChecksum(filePath);

    await backupRecord.update({
      file_size: fileStats.size,
      checksum,
      status: "completed",
      error_message: null,
      stats: stats ?? backupRecord.stats
    });

    if (!skipRetention) {
      await enforceSuccessfulRetention(protectedIds);
    }

    return backupRecord;
  } catch (error) {
    const message = error?.message || "Backup failed";
    await backupRecord.update({
      status: "failed",
      error_message: message
    });

    if (fs.existsSync(filePath)) {
      try {
        await fsPromises.unlink(filePath);
      } catch (cleanupError) {
        console.warn("Failed to cleanup backup file:", cleanupError?.message || cleanupError);
      }
    }

    throw error;
  }
};

export const createBackup = async ({ adminId = null, label = null, source = "manual" } = {}) => {
  if (jobInProgress) {
    const error = new Error("Another backup or restore job is already running");
    error.status = 409;
    throw error;
  }

  jobInProgress = true;
  try {
    return await performBackup({ adminId, label, source });
  } finally {
    jobInProgress = false;
  }
};

export const restoreBackup = async ({ backupId, adminId = null, skipPreBackup = false } = {}) => {
  if (jobInProgress) {
    const error = new Error("Another backup or restore job is already running");
    error.status = 409;
    throw error;
  }

  jobInProgress = true;
  const dbConfig = getDbConfig();

  const backupRecord = await DatabaseBackup.findByPk(backupId);
  if (!backupRecord) {
    const error = new Error("Backup not found");
    error.status = 404;
    jobInProgress = false;
    throw error;
  }

  if (!["completed", "restored"].includes(backupRecord.status)) {
    const error = new Error("Backup is not ready for restore");
    error.status = 409;
    jobInProgress = false;
    throw error;
  }

  if (backupRecord.database_name !== dbConfig.database) {
    const error = new Error("Backup database does not match the current database");
    error.status = 409;
    jobInProgress = false;
    throw error;
  }

  if (!backupRecord.file_path || !fs.existsSync(backupRecord.file_path)) {
    const error = new Error("Backup file is missing");
    error.status = 404;
    jobInProgress = false;
    throw error;
  }

  let restoreStarted = false;

  try {
    if (!skipPreBackup) {
      await performBackup({
        adminId,
        label: `Auto backup before restore (${backupRecord.filename})`,
        source: "pre-restore",
        protectedIds: [backupRecord.id]
      });
    }

    const checksum = backupRecord.checksum;
    if (checksum) {
      const currentChecksum = await computeChecksum(backupRecord.file_path);
      if (checksum !== currentChecksum) {
        const error = new Error("Backup checksum mismatch");
        error.status = 409;
        throw error;
      }
    }

    await backupRecord.update({ status: "restoring" });
    restoreStarted = true;

    await terminateDbConnections(dbConfig.database);

    const envOverrides = {};
    if (dbConfig.password) {
      envOverrides.PGPASSWORD = dbConfig.password;
    }
    if (dbConfig.sslRequired) {
      envOverrides.PGSSLMODE = "require";
    }

    const args = buildRestoreArgs(backupRecord.file_path, dbConfig);
    const pgRestoreCommand = resolvePgCommand("PG_RESTORE_PATH", "pg_restore");
    await runCommand(pgRestoreCommand, args, envOverrides);

    await backupRecord.update({
      status: "restored",
      restored_by: adminId,
      restored_at: new Date(),
      error_message: null
    });

    return backupRecord;
  } catch (error) {
    const message = error?.message || "Restore failed";
    if (restoreStarted) {
      await backupRecord.update({
        status: "failed",
        error_message: message
      });
    }
    throw error;
  } finally {
    jobInProgress = false;
  }
};

export const deleteBackup = async (backupId) => {
  const backupRecord = await DatabaseBackup.findByPk(backupId);
  if (!backupRecord) {
    const error = new Error("Backup not found");
    error.status = 404;
    throw error;
  }

  if (backupRecord.status === "restoring") {
    const error = new Error("Cannot delete a backup being restored");
    error.status = 409;
    throw error;
  }

  if (backupRecord.file_path && fs.existsSync(backupRecord.file_path)) {
    await fsPromises.unlink(backupRecord.file_path);
  }

  await backupRecord.destroy();
  return true;
};

export { getRetentionCount };
