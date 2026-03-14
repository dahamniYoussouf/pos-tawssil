import { Op } from "sequelize";
import sequelize from "../config/database.js";
import Driver from "../models/Driver.js";
import DeviceToken from "../models/DeviceToken.js";
import { normalizeDataPayload, sendToTokens } from "./firebaseNotification.service.js";
import { getDriverNewMissionCopy } from "./orders/pushCopy.helper.js";

const FIREBASE_ENABLED = process.env.NOTIFICATION_FIREBASE_ENABLED !== "false";

export async function notifyNearbyDrivers(orderLat, orderLng, data, radius = 5) {
  const radiusMeters = radius * 1000;

  console.log(`🔍 Searching nearby drivers within ${radius} km`);
  console.log(`📍 Order location: [${orderLat}, ${orderLng}]`);

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

    console.log(`✅ SQL Query returned ${nearbyDrivers.length} drivers`);

    let notifiedCount = 0;
    for (const driver of nearbyDrivers) {
      const distanceMeters = Number(driver.getDataValue("distance_meters")) || 0;
      const distance = (distanceMeters / 1000).toFixed(2);
      const distanceKm = parseFloat(distance);
      const activeOrdersCount = Array.isArray(driver.active_orders)
        ? driver.active_orders.length
        : 0;
      const maxCapacity = Number.isFinite(Number(driver.max_orders_capacity))
        ? Number(driver.max_orders_capacity)
        : 0;

      if (maxCapacity > 0 && activeOrdersCount >= maxCapacity) {
        console.log(
          `⚠️ Driver ${driver.id} at max capacity (${activeOrdersCount}/${maxCapacity})`
        );
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

      await sendDriverPushNotification(driver.id, notificationData);
      notifiedCount += 1;

      console.log(`📢 NOTIFIED driver ${driver.id}:`);
      console.log(`   - Distance: ${distance} km`);
      console.log(`   - Orders: ${activeOrdersCount}/${maxCapacity || "-"}`);
    }

    console.log(`✅ Successfully notified ${notifiedCount}/${nearbyDrivers.length} drivers`);
    return nearbyDrivers;
  } catch (error) {
    console.error("❌ Error in notifyNearbyDrivers:", error);
    return [];
  }
}

async function sendDriverPushNotification(driverId, data) {
  if (!FIREBASE_ENABLED) return;

  const tokens = await DeviceToken.findAll({
    where: {
      role: "driver",
      profile_id: driverId,
      is_active: true
    },
    attributes: ["token"]
  });

  const tokenValues = tokens.map((t) => t.token).filter(Boolean);
  if (tokenValues.length === 0) return;

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
    })
  };

  const result = await sendToTokens(tokenValues, message);

  if (result.invalidTokens?.length) {
    await DeviceToken.update(
      { is_active: false },
      { where: { token: { [Op.in]: result.invalidTokens } } }
    );
  }
}
