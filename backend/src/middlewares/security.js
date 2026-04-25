import helmet from "helmet";
const noopMiddleware = (_req, _res, next) => next();

export const securityMiddlewares = [
  helmet(),
  noopMiddleware
];

export const authRateLimiter = noopMiddleware;

export const otpRateLimiter = noopMiddleware;
