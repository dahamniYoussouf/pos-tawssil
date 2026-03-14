import jwt from "jsonwebtoken";

const isProd = process.env.NODE_ENV === "production";

const DEFAULT_ACCESS_TTL = "15m";
const DEFAULT_REFRESH_TTL = "30d";
const DEV_JWT_SECRET = "dev-unsafe-secret";
const DEV_JWT_REFRESH_SECRET = "dev-unsafe-refresh-secret";

const JWT_ACCESS_TTL = process.env.JWT_ACCESS_TTL || DEFAULT_ACCESS_TTL;
const JWT_REFRESH_TTL = process.env.JWT_REFRESH_TTL || DEFAULT_REFRESH_TTL;
const JWT_ISSUER = process.env.JWT_ISSUER || undefined;
const JWT_AUDIENCE = process.env.JWT_AUDIENCE || undefined;

const CORS_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"];
const CORS_ALLOWED_HEADERS = ["Content-Type", "Authorization"];

const requireEnv = (name, fallback) => {
  const value = process.env[name];
  if (!value) {
    if (isProd) {
      throw new Error(`${name} is required in production`);
    }
    return fallback;
  }
  return value;
};

const buildJwtSignOptions = (expiresIn) => {
  const options = { expiresIn };
  if (JWT_ISSUER) options.issuer = JWT_ISSUER;
  if (JWT_AUDIENCE) options.audience = JWT_AUDIENCE;
  return options;
};

const buildJwtVerifyOptions = () => {
  const options = {};
  if (JWT_ISSUER) options.issuer = JWT_ISSUER;
  if (JWT_AUDIENCE) options.audience = JWT_AUDIENCE;
  return options;
};

const durationToSeconds = (value, fallbackSeconds) => {
  if (!value) return fallbackSeconds;
  const match = String(value).trim().match(/^(\d+)\s*([smhd])?$/i);
  if (!match) return fallbackSeconds;
  const amount = Number.parseInt(match[1], 10);
  const unit = (match[2] || "s").toLowerCase();
  const multipliers = { s: 1, m: 60, h: 3600, d: 86400 };
  const multiplier = multipliers[unit] ?? 1;
  return amount * multiplier;
};

export const ACCESS_TOKEN_TTL = JWT_ACCESS_TTL;
export const REFRESH_TOKEN_TTL = JWT_REFRESH_TTL;
export const ACCESS_TOKEN_TTL_SECONDS = durationToSeconds(JWT_ACCESS_TTL, 900);
export const REFRESH_TOKEN_TTL_SECONDS = durationToSeconds(JWT_REFRESH_TTL, 2592000);

export const getJwtSecret = () => requireEnv("JWT_SECRET", DEV_JWT_SECRET);
export const getJwtRefreshSecret = () =>
  requireEnv("JWT_REFRESH_SECRET", DEV_JWT_REFRESH_SECRET);

export const signAccessToken = (payload) =>
  jwt.sign(payload, getJwtSecret(), buildJwtSignOptions(JWT_ACCESS_TTL));

export const signRefreshToken = (payload) =>
  jwt.sign(payload, getJwtRefreshSecret(), buildJwtSignOptions(JWT_REFRESH_TTL));

export const verifyAccessToken = (token) =>
  jwt.verify(token, getJwtSecret(), buildJwtVerifyOptions());

export const verifyRefreshToken = (token) =>
  jwt.verify(token, getJwtRefreshSecret(), buildJwtVerifyOptions());

export const getCorsOrigins = () => {
  const raw = process.env.CORS_ORIGINS || "";
  const origins = raw
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (isProd && origins.length === 0) {
    throw new Error("CORS_ORIGINS is required in production");
  }
  return origins;
};


export const buildCorsOptions = () => {
  const allowedOrigins = getCorsOrigins();
  const allowLocalhost = ["1", "true", "yes", "on"].includes(
    String(process.env.CORS_ALLOW_LOCALHOST || "").toLowerCase()
  );
  const isLocalhostOrigin = (origin) => {
    if (!origin) return false;
    try {
      const { hostname } = new URL(origin);
      return hostname === "localhost" || hostname === "127.0.0.1";
    } catch {
      return false;
    }
  };

  if (allowedOrigins.length === 0) {
    return {
      origin: true,
      credentials: false,
      methods: CORS_METHODS,
      allowedHeaders: CORS_ALLOWED_HEADERS,
      optionsSuccessStatus: 204
    };
  }

  return {
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      if (allowLocalhost && isLocalhostOrigin(origin)) return callback(null, true);
      return callback(new Error("Not allowed by CORS"));
    },
    credentials: false,
    methods: CORS_METHODS,
    allowedHeaders: CORS_ALLOWED_HEADERS,
    optionsSuccessStatus: 204
  };
};
