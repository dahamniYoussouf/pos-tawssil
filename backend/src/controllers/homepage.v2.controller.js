import * as restaurantService from "../services/restaurant.service.js";
import { getHomepageModules } from "../services/homepage.service.js";
import { buildHomepagePayload, buildNearbyFilters, normalizeCategories } from "./homepage.controller.js";

const nowNs = () => process.hrtime.bigint();
const msSince = (start) => Number(process.hrtime.bigint() - start) / 1e6;
const roundMs = (value) => Math.round(value * 10) / 10;

const logTiming = (event, durationMs) => {
  if (process.env.HOME_TIMING_LOG === "true") {
    console.info("homepage_stream_timing", {
      event,
      duration_ms: roundMs(durationMs)
    });
  }
};

const sendSseEvent = (res, event, payload) => {
  res.write(`event: ${event}\n`);
  res.write(`data: ${JSON.stringify(payload)}\n\n`);
  if (typeof res.flush === "function") {
    res.flush();
  }
};

export const streamHomepageOverview = async (req, res, next) => {
  res.set({
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive"
  });
  res.flushHeaders();

  const clientId = req.user?.client_id;
  if (!clientId) {
    sendSseEvent(res, "error", {
      success: false,
      message: "Client profile not found"
    });
    res.end();
    return;
  }

  const filterPayload = {
    ...req.body,
    categories: normalizeCategories(req.body.categories),
    client_id: clientId
  };
  const nearbyFilters = buildNearbyFilters(filterPayload);
  nearbyFilters.client_id = clientId;

  const modulesStart = nowNs();
  const nearbyStart = nowNs();

  const modulesPromise = getHomepageModules({ includeFeaturedRestaurants: false })
    .then((modules) => {
      logTiming("modules", msSince(modulesStart));
      return { ok: true, value: modules };
    })
    .catch((error) => ({ ok: false, error }));

  const nearbyPromise = restaurantService.filterNearbyRestaurants(nearbyFilters)
    .then((nearby) => {
      logTiming("nearby", msSince(nearbyStart));
      return { ok: true, value: nearby };
    })
    .catch((error) => ({ ok: false, error }));

  const [modulesResult, nearbyResult] = await Promise.all([modulesPromise, nearbyPromise]);
  if (!modulesResult.ok) {
    sendSseEvent(res, "error", {
      success: false,
      message: modulesResult.error?.message || "Unable to load homepage modules"
    });
    res.end();
    return;
  }
  if (!nearbyResult.ok) {
    sendSseEvent(res, "error", {
      success: false,
      message: nearbyResult.error?.message || "Unable to load nearby restaurants"
    });
    res.end();
    return;
  }

  const payload = buildHomepagePayload(modulesResult.value, nearbyResult.value);
  const { nearby, ...modulesPayload } = payload;

  sendSseEvent(res, "modules", { success: true, data: modulesPayload });
  sendSseEvent(res, "nearby", { success: true, data: nearby });

  sendSseEvent(res, "done", { success: true });
  res.end();
};
