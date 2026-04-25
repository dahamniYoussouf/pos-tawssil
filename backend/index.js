import "./processHandlers.js";
import "./src/config/env.js";
import { server } from "./src/app.js";
import { sequelize } from "./src/config/database.js";
import { startBackupScheduler } from "./src/services/backupScheduler.service.js";

const port = process.env.PORT || 3000;
const host = process.env.HOST || "127.0.0.1";

const MAX_LISTEN_RETRIES = 5;
let listenAttempts = 0;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// DB retry (prevents PM2 crash loops when Postgres/Supabase is temporarily down)
const DB_CONNECT_MAX_RETRIES = Number.parseInt(
  process.env.DB_CONNECT_MAX_RETRIES || "0",
  10
); // 0 = infinite
const DB_CONNECT_BASE_DELAY_MS = Number.parseInt(
  process.env.DB_CONNECT_BASE_DELAY_MS || "1000",
  10
);
const DB_CONNECT_MAX_DELAY_MS = Number.parseInt(
  process.env.DB_CONNECT_MAX_DELAY_MS || "30000",
  10
);

const extractErrorMessage = (error) => {
  if (error instanceof Error && error.message) return error.message;
  try {
    return JSON.stringify(error);
  } catch {
    return String(error);
  }
};

const connectDatabaseWithRetry = async () => {
  let attempt = 0;
  while (true) {
    attempt += 1;
    try {
      await sequelize.authenticate();
      return;
    } catch (error) {
      const retriesLabel =
        DB_CONNECT_MAX_RETRIES > 0 ? `/${DB_CONNECT_MAX_RETRIES}` : "";
      const shouldStop =
        DB_CONNECT_MAX_RETRIES > 0 && attempt >= DB_CONNECT_MAX_RETRIES;
      const delay = Math.min(
        DB_CONNECT_BASE_DELAY_MS * attempt,
        DB_CONNECT_MAX_DELAY_MS
      );

      console.error(
        `❌ Database connection failed (attempt ${attempt}${retriesLabel}): ${extractErrorMessage(error)}`
      );

      if (shouldStop) {
        throw error;
      }

      console.error(`⏳ Retrying database connection in ${delay}ms...`);
      await sleep(delay);
    }
  }
};

const listenWithRetry = () => {
  listenAttempts += 1;
  server.listen(port, host, () => {
    console.log(`✅ App listening on ${host}:${port}`);
  });
};

server.on("error", (error) => {
  if (error && error.code === "EADDRINUSE") {
    if (listenAttempts >= MAX_LISTEN_RETRIES) {
      console.error(
        `❌ Port ${port} still in use after ${listenAttempts} attempts`
      );
      process.exit(1);
    }
    const delay = Math.min(1000 * listenAttempts, 5000);
    console.error(
      `⚠️ Port ${port} in use. Retrying in ${delay}ms (${listenAttempts}/${MAX_LISTEN_RETRIES})`
    );
    setTimeout(() => {
      listenWithRetry();
    }, delay);
    return;
  }

  console.error("❌ Server error:", error);
  process.exit(1);
});

// Database connection and server start
const startServer = async () => {
  try {
    await connectDatabaseWithRetry();
    console.log("✅ Database connection established");

    // Start HTTP server with retry on EADDRINUSE
    listenWithRetry();

    if (process.env.NODE_ENV !== "test") {
      startBackupScheduler();
    }
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
};

startServer();
