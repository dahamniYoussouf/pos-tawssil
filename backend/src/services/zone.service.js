import { QueryTypes } from "sequelize";
import { sequelize } from "../config/database.js";
import Driver from "../models/Driver.js";
import SystemConfig from "../models/SystemConfig.js";
import calculateRouteTime from "./routingService.js";

const DEFAULT_RADIUS_METERS = 5000;
const DEFAULT_LIMIT = 12;
const DEFAULT_SPEED_KMH = 40;

const normalizeInt = (value, fallback) => {
  const parsed = Number.parseInt(String(value), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

const buildZoneId = (name, lat, lng) => {
  const slug = String(name || "zone")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
  return `${slug || "zone"}-${lat.toFixed(5)}-${lng.toFixed(5)}`;
};

const getLoadLevel = (count, lowMax, mediumMax) => {
  if (count <= lowMax) return "low";
  if (count <= mediumMax) return "middle";
  return "high";
};

export const getDriverNearbyZones = async (driverId, options = {}) => {
  const driver = await Driver.findByPk(driverId);
  if (!driver) throw { status: 404, message: "Driver not found" };
  if (!driver.current_location) {
    throw { status: 400, message: "Driver location not available. Please enable GPS." };
  }

  const coords = driver.getCurrentCoordinates?.();
  if (!coords) throw { status: 400, message: "Invalid driver location" };

  const [configuredRadius, configuredLimit] = await Promise.all([
    SystemConfig.get("driver_nearby_search_radius", DEFAULT_RADIUS_METERS),
    SystemConfig.get("driver_zone_limit", DEFAULT_LIMIT)
  ]);

  const radius = clamp(
    normalizeInt(options.radius ?? configuredRadius, DEFAULT_RADIUS_METERS),
    100,
    50000
  );
  const limit = clamp(
    normalizeInt(options.limit ?? configuredLimit, DEFAULT_LIMIT),
    1,
    50
  );

  const statusFilter = options.status && options.status.length
    ? options.status
    : ["accepted", "preparing"];

  const statusArray = Array.isArray(statusFilter) ? statusFilter : [statusFilter];

  const pointExpr = "ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography";
  const rows = await sequelize.query(`
    SELECT
      c.id,
      c.name,
      c.name_ar,
      c.wilaya_code,
      c.wilaya_name,
      ST_X(c.location::geometry) AS lng,
      ST_Y(c.location::geometry) AS lat,
      COUNT(o.id) AS available_orders
    FROM orders o
    JOIN restaurants r ON r.id = o.restaurant_id
    JOIN communes c ON c.id = r.commune_id
    WHERE o.order_type = 'delivery'
      AND o.livreur_id IS NULL
      AND o.delivery_location IS NOT NULL
      AND o.status IN (:status)
      AND ST_DWithin(r.location, ${pointExpr}, :radius)
    GROUP BY c.id, c.name, c.name_ar, c.wilaya_code, c.wilaya_name, c.location
    ORDER BY ST_Distance(c.location, ${pointExpr}) ASC
    LIMIT :limit
  `, {
    replacements: {
      lat: coords.latitude,
      lng: coords.longitude,
      radius,
      status: statusArray,
      limit
    },
    type: QueryTypes.SELECT
  });

  if (!rows.length) {
    return {
      center: { lat: coords.latitude, lng: coords.longitude },
      radius_m: radius,
      count: 0,
      data: []
    };
  }

  const maxOrders = Math.max(
    1,
    ...rows.map((item) => Number.parseInt(item.available_orders, 10) || 0)
  );

  const [configuredLow, configuredMedium] = await Promise.all([
    SystemConfig.get("zone_load_low_max", 2),
    SystemConfig.get("zone_load_medium_max", 5)
  ]);
  const lowMax = normalizeInt(configuredLow, 2);
  const mediumMax = Math.max(lowMax + 1, normalizeInt(configuredMedium, 5));

  const zones = await Promise.all(rows.map(async (row) => {
    const availableOrders = Number.parseInt(row.available_orders, 10) || 0;
    const lat = Number(row.lat);
    const lng = Number(row.lng);
    const progress = parseFloat((availableOrders / maxOrders).toFixed(2));

    let estimatedMinutes = 0;
    try {
      const route = await calculateRouteTime(
        coords.longitude,
        coords.latitude,
        lng,
        lat,
        DEFAULT_SPEED_KMH,
        { mode: "direct" }
      );
      estimatedMinutes = route?.timeMax ?? route?.timeMin ?? 0;
    } catch (error) {
      estimatedMinutes = 0;
    }

    return {
      id: buildZoneId(row.name, lat, lng),
      commune_id: row.id,
      name: row.name,
      name_ar: row.name_ar || null,
      wilaya_code: row.wilaya_code || null,
      wilaya_name: row.wilaya_name || null,
      availableOrders,
      estimatedMinutes,
      progress,
      loadLevel: getLoadLevel(availableOrders, lowMax, mediumMax),
      lat,
      lng
    };
  }));

  return {
    center: { lat: coords.latitude, lng: coords.longitude },
    radius_m: radius,
    count: zones.length,
    data: zones
  };
};
