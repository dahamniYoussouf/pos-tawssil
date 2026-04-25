import "./env.js";
import { Sequelize } from "sequelize";

const isTestEnv = process.env.NODE_ENV === "test";

const parseBoolean = (value, fallback = false) => {
  if (value === undefined || value === null) return fallback;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;

  const normalized = String(value).trim().toLowerCase();
  if (["true", "1", "yes", "on"].includes(normalized)) return true;
  if (["false", "0", "no", "off"].includes(normalized)) return false;

  return fallback;
};

const parseInteger = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const resolveDefaultDbPort = (host) => {
  const normalizedHost = String(host || "")
    .trim()
    .toLowerCase();

  if (["localhost", "127.0.0.1", "::1"].includes(normalizedHost)) {
    return 5432;
  }

  // Hosted Postgres providers often expose pooled connections on 6432.
  return 6432;
};

let sequelize;

if (isTestEnv) {
  sequelize = new Sequelize({
    dialect: "sqlite",
    storage: ":memory:",
    logging: false
  });
} else {
  const dialect = process.env.DB_DIALECT || "postgres";
  const dbName = process.env.DB_NAME || "resto_app";
  const dbUser = process.env.DB_USER || "postgres";
  const dbPassword = process.env.DB_PASSWORD || "1234";
  const dbHost = process.env.DB_HOST || "localhost";
  const dbPort = parseInteger(process.env.DB_PORT, resolveDefaultDbPort(dbHost));
  const useSsl = parseBoolean(process.env.DB_SSL, false);

  sequelize = new Sequelize(dbName, dbUser, dbPassword, {
    host: dbHost,
    dialect,
    port: dbPort,
    logging: false,
    dialectOptions: useSsl
      ? {
          ssl: {
            require: true,
            rejectUnauthorized: false
          }
        }
      : undefined,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
}

export { sequelize };
export default sequelize;
