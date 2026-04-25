import { Op } from "sequelize";
import sequelize from "../config/database.js";
import Driver from "../models/Driver.js";
import DeviceToken from "../models/DeviceToken.js";
import { normalizeDataPayload, sendToTokens } from "./firebaseNotification.service.js";
import { applyDeviceTokenDeliveryResults } from "./notification.service.js";
import { enqueueNotificationTask } from "./notificationQueue.service.js";
import { getDriverNewMissionCopy } from "./orders/pushCopy.helper.js";

const FIREBASE_ENABLED = process.env.NOTIFICATION_FIREBASE_ENABLED !== "false";

const buildDriverTokenMap = (rows = []) => {
  const tokensByDriverId = new Map();

  rows.forEach((row) => {
    const profileId = row.profile_id ? String(row.profile_id) : "";
    if (!profileId || !row.token) return;
    const bucket = tokensByDriverId.get(profileId) || [];
    bucket.push(row.token);
    tokensByDriverId.set(profileId, bucket);
  });

  return tokensByDriverId;
};

export async function notifyNearbyDrivers(orderLat, orderLng, data, radius = 5) {
  const radiusMeters = radius * 1000;

  console.log(`Searching nearby drivers within ${radius} km`);
  console.log(`Order location: [${orderLat}, ${orderLng}]`);

  try {
    const nearbyDrivers = await Driver.findAll({
      where: sequelize.literal(`
        status = 'available'
        AND is_active = true
        AND is_verified = true
        AND current_location IS NOT NULL
        AND (
          active_orders = '{}'::uuid[]
          OR array_length(active_orders, 1) IS NULL
          OR array_length(active_orders, 1) < max_orders_capacity
        )
        AND ST_DWithin(
          current_location,
          ST_GeogFromText('POINT(${orderLng} ${orderLat})'),
          ${radiusMeters}
        )
      `),
      attributes: {
        include: [
          [
            sequelize.literal(`
              ST_Distance(
                current_location,
                ST_GeogFromText('POINT(${orderLng} ${orderLat})')
              )
            `),
            "distance_meters"
          ]
        ]
      },
      order: [[sequelize.literal("distance_meters"), "ASC"]]
    });

    console.log(`Nearby driver query returned ${nearbyDrivers.length} drivers`);

    const driverIds = nearbyDrivers.map((driver) => driver.id);
    const tokenRows = driverIds.length
      ? await DeviceToken.findAll({
          where: {
            role: "driver",
            profile_id: { [Op.in]: driverIds },
            is_active: true
          },
          attributes: ["profile_id", "token"]
        })
      : [];
    const tokensByDriverId = buildDriverTokenMap(tokenRows);

    let notifiedCount = 0;

    for (const driver of nearbyDrivers) {
      const driverId = String(driver.id);
      const distanceMeters = Number(driver.getDataValue("distance_meters")) || 0;
      const distance = (distanceMeters / 1000).toFixed(2);
      const distanceKm = Number.parseFloat(distance);
      const activeOrdersCount = Array.isArray(driver.active_orders)
        ? driver.active_orders.length
        : 0;
      const maxCapacity = Number.isFinite(Number(driver.max_orders_capacity))
        ? Number(driver.max_orders_capacity)
        : 0;

      if (maxCapacity > 0 && activeOrdersCount >= maxCapacity) {
        console.log(
          `Driver ${driver.id} at max capacity (${activeOrdersCount}/${maxCapacity})`
        );
        continue;
      }

      const tokenValues = tokensByDriverId.get(driverId) || [];
      if (!tokenValues.length) {
        continue;
      }

      const notificationData = {
        ...data,
        distance,
        distance_km: distanceKm,
        remaining_capacity: maxCapacity > 0 ? Math.max(maxCapacity - activeOrdersCount, 0) : 0,
        driver_current_orders: activeOrdersCount,
        timestamp: new Date().toISOString()
      };

      await sendDriverPushNotification(driverId, tokenValues, notificationData);
      notifiedCount += 1;

      console.log(`Notified driver ${driver.id}: ${distance} km, orders ${activeOrdersCount}/${maxCapacity || "-"}`);
    }

    console.log(`Successfully notified ${notifiedCount}/${nearbyDrivers.length} nearby drivers`);
    return nearbyDrivers;
  } catch (error) {
    console.error("Error in notifyNearbyDrivers:", error);
    return [];
  }
}

export const queueNotifyNearbyDrivers = (orderLat, orderLng, data, radius = 5) =>
  enqueueNotificationTask(
    `notifyNearbyDrivers:${data?.orderId || "unknown"}`,
    () => notifyNearbyDrivers(orderLat, orderLng, data, radius)
  );

async function sendDriverPushNotification(driverId, tokenValues, data) {
  if (!FIREBASE_ENABLED) return;
  if (!tokenValues.length) return;

  const driverMissionCopy = getDriverNewMissionCopy();
  const title = data.title || driverMissionCopy.title;
  const body = data.message || driverMissionCopy.message;

  const message = {
    notification: { title, body },
    data: normalizeDataPayload({
      ...data,
      event: "new_delivery",
      role: "driver",
      profile_id: String(driverId)
    }),
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
          "content-available": 1,
          "mutable-content": 1
        }
      },
      headers: {
        "apns-priority": "10"
      }
    }
  };

  const result = await sendToTokens(tokenValues, message);
  await applyDeviceTokenDeliveryResults(result);
  return result;
}
