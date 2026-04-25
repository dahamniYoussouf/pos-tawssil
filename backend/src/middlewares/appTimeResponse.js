import { serializeDatesInAppTimeZone } from "../utils/appTime.js";

export const appTimeResponseMiddleware = (_req, res, next) => {
  const originalJson = res.json.bind(res);

  res.json = (body) => originalJson(serializeDatesInAppTimeZone(body));
  next();
};

export default appTimeResponseMiddleware;
