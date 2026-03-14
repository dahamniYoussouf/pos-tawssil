import helmet from "helmet";
import rateLimit from "express-rate-limit";
import SystemConfig from "../models/SystemConfig.js";

const isProd = process.env.NODE_ENV === "production";
const WINDOW_MS = 15 * 60 * 1000;
const OTP_RATE_LIMIT_MAX_KEY = "OTP_RATE_LIMIT_MAX";
const OTP_RATE_LIMIT_CACHE_MS = 30 * 1000;

const parseLimit = (value, fallback) => {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
};

const createRateLimiter = (options) =>
  rateLimit({
    windowMs: WINDOW_MS,
    standardHeaders: true,
    legacyHeaders: false,
    ...options
  });

const globalMax = parseLimit(
  process.env.RATE_LIMIT_MAX,
  isProd ? 300 : 1000
);

const authMax = parseLimit(
  process.env.AUTH_RATE_LIMIT_MAX,
  isProd ? 30 : 100
);

const otpMaxFallback = parseLimit(
  process.env.OTP_RATE_LIMIT_MAX,
  isProd ? 10 : 50
);

let otpMaxCached = otpMaxFallback;
let otpMaxCachedAt = 0;
let otpMaxInFlight = null;

const getOtpMax = async () => {
  const now = Date.now();
  if (now - otpMaxCachedAt < OTP_RATE_LIMIT_CACHE_MS) {
    return otpMaxCached;
  }

  if (!otpMaxInFlight) {
    otpMaxInFlight = SystemConfig.get(OTP_RATE_LIMIT_MAX_KEY, otpMaxFallback)
      .then((value) => {
        otpMaxCached = parseLimit(value, otpMaxFallback);
        otpMaxCachedAt = Date.now();
        return otpMaxCached;
      })
      .catch(() => {
        otpMaxCached = otpMaxFallback;
        otpMaxCachedAt = Date.now();
        return otpMaxCached;
      })
      .finally(() => {
        otpMaxInFlight = null;
      });
  }

  return otpMaxInFlight;
};

export const securityMiddlewares = [
  helmet(),
  createRateLimiter({
    max: globalMax,
    message: {
      status: 429,
      error: "Too many requests, please try again later."
    }
  })
];

export const authRateLimiter = createRateLimiter({
  max: authMax,
  message: {
    status: 429,
    error: "Too many authentication attempts, please try again later."
  }
});

export const otpRateLimiter = createRateLimiter({
  max: async () => await getOtpMax(),
  message: {
    status: 429,
    error: "Too many OTP requests, please try again later."
  }
});
