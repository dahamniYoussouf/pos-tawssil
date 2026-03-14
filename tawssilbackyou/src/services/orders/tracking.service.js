import Client from "../../models/Client.js";
import Driver from "../../models/Driver.js";
import Order from "../../models/Order.js";
import Restaurant from "../../models/Restaurant.js";
import calculateRouteTime from "../routingService.js";
import cacheService from "../cache.service.js";
import { notify } from "./notify.helper.js";
import { getClientDriverNearbyCopy } from "./pushCopy.helper.js";

const EARTH_RADIUS_METERS = 6371000;
const DRIVER_NEARBY_NOTIFICATION_RADIUS_METERS = 50;
const DRIVER_NEARBY_NOTIFICATION_TTL_SECONDS = 6 * 60 * 60;

const toRadians = (value) => (value * Math.PI) / 180;

const getDistanceMeters = (from, to) => {
  if (!from || !to) return null;
  const lat1 = Number(from.latitude);
  const lng1 = Number(from.longitude);
  const lat2 = Number(to.latitude);
  const lng2 = Number(to.longitude);

  if (![lat1, lng1, lat2, lng2].every(Number.isFinite)) {
    return null;
  }

  const dLat = toRadians(lat2 - lat1);
  const dLng = toRadians(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_METERS * c;
};

export async function updateDriverGPS(driverId, longitude, latitude) {
  const driver = await Driver.findByPk(driverId);
  if (!driver) throw { status: 404, message: "Driver not found" };

  driver.setCurrentLocation(longitude, latitude);
  driver.last_active_at = new Date();
  await driver.save();

  if (driver.hasActiveOrders()) {
    const orders = await Order.findAll({
      where: { id: driver.active_orders, status: "delivering" },
      include: [{ model: Client, as: "client" }],
    });

    const currentLocation = driver.getCurrentCoordinates();

    for (const order of orders) {
      const destination = order.delivery_location?.coordinates;
      if (destination?.length !== 2) {
        continue;
      }

      const [destLng, destLat] = destination;
      const destinationLocation = { longitude: destLng, latitude: destLat };
      const distanceMeters = getDistanceMeters(currentLocation, destinationLocation);
      const notificationCacheKey = `notification:client-nearby:${order.id}`;
      const alreadyNotifiedNearby = await cacheService.has(notificationCacheKey);

      if (
        distanceMeters !== null &&
        distanceMeters <= DRIVER_NEARBY_NOTIFICATION_RADIUS_METERS &&
        !alreadyNotifiedNearby
      ) {
        const nearbyCopy = getClientDriverNearbyCopy();
        notify("client", order.client_id, {
          type: "driver_nearby",
          orderId: order.id,
          distance_meters: Math.round(distanceMeters),
          location: currentLocation,
          title: nearbyCopy.title,
          message: nearbyCopy.message,
          i18n: nearbyCopy.i18n
        });
        await cacheService.set(notificationCacheKey, true, DRIVER_NEARBY_NOTIFICATION_TTL_SECONDS);
      }
    }
  }

  return { driver_id: driverId, active_orders: driver.active_orders };
}

export async function getOrderTracking(orderId) {
  const order = await Order.findByPk(orderId, {
    include: [
      {
        model: Driver,
        as: "driver",
        attributes: [
          "id",
          "first_name",
          "last_name",
          "phone",
          "vehicle_type",
          "vehicle_plate",
          "rating",
          "current_location",
        ],
      },
    ],
  });

  if (!order) throw { status: 404, message: "Order not found" };

  if (order.status !== "delivering") {
    return { order_id: orderId, status: order.status, message: "Order is not currently in delivery" };
  }

  const driverCoords = order.driver?.getCurrentCoordinates();
  const destinationCoords = order.delivery_location?.coordinates
    ? { longitude: order.delivery_location.coordinates[0], latitude: order.delivery_location.coordinates[1] }
    : null;

  return {
    order_id: orderId,
    order_number: order.order_number,
    status: order.status,
    driver: {
      id: order.driver.id,
      name: order.driver.getFullName(),
      phone: order.driver.phone,
      vehicle_type: order.driver.vehicle_type,
      vehicle_plate: order.driver.vehicle_plate,
      rating: order.driver.rating,
      current_location: driverCoords,
    },
    destination: destinationCoords,
    estimated_arrival: order.estimated_delivery_time,
    time_in_transit: order.getTimeInStatus(),
  };
}

export async function getRoutePreview(orderId, driverLng, driverLat) {
  const order = await Order.findByPk(orderId, { include: [{ model: Restaurant, as: "restaurant" }] });
  if (!order) throw { status: 404, message: "Order not found" };

  const rest = order.restaurant?.getCoordinates?.();
  const dest = order.delivery_location?.coordinates
    ? { longitude: order.delivery_location.coordinates[0], latitude: order.delivery_location.coordinates[1] }
    : null;

  let toRestaurant = null,
    toCustomer = null;
  if (driverLng != null && driverLat != null && rest) {
    toRestaurant = await calculateRouteTime(driverLng, driverLat, rest.longitude, rest.latitude);
  }
  if (rest && dest) {
    toCustomer = await calculateRouteTime(rest.longitude, rest.latitude, dest.longitude, dest.latitude);
  }
  return { toRestaurant, toCustomer };
}
